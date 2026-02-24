/**
 * Analytics prompt engineering — single source of truth for AI analytical insights.
 * Used by analytics.ts (generateAnalyticalInsight, generateAIInsights) and orchestrator/tools/analytics-tool.ts.
 */

export type AnalyticsRole = 'volunteer' | 'ngo' | 'admin';

/** Role-based descriptive insight for the analytics reporting page (user/org/admin). */
export function getRoleBasedDescriptivePrompt(role: AnalyticsRole, metrics: Record<string, unknown>): string {
  if (role === 'volunteer') {
    return `As a volunteer on a volunteering platform, summarize what these contribution metrics say about this user in 2-4 short, encouraging sentences. Be personal and positive.
Hours spent on volunteerism: ${(metrics.hoursVolunteerism as number)?.toFixed(1) ?? 0}
RM spent on donations: ${(metrics.rmDonations as number)?.toFixed(2) ?? 0}
Points collected: ${metrics.pointsCollected ?? 0}`;
  }
  if (role === 'ngo') {
    return `As an organizer on a volunteering platform, summarize what these metrics say about their impact in 2-4 short sentences. Be encouraging and data-driven.
Total volunteers: ${metrics.totalVolunteers ?? 0}
Active campaigns: ${metrics.activeCampaigns ?? 0}
Impact funds (RM): ${(metrics.impactFunds as number)?.toFixed(2) ?? 0}`;
  }
  return `As a platform admin, summarize what these platform metrics indicate in 2-4 short sentences. Focus on health and growth.
Number of users: ${metrics.numberOfUsers ?? 0}
Number of organisations: ${metrics.numberOfOrganisations ?? 0}
Active events: ${metrics.activeEvents ?? 0}`;
}

/** Role-based prescriptive (recommendations) for the analytics reporting page. */
export function getRoleBasedPrescriptivePrompt(role: AnalyticsRole): string {
  if (role === 'volunteer') {
    return `Give 2-3 short, actionable suggestions for this volunteer (e.g. try a new opportunity, set a small donation goal, reach the next tier).`;
  }
  if (role === 'ngo') {
    return `Give 2-3 short, actionable recommendations for this organizer (e.g. recruit more volunteers, launch a campaign, hit a funding goal).`;
  }
  return `Give 2-3 short admin recommendations (e.g. verify pending NGOs, highlight top events, address bottlenecks).`;
}

/** Platform-level descriptive insights (what happened). */
export function getPlatformDescriptivePrompt(metrics: {
  totalUsers?: number;
  totalActivities?: number;
  totalDrives?: number;
  totalAttendances?: number;
  totalDonations?: number;
}): string {
  return `Analyze these volunteer platform metrics and provide descriptive insights (what happened):

Metrics:
- Total Users: ${metrics.totalUsers}
- Total Activities: ${metrics.totalActivities}
- Total Donation Drives: ${metrics.totalDrives}
- Total Volunteer Attendances: ${metrics.totalAttendances}
- Total Donations Raised: RM ${(metrics.totalDonations ?? 0).toFixed(2)}

Provide 3-4 insights explaining trends, patterns, and what these numbers mean. Be concise and data-driven. Format as bullet points.`;
}

/** Platform-level prescriptive recommendations (what to do next). */
export function getPlatformPrescriptivePrompt(metrics: {
  totalUsers?: number;
  totalActivities?: number;
  totalDrives?: number;
  totalAttendances?: number;
  totalDonations?: number;
}): string {
  return `Based on these metrics, provide prescriptive recommendations (what to do next):

Metrics:
- Total Users: ${metrics.totalUsers}
- Total Activities: ${metrics.totalActivities}
- Total Donation Drives: ${metrics.totalDrives}
- Total Volunteer Attendances: ${metrics.totalAttendances}
- Total Donations Raised: RM ${(metrics.totalDonations ?? 0).toFixed(2)}

Provide 3-4 actionable recommendations for:
1. Increasing volunteer engagement
2. Optimizing donation drives
3. Improving user retention
4. Addressing gaps or opportunities

Be specific and actionable. Format as bullet points.`;
}

/** Orchestrator analytics tool: short descriptive summary by role. */
export function getOrchestratorDescriptivePrompt(role: AnalyticsRole, metricsStr: string): string {
  const roleLabel = role === 'volunteer' ? 'volunteer' : role === 'ngo' ? 'organizer' : 'admin';
  return `As a ${roleLabel} on a volunteering platform, summarize these metrics in 2-4 short sentences (what happened). Be encouraging and data-driven.\nMetrics: ${metricsStr}`;
}

/** Orchestrator analytics tool: short prescriptive recommendations. */
export function getOrchestratorPrescriptivePrompt(role: AnalyticsRole, metricsStr: string): string {
  return `Based on these ${role} metrics, give 2-3 actionable recommendations. Be concise.\nMetrics: ${metricsStr}`;
}

/** Orchestrator analytics tool: answer user question about their analytics. */
export function getOrchestratorNLPAnswerPrompt(role: AnalyticsRole, metricsStr: string, userMessage: string): string {
  return `You are an analytics assistant for a volunteering platform. The user (role: ${role}) asked a question about their analytics. Answer it using ONLY the following metrics. Be concise (2-4 sentences), friendly, and actionable. Do not make up numbers.

Metrics:
${metricsStr}

User question: "${userMessage}"

Answer:`;
}
