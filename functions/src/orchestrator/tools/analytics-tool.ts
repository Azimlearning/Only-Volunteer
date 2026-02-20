import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as functions from 'firebase-functions';
import type { UserContext } from '../context-builder';

const db = admin.firestore();
const gemini = new GoogleGenerativeAI(functions.config().gemini?.api_key || '');
const model = gemini.getGenerativeModel({ model: 'gemini-2.0-flash' });

export interface AnalyticsToolOutput {
  metrics: {
    totalUsers: number;
    totalActivities: number;
    totalDrives: number;
    totalAttendances: number;
    totalDonations: number;
  };
  descriptive?: string;
  prescriptive?: string;
  generatedAt: string;
}

/**
 * Analytics tool: gather metrics and generate AI insights.
 */
export async function runAnalyticsTool(_userId: string, _context: UserContext): Promise<AnalyticsToolOutput> {
  const metrics = await gatherMetrics();
  let descriptive: string | undefined;
  let prescriptive: string | undefined;

  try {
    descriptive = await generateDescriptive(metrics);
    prescriptive = await generatePrescriptive(metrics);
  } catch (e) {
    console.warn('Analytics AI text generation failed:', e);
  }

  return {
    metrics,
    descriptive,
    prescriptive,
    generatedAt: new Date().toISOString(),
  };
}

async function gatherMetrics(): Promise<AnalyticsToolOutput['metrics']> {
  try {
    const [usersSnap, activitiesSnap, drivesSnap, attendancesSnap, donationsSnap] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('volunteer_listings').count().get(),
      db.collection('donation_drives').count().get(),
      db.collection('attendances').count().get(),
      db.collection('donations').get(),
    ]);
    let totalDonations = 0;
    donationsSnap.docs.forEach((doc) => {
      const amount = doc.data().amount ?? 0;
      totalDonations += typeof amount === 'number' ? amount : 0;
    });
    return {
      totalUsers: usersSnap.data().count,
      totalActivities: activitiesSnap.data().count,
      totalDrives: drivesSnap.data().count,
      totalAttendances: attendancesSnap.data().count,
      totalDonations,
    };
  } catch (e) {
    console.error('gatherMetrics error:', e);
    return {
      totalUsers: 0,
      totalActivities: 0,
      totalDrives: 0,
      totalAttendances: 0,
      totalDonations: 0,
    };
  }
}

async function generateDescriptive(metrics: AnalyticsToolOutput['metrics']): Promise<string> {
  const prompt = `Analyze these volunteer platform metrics. Provide 3-4 short descriptive insights (what happened). Be concise, bullet-style.
Metrics: Users ${metrics.totalUsers}, Activities ${metrics.totalActivities}, Drives ${metrics.totalDrives}, Attendances ${metrics.totalAttendances}, Donations RM ${metrics.totalDonations.toFixed(2)}`;
  const result = await model.generateContent(prompt);
  return result.response.text()?.trim() || 'No descriptive insights generated.';
}

async function generatePrescriptive(metrics: AnalyticsToolOutput['metrics']): Promise<string> {
  const prompt = `Based on these metrics, give 3-4 actionable recommendations (what to do next): increase engagement, optimize drives, retention.
Metrics: Users ${metrics.totalUsers}, Activities ${metrics.totalActivities}, Drives ${metrics.totalDrives}, Attendances ${metrics.totalAttendances}, Donations RM ${metrics.totalDonations.toFixed(2)}`;
  const result = await model.generateContent(prompt);
  return result.response.text()?.trim() || 'No prescriptive insights generated.';
}
