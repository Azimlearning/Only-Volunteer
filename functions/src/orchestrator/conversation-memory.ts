import * as admin from 'firebase-admin';

const COLLECTION = 'chat_sessions';
const MESSAGES_SUB = 'messages';
const DEFAULT_LIMIT = 6;

export interface ChatTurn {
  role: 'user' | 'model';
  content: string;
}

/**
 * Get the last N messages for a user, ordered by timestamp ascending (oldest first for Gemini history).
 */
export async function getConversationHistory(
  userId: string,
  limit: number = DEFAULT_LIMIT
): Promise<ChatTurn[]> {
  const ref = admin.firestore().collection(COLLECTION).doc(userId).collection(MESSAGES_SUB);
  const snap = await ref.orderBy('timestamp', 'desc').limit(limit).get();
  const turns: ChatTurn[] = snap.docs
    .map((d) => {
      const dta = d.data();
      const role = dta.role === 'user' || dta.role === 'model' ? dta.role : 'user';
      const content = typeof dta.content === 'string' ? dta.content : '';
      return { role, content };
    })
    .filter((t) => t.content.length > 0);
  return turns.reverse();
}

/**
 * Append a single message to the user's conversation. Call twice per turn (user + model).
 */
export async function appendMessage(
  userId: string,
  role: 'user' | 'model',
  content: string
): Promise<void> {
  const ref = admin.firestore().collection(COLLECTION).doc(userId).collection(MESSAGES_SUB).doc();
  await ref.set({
    role,
    content,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}
