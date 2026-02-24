import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';

const db = admin.firestore();
const gemini = new GoogleGenerativeAI(getGeminiApiKey());
const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });

type Role = 'volunteer' | 'ngo' | 'admin';

/** Role-scoped analytical insight for the analytics reporting page. */
export const generateAnalyticalInsight = functions
  .runWith({ timeoutSeconds: 60 })
  .https.onCall(async (_, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in.');
    }
    const userId = context.auth.uid;
    try {
      const userDoc = await db.collection('users').doc(userId).get();
      const role: Role = (userDoc.data()?.role as Role) || 'volunteer';

      let metrics: any;
      if (role === 'volunteer') {
        metrics = await gatherUserMetrics(userId);
      } else if (role === 'ngo') {
        metrics = await gatherOrganizerMetrics(userId);
      } else {
        metrics = await gatherAdminMetrics();
      }

      const { descriptive, prescriptive } = await generateRoleBasedInsight(role, metrics);
      return {
        descriptive,
        prescriptive,
        metrics,
        generatedAt: new Date().toISOString(),
      };
    } catch (error) {
      console.error('generateAnalyticalInsight error:', error);
      throw new functions.https.HttpsError('internal', 'Failed to generate insight');
    }
  });

async function gatherUserMetrics(userId: string): Promise<any> {
  const [attendancesSnap, donationsSnap, userSnap] = await Promise.all([
    db.collection('attendances').where('userId', '==', userId).get(),
    db.collection('donations').where('userId', '==', userId).get(),
    db.collection('users').doc(userId).get(),
  ]);
  let hours = 0;
  attendancesSnap.docs.forEach((d) => {
    const h = d.data().hours;
    if (typeof h === 'number') hours += h;
  });
  let rmDonations = 0;
  donationsSnap.docs.forEach((d) => {
    const a = d.data().amount;
    if (typeof a === 'number') rmDonations += a;
  });
  const points = (userSnap.data()?.points as number) || 0;
  return { hoursVolunteerism: hours, rmDonations, pointsCollected: points };
}

async function gatherOrganizerMetrics(uid: string): Promise<any> {
  const [drivesSnap, listingsSnap] = await Promise.all([
    db.collection('donation_drives').where('ngoId', '==', uid).get(),
    db.collection('volunteer_listings').where('organizationId', '==', uid).get(),
  ]);
  const driveIds = drivesSnap.docs.map((d) => d.id);
  const listingIds = listingsSnap.docs.map((d) => d.id);

  const userIds = new Set<string>();
  for (let i = 0; i < listingIds.length; i += 10) {
    const chunk = listingIds.slice(i, i + 10);
    const attSnap = await db.collection('attendances').where('listingId', 'in', chunk).get();
    attSnap.docs.forEach((d) => {
      const u = d.data().userId;
      if (u) userIds.add(u);
    });
  }

  const now = admin.firestore.Timestamp.now().toDate();
  let activeCampaigns = 0;
  drivesSnap.docs.forEach((d) => {
    const end = d.data().endDate?.toDate?.();
    if (!end || end > now) activeCampaigns++;
  });
  listingsSnap.docs.forEach((d) => {
    const end = d.data().endTime?.toDate?.();
    if (!end || end > now) activeCampaigns++;
  });

  let impactFunds = 0;
  for (let i = 0; i < driveIds.length; i += 10) {
    const chunk = driveIds.slice(i, i + 10);
    const donSnap = await db.collection('donations').where('driveId', 'in', chunk).get();
    donSnap.docs.forEach((d) => {
      impactFunds += (d.data().amount as number) || 0;
    });
  }

  return {
    totalVolunteers: userIds.size,
    activeCampaigns,
    impactFunds,
  };
}

async function gatherAdminMetrics(): Promise<any> {
  const [usersSnap, listingsSnap, drivesSnap] = await Promise.all([
    db.collection('users').get(),
    db.collection('volunteer_listings').count().get(),
    db.collection('donation_drives').count().get(),
  ]);
  let nOrgs = 0;
  usersSnap.docs.forEach((d) => {
    const r = d.data().role;
    if (r === 'ngo' || r === 'org') nOrgs++;
  });
  return {
    numberOfUsers: usersSnap.size,
    numberOfOrganisations: nOrgs,
    activeEvents: listingsSnap.data().count + drivesSnap.data().count,
  };
}

async function generateRoleBasedInsight(role: Role, metrics: any): Promise<{ descriptive: string; prescriptive: string }> {
  let promptDesc: string;
  let promptPres: string;
  if (role === 'volunteer') {
    promptDesc = `As a volunteer on a volunteering platform, summarize what these contribution metrics say about this user in 2-4 short, encouraging sentences. Be personal and positive.
Hours spent on volunteerism: ${metrics.hoursVolunteerism?.toFixed(1) ?? 0}
RM spent on donations: ${metrics.rmDonations?.toFixed(2) ?? 0}
Points collected: ${metrics.pointsCollected ?? 0}`;
    promptPres = `Give 2-3 short, actionable suggestions for this volunteer (e.g. try a new opportunity, set a small donation goal, reach the next tier).`;
  } else if (role === 'ngo') {
    promptDesc = `As an organizer on a volunteering platform, summarize what these metrics say about their impact in 2-4 short sentences. Be encouraging and data-driven.
Total volunteers: ${metrics.totalVolunteers ?? 0}
Active campaigns: ${metrics.activeCampaigns ?? 0}
Impact funds (RM): ${metrics.impactFunds?.toFixed(2) ?? 0}`;
    promptPres = `Give 2-3 short, actionable recommendations for this organizer (e.g. recruit more volunteers, launch a campaign, hit a funding goal).`;
  } else {
    promptDesc = `As a platform admin, summarize what these platform metrics indicate in 2-4 short sentences. Focus on health and growth.
Number of users: ${metrics.numberOfUsers ?? 0}
Number of organisations: ${metrics.numberOfOrganisations ?? 0}
Active events: ${metrics.activeEvents ?? 0}`;
    promptPres = `Give 2-3 short admin recommendations (e.g. verify pending NGOs, highlight top events, address bottlenecks).`;
  }

  try {
    const [descResult, presResult] = await Promise.all([
      model.generateContent(promptDesc),
      model.generateContent(promptPres),
    ]);
    const descriptive = descResult.response.text()?.trim() || 'No insight generated.';
    const prescriptive = presResult.response.text()?.trim() || 'No recommendations generated.';
    return { descriptive, prescriptive };
  } catch (error) {
    console.error('generateRoleBasedInsight error:', error);
    return {
      descriptive: 'Insights temporarily unavailable.',
      prescriptive: 'Try again later.',
    };
  }
}

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
