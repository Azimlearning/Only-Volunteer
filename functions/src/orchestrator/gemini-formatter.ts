import * as functions from 'firebase-functions';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { contextToPromptBlock } from './context-builder';
import type { UserContext } from './context-builder';
import type { ToolName } from './router';

const MODEL = 'gemini-2.0-flash';

function getGeminiModel() {
  const raw =
    (typeof functions.config().gemini?.api_key === 'string' && functions.config().gemini.api_key) ||
    process.env.GEMINI_API_KEY ||
    '';
  const apiKey = typeof raw === 'string' ? raw.trim().replace(/^["']|["']$/g, '') : '';
  if (!apiKey || apiKey.length < 10) {
    console.error('Gemini API key missing or too short. Set firebase functions:config:set gemini.api_key="YOUR_KEY"');
    return { model: null, apiKey: '' };
  }
  const gemini = new GoogleGenerativeAI(apiKey);
  const model = gemini.getGenerativeModel({ model: MODEL });
  return { model, apiKey };
}

/**
 * Format tool output into natural language using Gemini.
 * Single voice for the whole app.
 */
export async function formatWithGemini(
  userContext: UserContext,
  toolUsed: ToolName,
  toolData: any,
  userMessage?: string
): Promise<string> {
  const contextBlock = contextToPromptBlock(userContext);
  const dataStr = JSON.stringify(toolData, null, 2);

  const systemPrompt = `You are OnlyVolunteer AI, a helpful volunteer assistant.

User Context:
${contextBlock}

Tool that was used: ${toolUsed || 'none'}
Structured data from tool:
${dataStr}
${userMessage ? `\nUser asked: "${userMessage}"` : ''}

Your task: Explain this in a friendly, encouraging, and actionable way.
- Be concise (2-4 sentences).
- Highlight key points.
- End with a suggestion if relevant.
- Use emoji sparingly (0-2 max).
- Stay in character (helpful, not robotic).`;

  const { model } = getGeminiModel();
  if (!model) return 'I’ve retrieved the information. Please check the data shown.';
  try {
    const result = await model.generateContent(systemPrompt);
    const text = result.response.text();
    return text?.trim() || 'Here’s what I found. Check the details above.';
  } catch (e: any) {
    console.error('Gemini formatter error:', e?.message ?? e);
    return 'I’ve retrieved the information. Please check the data shown.';
  }
}

/**
 * General chat when no tool was used (pure Gemini).
 */
export async function chatWithContext(
  userContext: UserContext,
  userMessage: string
): Promise<string> {
  const contextBlock = contextToPromptBlock(userContext);
  const prompt = `You are OnlyVolunteer AI. Help with volunteer opportunities, donation drives, alerts, matching, and nearby aid.

Context:
${contextBlock}

User: ${userMessage}
Assistant:`;

  const { model } = getGeminiModel();
  if (!model) {
    console.error('Gemini API key not configured. Chat unavailable.');
    return 'Chat is temporarily unavailable. Please try again later or ask about alerts, insights, or matching.';
  }
  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    return text?.trim() || 'I’m not sure how to answer that. Try asking about alerts, insights, matching, or nearby aid.';
  } catch (e: any) {
    const msg = e?.message ?? String(e);
    console.error('Gemini chat error:', msg);
    // Common causes: invalid API key, quota, model not found
    if (msg.includes('API key') || msg.includes('401') || msg.includes('403')) {
      return 'I’m having trouble connecting right now. Please try again in a moment.';
    }
    return 'Something went wrong. Please try again.';
  }
}
