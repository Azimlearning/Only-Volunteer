import * as admin from 'firebase-admin';
import type { UserContext } from '../context-builder';

const db = admin.firestore();

export interface AlertItem {
  id: string;
  title: string;
  body?: string;
  type: string;
  region?: string;
  severity?: string;
  createdAt?: string;
}

export interface AlertsToolOutput {
  activeAlerts: AlertItem[];
  summary: { totalActive: number };
}

/**
 * Alerts tool: fetch active alerts from Firestore (non-expired).
 */
export async function runAlertsTool(_userId: string, _context: UserContext): Promise<AlertsToolOutput> {
  const snap = await db
    .collection('alerts')
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get();

  const activeAlerts: AlertItem[] = [];
  snap.docs.forEach((doc) => {
    const d = doc.data();
    const expiresAt = d.expiresAt?.toDate?.() ?? null;
    if (expiresAt && expiresAt < new Date()) return; // skip expired
    activeAlerts.push({
      id: doc.id,
      title: d.title ?? '',
      body: d.body,
      type: d.type ?? 'general',
      region: d.region,
      severity: d.severity,
      createdAt: d.createdAt?.toDate?.()?.toISOString(),
    });
  });

  return {
    activeAlerts,
    summary: { totalActive: activeAlerts.length },
  };
}
