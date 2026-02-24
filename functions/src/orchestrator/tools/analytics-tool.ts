import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from '../../gemini-config';
import type { UserContext } from '../context-builder';

const db = admin.firestore();
const gemini = new GoogleGenerativeAI(getGeminiApiKey());
const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });

export interface AnalyticsToolOutput {
  metrics: Record<string, number | string>;
  descriptive?: string;
  prescriptive?: string;
  answer?: string;
  generatedAt: string;
}

type Role = 'volunteer' | 'ngo' | 'admin';

/**
 * Analytics tool: gather role-scoped metrics and optionally answer the user's question (NLP/chat with data).
 */
export async function runAnalyticsTool(
  userId: string,
  context: UserContext,
  message?: string
): Promise<AnalyticsToolOutput> {
  const role: Role = (context.role as Role) || 'volunteer';

  let metrics: Record<string, number | string>;
  if (role === 'volunteer') {
    metrics = await gatherUserMetrics(userId);
  } else if (role === 'ngo') {
    metrics = await gatherOrganizerMetrics(userId);
  } else {
    metrics = await gatherAdminMetrics();
  }

  let descriptive: string | undefined;
  let prescriptive: string | undefined;
  let answer: string | undefined;

  try {
    descriptive = await generateDescriptive(role, metrics);
    prescriptive = await generatePrescriptive(role, metrics);
    if (message && message.trim().length > 0) {
      answer = await generateNLPAnswer(role, metrics, message.trim());
    }
  } catch (e) {
    console.warn('Analytics AI text generation failed:', e);
  }

  return {
    metrics,
    descriptive,
    prescriptive,
    answer,
    generatedAt: new Date().toISOString(),
  };
}

async function gatherUserMetrics(userId: string): Promise<Record<string, number | string>> {
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
  return {
    hoursVolunteerism: hours,
    rmDonations,
    pointsCollected: points,
  };
}

async function gatherOrganizerMetrics(uid: string): Promise<Record<string, number | string>> {
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

async function gatherAdminMetrics(): Promise<Record<string, number | string>> {
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

async function generateDescriptive(role: Role, metrics: Record<string, number | string>): Promise<string> {
  const metricsStr = JSON.stringify(metrics);
  const roleLabel = role === 'volunteer' ? 'volunteer' : role === 'ngo' ? 'organizer' : 'admin';
  const prompt = `As a ${roleLabel} on a volunteering platform, summarize these metrics in 2-4 short sentences (what happened). Be encouraging and data-driven.\nMetrics: ${metricsStr}`;
  const result = await model.generateContent(prompt);
  return result.response.text()?.trim() || 'No descriptive insights generated.';
}

async function generatePrescriptive(role: Role, metrics: Record<string, number | string>): Promise<string> {
  const metricsStr = JSON.stringify(metrics);
  const prompt = `Based on these ${role} metrics, give 2-3 actionable recommendations. Be concise.\nMetrics: ${metricsStr}`;
  const result = await model.generateContent(prompt);
  return result.response.text()?.trim() || 'No prescriptive insights generated.';
}

async function generateNLPAnswer(role: Role, metrics: Record<string, number | string>, userMessage: string): Promise<string> {
  const metricsStr = JSON.stringify(metrics, null, 2);
  const prompt = `You are an analytics assistant for a volunteering platform. The user (role: ${role}) asked a question about their analytics. Answer it using ONLY the following metrics. Be concise (2-4 sentences), friendly, and actionable. Do not make up numbers.

Metrics:
${metricsStr}

User question: "${userMessage}"

Answer:`;
  const result = await model.generateContent(prompt);
  return result.response.text()?.trim() || "I don't have enough data to answer that specifically. Check your Analytics page for details.";
}
