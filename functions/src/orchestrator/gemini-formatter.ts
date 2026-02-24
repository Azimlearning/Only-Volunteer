import { GoogleGenerativeAI } from '@google/generative-ai';
import type { Content } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey, isGeminiConfigured } from '../gemini-config';
import { getChatbotFollowUpSuggestionsPrompt } from '../prompts/chatbot-prompts';
import { contextToPromptBlock } from './context-builder';
import type { UserContext } from './context-builder';
import type { ToolName } from './router';
import type { ChatTurn } from './conversation-memory';

function getGeminiModel() {
  if (!isGeminiConfigured()) {
    console.error('GEMINI_API_KEY environment variable missing or too short');
    return { model: null, apiKey: '' };
  }
  const apiKey = getGeminiApiKey();
  const gemini = new GoogleGenerativeAI(apiKey);
  const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });
  return { model, apiKey };
}

/** Base system prompt: personality, capabilities, rules. Context block is injected by callers. */
function buildBaseSystemPrompt(contextBlock: string): string {
  const today = new Date().toLocaleDateString('en-MY', { dateStyle: 'long' });
  return `You are OnlyVolunteer AI, an expert assistant embedded in a volunteer & aid management platform in Malaysia.

## Your Personality
- Warm, encouraging, and action-oriented
- Concise but never robotic — speak like a helpful human coordinator
- Use the user's name when you know it
- Always respond in English

## Your Capabilities
You have access to real-time tools:
- alerts: Active disaster/emergency alerts
- analytics: Platform insights and impact stats
- match_me_mini (Match Me): AI-powered volunteer matching with a short Q&A flow
- donation_drives: Ongoing donation drives (we have the user's location in context; do not ask for it)
- aidfinder: Aid resources (food banks, donation centers, etc.) — lists and summarizes; the Aid Finder page in the app does "nearest by location" separately

## Response Rules
- ALWAYS use a tool when the query relates to your capabilities — never guess data
- After tool results, summarize in 2-4 sentences max; highlight the most actionable item
- If no results found, suggest what the user can do next (e.g. create an alert, check back later)
- Never show raw JSON or tool names to the user
- Format responses with clear structure when listing multiple items (bold, short bullets)
- End responses with ONE specific next action suggestion
- **NEVER ask the user for their location.** User location is in the context block when set; use it for personalization and wording only. If location is "Not set", suggest they add it in their profile or use the Aid Finder page for location-based search.

## Aid Finder (chat)
The Aid Finder page in the app already finds nearest aid by location. In chat, the aidfinder tool only lists and summarizes aid resources (optionally by category/urgency). Do not ask for location; use the location from context when you mention area.

## Context
- Today's date: ${today}
- Platform: OnlyVolunteer Malaysia

User Context:
${contextBlock}`;
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
  if (toolUsed === 'analytics' && toolData?.answer && typeof toolData.answer === 'string') {
    return toolData.answer;
  }

  const contextBlock = contextToPromptBlock(userContext);
  const dataStr = JSON.stringify(toolData, null, 2);
  const basePrompt = buildBaseSystemPrompt(contextBlock);

  const userContent = `Tool that was used: ${toolUsed || 'none'}
Structured data from tool:
${dataStr}
${userMessage ? `\nUser asked: "${userMessage}"` : ''}

Your task: Explain this in a friendly, encouraging, and actionable way. Be concise (2-4 sentences). Highlight key points. End with one suggestion. Use emoji sparingly (0-2 max). Never show raw JSON or ask for location.`;

  if (!isGeminiConfigured()) return "I've retrieved the information. Please check the data shown.";
  try {
    const gemini = new GoogleGenerativeAI(getGeminiApiKey());
    const modelWithSystem = gemini.getGenerativeModel({
      model: GEMINI_MODEL,
      systemInstruction: {
        role: 'system',
        parts: [{ text: basePrompt }],
      },
    });
    const result = await modelWithSystem.generateContent(userContent);
    const text = result.response.text();
    return text?.trim() || "Here's what I found. Check the details above.";
  } catch (e: any) {
    console.error('Gemini formatter error:', e?.message ?? e);
    return "I've retrieved the information. Please check the data shown.";
  }
}

/**
 * General chat when no tool was used (pure Gemini).
 * If history is provided, uses multi-turn chat with conversation memory.
 */
export async function chatWithContext(
  userContext: UserContext,
  userMessage: string,
  history: ChatTurn[] = []
): Promise<string> {
  const contextBlock = contextToPromptBlock(userContext);
  const systemInstruction = buildBaseSystemPrompt(contextBlock);
  const { model } = getGeminiModel();
  if (!model) {
    console.error('Gemini API key not configured. Chat unavailable.');
    return 'Chat is temporarily unavailable. Please try again later or ask about alerts, insights, or matching.';
  }
  try {
    if (history.length > 0) {
      const contentHistory: Content[] = history.map((t) => ({
        role: t.role,
        parts: [{ text: t.content }],
      }));
      const chat = model.startChat({
        history: contentHistory,
        systemInstruction: {
          role: 'system',
          parts: [{ text: systemInstruction }],
        },
      });
      const result = await chat.sendMessage(userMessage);
      const text = result.response.text();
      return text?.trim() || "I'm not sure how to answer that. Try asking about alerts, insights, matching, or nearby aid.";
    }
    const gemini = new GoogleGenerativeAI(getGeminiApiKey());
    const modelWithSystem = gemini.getGenerativeModel({
      model: GEMINI_MODEL,
      systemInstruction: {
        role: 'system',
        parts: [{ text: systemInstruction }],
      },
    });
    const result = await modelWithSystem.generateContent(userMessage);
    const text = result.response.text();
    return text?.trim() || "I'm not sure how to answer that. Try asking about alerts, insights, matching, or nearby aid.";
  } catch (e: any) {
    const msg = e?.message ?? String(e);
    console.error('Gemini chat error:', msg);
    if (msg.includes('API key') || msg.includes('401') || msg.includes('403')) {
      return "I'm having trouble connecting right now. Please try again in a moment.";
    }
    return 'Something went wrong. Please try again.';
  }
}

/**
 * Generate 2-3 contextual follow-up suggestion phrases based on the last exchange.
 * Returns empty array on failure or if not configured.
 */
export async function generateSuggestions(userMessage: string, responseText: string): Promise<string[]> {
  const { model } = getGeminiModel();
  if (!model) return [];
  const prompt = getChatbotFollowUpSuggestionsPrompt(userMessage, responseText);
  try {
    const result = await model.generateContent(prompt);
    const raw = result.response.text()?.trim() ?? '';
    const lines = raw
      .split(/\n/)
      .map((s) => s.replace(/^[\d\.\-\*]\s*/, '').trim())
      .filter((s) => s.length > 0 && s.length < 80);
    return lines.slice(0, 3);
  } catch {
    return [];
  }
}
