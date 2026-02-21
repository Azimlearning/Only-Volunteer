import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';

const gemini = new GoogleGenerativeAI(getGeminiApiKey());
const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });

export const generateAIInsights = functions.https.onCall(async (data, context) => {
  // Check authentication (optional - can be public for demo)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  // }

  try {
    // Gather metrics
    const metrics = await gatherMetrics();

    // Generate descriptive insights
    const descriptive = await generateDescriptiveInsights(metrics);

    // Generate prescriptive recommendations
    const prescriptive = await generatePrescriptiveInsights(metrics);

    return {
      metrics,
      descriptive,
      prescriptive,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error generating AI insights:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate insights');
  }
});

async function gatherMetrics(): Promise<any> {
  try {
    const [
      usersSnapshot,
      activitiesSnapshot,
      drivesSnapshot,
      attendancesSnapshot,
      donationsSnapshot,
    ] = await Promise.all([
      admin.firestore().collection('users').count().get(),
      admin.firestore().collection('volunteer_listings').count().get(),
      admin.firestore().collection('donation_drives').count().get(),
      admin.firestore().collection('attendances').count().get(),
      admin.firestore().collection('donations').get(),
    ]);

    const totalDonations = donationsSnapshot.docs.reduce((sum, doc) => {
      const amount = doc.data().amount || 0;
      return sum + (typeof amount === 'number' ? amount : 0);
    }, 0);

    return {
      totalUsers: usersSnapshot.data().count,
      totalActivities: activitiesSnapshot.data().count,
      totalDrives: drivesSnapshot.data().count,
      totalAttendances: attendancesSnapshot.data().count,
      totalDonations: totalDonations,
    };
  } catch (error) {
    console.error('Error gathering metrics:', error);
    return {
      totalUsers: 0,
      totalActivities: 0,
      totalDrives: 0,
      totalAttendances: 0,
      totalDonations: 0,
    };
  }
}

async function generateDescriptiveInsights(metrics: any): Promise<string> {
  const prompt = `Analyze these volunteer platform metrics and provide descriptive insights (what happened):

Metrics:
- Total Users: ${metrics.totalUsers}
- Total Activities: ${metrics.totalActivities}
- Total Donation Drives: ${metrics.totalDrives}
- Total Volunteer Attendances: ${metrics.totalAttendances}
- Total Donations Raised: RM ${metrics.totalDonations.toFixed(2)}

Provide 3-4 insights explaining trends, patterns, and what these numbers mean. Be concise and data-driven. Format as bullet points.`;

  try {
    const result = await model.generateContent(prompt);
    return result.response.text() || 'Unable to generate descriptive insights.';
  } catch (error) {
    console.error('Error generating descriptive insights:', error);
    return 'Unable to generate descriptive insights at this time.';
  }
}

async function generatePrescriptiveInsights(metrics: any): Promise<string> {
  const prompt = `Based on these metrics, provide prescriptive recommendations (what to do next):

Metrics:
- Total Users: ${metrics.totalUsers}
- Total Activities: ${metrics.totalActivities}
- Total Donation Drives: ${metrics.totalDrives}
- Total Volunteer Attendances: ${metrics.totalAttendances}
- Total Donations Raised: RM ${metrics.totalDonations.toFixed(2)}

Provide 3-4 actionable recommendations for:
1. Increasing volunteer engagement
2. Optimizing donation drives
3. Improving user retention
4. Addressing gaps or opportunities

Be specific and actionable. Format as bullet points.`;

  try {
    const result = await model.generateContent(prompt);
    return result.response.text() || 'Unable to generate prescriptive insights.';
  } catch (error) {
    console.error('Error generating prescriptive insights:', error);
    return 'Unable to generate prescriptive insights at this time.';
  }
}
