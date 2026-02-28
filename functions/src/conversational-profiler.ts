import * as functions from 'firebase-functions';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey, isGeminiConfigured } from './gemini-config';
import { CONVERSATIONAL_PROFILER_SYSTEM, buildProfilerUserPrompt } from './prompts/match-me';

export interface ProfilerResponse {
  done: boolean;
  question?: string;
  chips?: string[];
  profile?: { skills: string[]; availability?: string; location?: string; causes: string[] };
}

function parseProfilerOutput(text: string): ProfilerResponse {
  const trimmed = text.trim();
  if (trimmed.toUpperCase().startsWith('DONE:')) {
    try {
      // First try standard JSON parse
      let jsonStr = trimmed.slice(5).trim();

      // The model sometimes cuts off the closing brace due to token limits or formatting.
      // Auto-fix simple truncation if missing ending brace
      if (!jsonStr.endsWith('}')) {
        jsonStr += '}';
      }

      const parsed = JSON.parse(jsonStr) as { skills?: string[]; availability?: string; location?: string; causes?: string[] };
      return {
        done: true,
        profile: {
          skills: Array.isArray(parsed.skills) ? parsed.skills : [],
          availability: typeof parsed.availability === 'string' ? parsed.availability : undefined,
          location: typeof parsed.location === 'string' ? parsed.location : undefined,
          causes: Array.isArray(parsed.causes) ? parsed.causes : [],
        },
      };
    } catch {
      // If parsing still fails, treat it as done anyway but with empty arrays so the app can move on securely
      return {
        done: true,
        profile: { skills: [], causes: [] }
      };
    }
  }
  return { done: false, question: trimmed };
}

/**
 * Callable: get next profile question or done + profile.
 * Input: { conversationHistory: { role: 'user'|'model', content: string }[] }
 * Output: { done: boolean, question?: string, profile?: { skills, availability, location, causes } }
 */
export const getNextProfileQuestion = functions.https.onCall(async (data): Promise<ProfilerResponse> => {
  const history = (data.conversationHistory as { role: string; content: string }[]) || [];
  if (!isGeminiConfigured()) {
    if (history.length >= 6) {
      return {
        done: true,
        profile: { skills: [], causes: [] },
      };
    }
    return { done: false, question: 'What skills or interests do you have that you could volunteer with?' };
  }

  const gemini = new GoogleGenerativeAI(getGeminiApiKey());
  const model = gemini.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { temperature: 0.5, maxOutputTokens: 512 },
  });
  const userPrompt = buildProfilerUserPrompt(history);
  const fullPrompt = `${CONVERSATIONAL_PROFILER_SYSTEM}\n\n---\n\n${userPrompt}`;
  try {
    const result = await model.generateContent(fullPrompt);
    const text = result.response.text()?.trim() ?? '';
    return parseProfilerOutput(text);
  } catch (e) {
    console.error('getNextProfileQuestion error', e);
    if (history.length >= 6) {
      return { done: true, profile: { skills: [], causes: [] } };
    }
    return { done: false, question: 'What causes are you most interested in? (e.g. education, animals, environment)' };
  }
});
