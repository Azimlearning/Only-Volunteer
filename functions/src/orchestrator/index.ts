import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { buildContext, type PageContext } from './context-builder';
import { route } from './router';
import { checkChatLimit, checkToolLimit } from './rate-limiter';
import { formatWithGemini, chatWithContext, generateSuggestions } from './gemini-formatter';
import { runAnalyticsTool } from './tools/analytics-tool';
import { runAlertsTool } from './tools/alerts-tool';
import { runMatchingTool } from './tools/matching-tool';
import { runAidFinderTool } from './tools/aidfinder-tool';
import { runDonationDrivesTool } from './tools/donation-drives-tool';
import { getConversationHistory, appendMessage } from './conversation-memory';

export interface HandleAIRequestInput {
  userId: string;
  message?: string;
  pageContext?: PageContext;
  autoExecute?: boolean;
  metadata?: Record<string, any>;
}

export interface HandleAIRequestOutput {
  text: string;
  data?: any;
  toolUsed?: string | null;
  suggestions?: string[];
}

function setCorsHeaders(res: functions.Response): void {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'OPTIONS, POST, GET');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '86400');
}

/**
 * Core handler logic shared by callable and HTTP. Does not throw.
 */
export async function runHandleAIRequest(
  data: HandleAIRequestInput,
  userId: string
): Promise<HandleAIRequestOutput> {
  const message = typeof data.message === 'string' ? data.message.trim() : undefined;
  const pageContext: PageContext = (data.pageContext || 'chat') as PageContext;
  const autoExecute = !!data.autoExecute;

  const isToolCall = autoExecute || (message && route(message, pageContext, false) !== null);
  const limitResult = isToolCall ? await checkToolLimit(userId) : await checkChatLimit(userId);
  if (!limitResult.allowed) {
    return {
      text: 'Too many requests. Please try again later.',
      toolUsed: null,
    };
  }

  const userContext = await buildContext(userId, pageContext);
  const toolName = route(message, pageContext, autoExecute);

  let toolData: any = null;
  try {
    if (toolName === 'analytics') {
      toolData = await runAnalyticsTool(userId, userContext);
    } else if (toolName === 'alerts') {
      toolData = await runAlertsTool(userId, userContext);
    } else if (toolName === 'matching') {
      toolData = await runMatchingTool(userId, userContext);
    } else if (toolName === 'aidfinder') {
      const opts = data.metadata as { category?: string; urgency?: string } | undefined;
      toolData = await runAidFinderTool(userId, userContext, opts);
    } else if (toolName === 'donation_drives') {
      toolData = await runDonationDrivesTool(userId, userContext);
    }
  } catch (toolError) {
    console.error(`Tool ${toolName} error:`, toolError);
  }

  const conversationHistory = message ? await getConversationHistory(userId, 6) : [];

  let text: string;
  try {
    if (toolData !== null && toolName) {
      text = await formatWithGemini(userContext, toolName, toolData, message);
    } else if (message) {
      text = await chatWithContext(userContext, message, conversationHistory);
    } else {
      text = 'Ask me about alerts, insights, matching, or nearby aid.';
    }
  } catch (geminiError) {
    console.error('Gemini error:', geminiError);
    if (toolData !== null) {
      text = `I found ${toolName === 'alerts' ? toolData.activeAlerts?.length || 0 : 'some'} ${toolName || 'information'}. Check the details above.`;
    } else {
      text = 'I encountered an issue processing your request. Please try again or ask about alerts, insights, matching, or nearby aid.';
    }
  }

  if (message && text) {
    try {
      await appendMessage(userId, 'user', message);
      await appendMessage(userId, 'model', text);
    } catch (appendErr) {
      console.warn('Conversation append failed:', appendErr);
    }
  }

  let suggestions: string[] = [];
  if (toolName === 'alerts') suggestions.push('Show me the latest alerts', 'Any SOS?');
  if (toolName === 'analytics') suggestions.push('What should we focus on?');
  if (toolName === 'matching') suggestions.push('Find more matches', 'What else fits me?');
  if (toolName === 'aidfinder') suggestions.push('Find food banks', 'Nearby resources');
  if (toolName === 'donation_drives') suggestions.push('Find food drives', 'What can I donate?');

  if (message && text) {
    try {
      const aiSuggestions = await generateSuggestions(message, text);
      if (aiSuggestions.length >= 2) suggestions = aiSuggestions;
    } catch {
      // keep static suggestions
    }
  }

  const result: HandleAIRequestOutput = {
    text,
    toolUsed: toolName,
    suggestions: suggestions.length ? suggestions : undefined,
  };
  if (toolData !== null) result.data = toolData;
  return result;
}

/**
 * Callable entry point (can still hit CORS on failure in some clients).
 */
export const handleAIRequest = functions.https.onCall(async (data: HandleAIRequestInput, context): Promise<HandleAIRequestOutput> => {
  const userId = data.userId || context.auth?.uid;
  if (!userId) {
    if (process.env.FUNCTIONS_EMULATOR === 'true') {
      throw new functions.https.HttpsError('invalid-argument', 'userId required in request data');
    }
    throw new functions.https.HttpsError('unauthenticated', 'userId required');
  }
  try {
    return await runHandleAIRequest(data, userId);
  } catch (error: any) {
    console.error('handleAIRequest error:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    return {
      text: 'I encountered an error. Please try again or ask about alerts, insights, matching, or nearby aid.',
      toolUsed: null,
    };
  }
});

/**
 * HTTP endpoint with CORS for web clients. Use this from Flutter web to avoid CORS issues.
 * POST body: { userId, message?, pageContext?, autoExecute?, metadata? }
 * Or send Authorization: Bearer <idToken> and body can omit userId (will use token uid).
 */
export const handleAIRequestHttp = functions.https.onRequest(async (req, res) => {
  // Set CORS headers first, before any response
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  let userId: string | null = null;
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    try {
      const idToken = authHeader.slice(7);
      const decoded = await admin.auth().verifyIdToken(idToken);
      userId = decoded.uid;
    } catch (e) {
      console.warn('Invalid or expired token:', e);
    }
  }

  let data: HandleAIRequestInput;
  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    data = {
      userId: body.userId ?? userId ?? '',
      message: body.message,
      pageContext: body.pageContext,
      autoExecute: body.autoExecute,
      metadata: body.metadata,
    };
  } catch (e) {
    setCorsHeaders(res);
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }

  if (!data.userId) {
    setCorsHeaders(res);
    res.status(401).json({ error: 'userId required (in body or via Authorization Bearer token)' });
    return;
  }

  try {
    const result = await runHandleAIRequest(data, data.userId);
    setCorsHeaders(res);
    res.status(200).json(result);
  } catch (e) {
    console.error('handleAIRequestHttp error:', e);
    setCorsHeaders(res);
    res.status(200).json({
      text: 'I encountered an error. Please try again or ask about alerts, insights, matching, or nearby aid.',
      toolUsed: null,
    });
  }
});
