/**
 * Single source of truth for Gemini API key and model.
 * - API key: set GEMINI_API_KEY in functions/.env (local) or Cloud Console env vars (production).
 * - .env is not deployed; production must set GEMINI_API_KEY in the function's environment.
 */
export const GEMINI_MODEL = 'gemini-2.5-flash';

export function getGeminiApiKey(): string {
  const key = (process.env.GEMINI_API_KEY || '').trim();
  return key;
}

export function isGeminiConfigured(): boolean {
  const key = getGeminiApiKey();
  return key.length >= 10;
}
