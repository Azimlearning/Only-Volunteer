import * as admin from 'firebase-admin';
import type { UserContext } from '../context-builder';
import { runMatchAssessmentCore, type MatchResultItem } from '../../assessment';

const db = admin.firestore();

export interface MatchMeMiniState {
  step: number;
  answers: Record<string, string>;
}

const FIXED_QUESTIONS = [
  'What skills do you have? (e.g. coding, teaching, manual labor)',
  'When are you usually free? (weekdays, weekends, evenings)',
  'Which cause matters most to you? (e.g. animals, education, environment)',
  'Where are you based? (city or region)',
  "Anything else you'd like to add?",
];

export type MatchMeMiniOutput =
  | { kind: 'question'; step: number; question: string; matchMeState: MatchMeMiniState }
  | { kind: 'matches'; topMatches: MatchResultItem[] };

function isMatchIntent(message: string): boolean {
  const lower = (message || '').toLowerCase().trim();
  const keywords = [
    'match', 'match me', 'recommend', 'recommendation', 'suitable', 'for me',
    'best for me', 'what can i do', 'opportunities for me', 'fit',
  ];
  return keywords.some((k) => lower.includes(k));
}

function answersToProfile(state: MatchMeMiniState): Record<string, unknown> {
  const a = state.answers;
  return {
    skills: (a.q1 || '').split(/[,;]/).map((s) => s.trim()).filter(Boolean),
    availability: a.q2?.trim() || '',
    causes: (a.q3 || '').split(/[,;]/).map((s) => s.trim()).filter(Boolean),
    location: a.q4?.trim() || '',
    interests: (a.q5 || '').split(/[,;]/).map((s) => s.trim()).filter(Boolean),
  };
}

/**
 * Mini match-me: 5 fixed questions then 2-3 suggestions. Used from chatbot.
 */
export async function runMatchMeMiniTool(
  userId: string,
  _context: UserContext,
  message: string | undefined,
  metadata?: { matchMeState?: MatchMeMiniState }
): Promise<MatchMeMiniOutput> {
  const state = metadata?.matchMeState;
  const hasMessage = typeof message === 'string' && message.trim().length > 0;

  if (!state) {
    if (hasMessage && isMatchIntent(message!)) {
      return {
        kind: 'question',
        step: 1,
        question: FIXED_QUESTIONS[0],
        matchMeState: { step: 1, answers: {} },
      };
    }
    const out = await runMiniAssessmentFromUserProfile(userId);
    return { kind: 'matches', topMatches: out };
  }

  const step = state.step;
  const answers = { ...state.answers };
  if (step === 1 && hasMessage) answers.q1 = message!.trim();
  if (step === 2 && hasMessage) answers.q2 = message!.trim();
  if (step === 3 && hasMessage) answers.q3 = message!.trim();
  if (step === 4 && hasMessage) answers.q4 = message!.trim();
  if (step === 5 && hasMessage) answers.q5 = message!.trim();

  const nextStep = step + (hasMessage ? 1 : 0);
  if (nextStep <= 5) {
    return {
      kind: 'question',
      step: nextStep,
      question: FIXED_QUESTIONS[nextStep - 1],
      matchMeState: { step: nextStep, answers },
    };
  }

  const profile = answersToProfile({ step: 5, answers });
  const result = await runMatchAssessmentCore(userId, profile);
  const topMatches = result.topMatches.slice(0, 3);
  return { kind: 'matches', topMatches };
}

async function runMiniAssessmentFromUserProfile(userId: string): Promise<MatchResultItem[]> {
  const userDoc = await db.collection('users').doc(userId).get();
  const user = userDoc.data();
  if (!user) return [];
  const answers = {
    skills: user.skills || [],
    interests: user.interests || [],
    availability: user.availability || '',
    location: user.location || '',
    causes: user.causes || [],
  };
  const result = await runMatchAssessmentCore(userId, answers);
  return result.topMatches.slice(0, 3);
}
