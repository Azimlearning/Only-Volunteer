import { PageContext } from './context-builder';

export type ToolName = 'alerts' | 'analytics' | 'match_me_mini' | 'aidfinder' | 'donation_drives' | null;

const ALERT_KEYWORDS = [
  'alert', 'alerts', 'sos', 'crisis', 'emergency', 'current issues',
  'flood', 'disaster', 'urgent', 'what\'s happening', 'breaking',
];
const ANALYTICS_KEYWORDS = [
  'insight', 'insights', 'stats', 'statistics', 'analytics', 'performance',
  'how are we', 'metrics', 'numbers', 'report', 'dashboard',
];
const MATCHING_KEYWORDS = [
  'match', 'match me', 'recommend', 'recommendation', 'suitable', 'for me',
  'best for me', 'what can i do', 'opportunities for me', 'fit',
];
const DONATION_DRIVES_KEYWORDS = [
  'donation drive', 'donation drives', 'drives', 'food drive', 'food drives',
  'find donation', 'ongoing drives', 'where to donate', 'donation campaign',
];
const AIDFINDER_KEYWORDS = [
  'nearby', 'nearby aid', 'aid', 'find aid', 'food bank', 'foodbank',
  'resource', 'resources', 'help near', 'where can i get', 'donation center',
];

/**
 * Deterministic router: no LLM call.
 * Priority: 1) Page auto-execute, 2) Intent keywords, 3) Page fallback, 4) No tool.
 */
export function route(
  message: string | undefined,
  pageContext: PageContext,
  autoExecute?: boolean
): ToolName {
  const lower = (message || '').toLowerCase().trim();

  // Priority 1: Page auto-execute
  if (autoExecute) {
    if (pageContext === 'analytics') return 'analytics';
    if (pageContext === 'aidfinder') return 'aidfinder';
    if (pageContext === 'alerts') return 'alerts';
    if (pageContext === 'match') return 'match_me_mini';
  }

  // Priority 2: Intent keywords from message (Match Me flow via match_me_mini)
  if (lower) {
    if (ALERT_KEYWORDS.some((k) => lower.includes(k))) return 'alerts';
    if (ANALYTICS_KEYWORDS.some((k) => lower.includes(k))) return 'analytics';
    if (MATCHING_KEYWORDS.some((k) => lower.includes(k))) return 'match_me_mini';
    if (DONATION_DRIVES_KEYWORDS.some((k) => lower.includes(k))) return 'donation_drives';
    if (AIDFINDER_KEYWORDS.some((k) => lower.includes(k))) return 'aidfinder';
  }

  // Priority 3: Page fallback (user on specific page, no clear message)
  if (pageContext === 'analytics') return 'analytics';
  if (pageContext === 'aidfinder') return 'aidfinder';
  if (pageContext === 'alerts') return 'alerts';
  if (pageContext === 'match') return 'match_me_mini';

  return null;
}
