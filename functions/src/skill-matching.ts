import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';
import { buildSkillMatchExplanationPrompt } from './prompts/match-me';

const gemini = new GoogleGenerativeAI(getGeminiApiKey());
const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });

export const matchVolunteerToActivities = functions.https.onCall(async (data, context) => {
  const { userId } = data;
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing userId');
  }

  try {
    // Get user profile
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const user = userDoc.data();
    if (!user) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    // Get all active activities
    const now = admin.firestore.Timestamp.now();
    const activitiesSnapshot = await admin.firestore()
      .collection('volunteer_listings')
      .where('startTime', '>', now)
      .get();

    // If no activities with startTime filter, get all
    let activities = activitiesSnapshot.docs;
    if (activities.length === 0) {
      const allActivities = await admin.firestore()
        .collection('volunteer_listings')
        .limit(50)
        .get();
      activities = allActivities.docs;
    }

    // Score each activity
    const matches: any[] = [];
    for (const doc of activities) {
      const activity = doc.data();
      const score = calculateMatchScore(user, activity);

      if (score >= 50) {
        const explanation = await explainMatch(user, activity, score);
        matches.push({
          id: doc.id,
          ...activity,
          matchScore: score,
          matchExplanation: explanation,
        });
      }
    }

    // Sort by score and return top 10
    matches.sort((a, b) => b.matchScore - a.matchScore);
    return matches.slice(0, 10);
  } catch (error) {
    console.error('Error matching activities:', error);
    throw new functions.https.HttpsError('internal', 'Failed to match activities');
  }
});

function calculateMatchScore(user: any, activity: any): number {
  let score = 0;

  // 1. Skills match (40%)
  const userSkills = user.skills || [];
  const requiredSkills = activity.skillsRequired || [];
  if (requiredSkills.length > 0) {
    const skillsMatched = userSkills.filter((s: string) =>
      requiredSkills.includes(s)
    ).length;
    score += (skillsMatched / requiredSkills.length) * 40;
  } else {
    // If no skills required, give partial credit
    score += 20;
  }

  // 2. Interest match (25%)
  const userInterests = user.interests || [];
  const category = (activity.category || activity.title || '').toLowerCase();
  const hasInterestMatch = userInterests.some((i: string) =>
    category.includes(i.toLowerCase())
  );
  if (hasInterestMatch) {
    score += 25;
  }

  // 3. Location proximity (20%) - simplified
  if (user.location && activity.location) {
    const userLoc = user.location.toLowerCase();
    const activityLoc = activity.location.toLowerCase();
    // Assume close if same city/region (simplified)
    if (userLoc.includes(activityLoc) || activityLoc.includes(userLoc)) {
      score += 20;
    } else {
      score += 10; // Partial match
    }
  }

  // 4. Availability (15%)
  const slotsTotal = activity.slotsTotal || 0;
  const slotsFilled = activity.slotsFilled || 0;
  const slotsLeft = slotsTotal - slotsFilled;
  if (slotsLeft > 5) {
    score += 15;
  } else if (slotsLeft > 0) {
    score += 8;
  }

  return Math.round(Math.min(score, 100));
}

async function explainMatch(user: any, activity: any, score: number): Promise<string> {
  const prompt = buildSkillMatchExplanationPrompt(user, activity, score);

  try {
    const result = await model.generateContent(prompt);
    return result.response.text() || `Good match based on skills and interests (${score}% compatibility).`;
  } catch (error) {
    console.error('Error explaining match:', error);
    return `Good match based on skills and interests (${score}% compatibility).`;
  }
}
