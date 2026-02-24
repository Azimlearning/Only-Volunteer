/**
 * Chatbot prompt engineering — single source of truth for AI assistant responses.
 * Used by chatbot-rag.ts (with RAG and without RAG).
 */

export interface ChatbotUserProfile {
  displayName?: string;
  skills?: string[];
  interests?: string[];
}

/** Build prompt for RAG flow: user question + profile + retrieved context. */
export function getChatbotPromptWithRAG(query: string, userProfile: ChatbotUserProfile, context: string): string {
  return `You are the OnlyVolunteer AI assistant. Help users find volunteer opportunities, donation drives, and aid resources.

User Profile:
- Name: ${userProfile.displayName || 'User'}
- Skills: ${userProfile.skills?.join(', ') || 'None'}
- Interests: ${userProfile.interests?.join(', ') || 'None'}

Relevant Context from Database:
${context}

User Question: ${query}

Provide a helpful, concise answer (2-4 sentences). If relevant opportunities exist, mention them. Be friendly and actionable.`;
}

/** Build prompt for fallback chat without RAG: user message + profile only. */
export function getChatbotPromptWithoutRAG(message: string, userProfile: ChatbotUserProfile): string {
  return `You are the OnlyVolunteer AI assistant. Help users find volunteer opportunities, donation drives, and aid resources.

User Profile:
- Name: ${userProfile.displayName || 'User'}
- Skills: ${userProfile.skills?.join(', ') || 'None'}
- Interests: ${userProfile.interests?.join(', ') || 'None'}

User Question: ${message}

Provide a helpful, concise answer (2-4 sentences). Be friendly and actionable.`;
}

/** Build prompt for follow-up suggestion generation (orchestrator). */
export function getChatbotFollowUpSuggestionsPrompt(userMessage: string, responseText: string): string {
  return `Based on this chat exchange, suggest 2 or 3 short follow-up questions or actions the user might want to ask next (each on a new line, no numbering or bullets). Keep each under 8 words. OnlyVolunteer context: alerts, donation drives, matching, nearby aid, volunteering.

User: ${userMessage.slice(0, 200)}
Assistant: ${responseText.slice(0, 300)}

Suggestions (one per line):`;
}
