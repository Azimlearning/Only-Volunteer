import * as admin from 'firebase-admin';

const db = admin.firestore();

const CHAT_PER_MIN = 10;
const CHAT_PER_HOUR = 60;
const TOOL_PER_MIN = 20;
const TOOL_PER_HOUR = 100;

interface LimitResult {
  allowed: boolean;
  retryAfterSeconds?: number;
}

/**
 * Check chat rate limit (per user).
 * Uses Firestore counters: rate_limits/{userId} with minute and hour windows.
 */
export async function checkChatLimit(userId: string): Promise<LimitResult> {
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return { allowed: true };
  }
  const ref = db.collection('rate_limits').doc(`chat_${userId}`);
  const now = Date.now();
  const minWindow = Math.floor(now / 60000) * 60000;
  const hourWindow = Math.floor(now / 3600000) * 3600000;

  try {
    const doc = await ref.get();
    const data = doc.data() || {};
    const minCount = data.minuteCount ?? 0;
    const minWindowStored = data.minuteWindow ?? 0;
    const hourCount = data.hourCount ?? 0;
    const hourWindowStored = data.hourWindow ?? 0;

    const currentMinCount = minWindowStored === minWindow ? minCount + 1 : 1;
    const currentHourCount = hourWindowStored === hourWindow ? hourCount + 1 : 1;

    if (currentMinCount > CHAT_PER_MIN || currentHourCount > CHAT_PER_HOUR) {
      return { allowed: false, retryAfterSeconds: 60 };
    }

    await ref.set({
      minuteWindow: minWindow,
      minuteCount: currentMinCount,
      hourWindow: hourWindow,
      hourCount: currentHourCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { allowed: true };
  } catch (e) {
    console.warn('Rate limit check failed, allowing:', e);
    return { allowed: true };
  }
}

/**
 * Check tool (auto-execute) rate limit.
 */
export async function checkToolLimit(userId: string): Promise<LimitResult> {
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return { allowed: true };
  }
  const ref = db.collection('rate_limits').doc(`tool_${userId}`);
  const now = Date.now();
  const minWindow = Math.floor(now / 60000) * 60000;
  const hourWindow = Math.floor(now / 3600000) * 3600000;

  try {
    const doc = await ref.get();
    const data = doc.data() || {};
    const minCount = (data.minuteWindow === minWindow ? (data.minuteCount ?? 0) : 0) + 1;
    const hourCount = (data.hourWindow === hourWindow ? (data.hourCount ?? 0) : 0) + 1;

    if (minCount > TOOL_PER_MIN || hourCount > TOOL_PER_HOUR) {
      return { allowed: false, retryAfterSeconds: 60 };
    }

    await ref.set({
      minuteWindow: minWindow,
      minuteCount: minCount,
      hourWindow: hourWindow,
      hourCount: hourCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { allowed: true };
  } catch (e) {
    console.warn('Tool rate limit check failed, allowing:', e);
    return { allowed: true };
  }
}
