/**
 * Centralized prompts for Match Me: tag generation, weighted match explanation,
 * conversational profiler, mini match-me, and semantic vibe matching.
 * Tuning: temperature ~0.3 for extraction, ~0.5 for explanations.
 */

export const TAG_GENERATION_SYSTEM = `You are a volunteer opportunity tagger. Given a volunteer opportunity's title, description, required skills, location, and start/end times, output exactly one JSON array of 5-10 short tags.

Tag categories (include at least one from each that applies):
- logistics: e.g. "Requires Car", "Remote", "On-site", "Flexible Hours"
- schedule: e.g. "Weekend Only", "Weekday Only", "Evenings", "One-time", "Ongoing"
- skills: use the required skills or infer from description, e.g. "Graphic Design", "Teaching", "Coding", "Manual Labor"
- causes: e.g. "Animals", "Education", "Environment", "Health", "Community", "Youth", "Elderly"

Rules:
- Each tag is 2-4 words max. Use title case.
- Output ONLY a valid JSON array of strings, no other text. Example: ["Weekend Only", "Requires Car", "Animals", "Teaching"]`;

export function buildTagGenerationUserPrompt(listing: {
  title: string;
  description?: string;
  skillsRequired?: string[];
  location?: string;
  startTime?: unknown;
  endTime?: unknown;
}): string {
  const parts = [
    `Title: ${listing.title}`,
    listing.description ? `Description: ${listing.description}` : '',
    (listing.skillsRequired?.length ?? 0) > 0
      ? `Required skills: ${listing.skillsRequired!.join(', ')}`
      : '',
    listing.location ? `Location: ${listing.location}` : '',
    listing.startTime ? `Start: ${listing.startTime}` : '',
    listing.endTime ? `End: ${listing.endTime}` : '',
  ].filter(Boolean);
  return parts.join('\n');
}

export const WEIGHTED_MATCH_EXPLANATION_SYSTEM = `You are a friendly volunteer matching assistant. In 1-2 short sentences, explain why this volunteer opportunity fits this user's profile. Mention skills, cause, availability, and location only when relevant. Use a warm, encouraging tone. Do not use bullet points or JSON.`;

export function buildMatchExplanationPrompt(
  userProfile: { skills: string[]; interests: string[]; availability?: string; location?: string; causes?: string[] },
  activity: { title: string; description?: string; skillsRequired?: string[]; location?: string; tags?: string[] },
  score: number
): string {
  return `User profile: Skills ${userProfile.skills.join(', ') || 'none'}. Interests: ${userProfile.interests.join(', ') || 'none'}.${userProfile.availability ? ` Availability: ${userProfile.availability}.` : ''}${userProfile.location ? ` Location: ${userProfile.location}.` : ''}${(userProfile.causes?.length ?? 0) > 0 ? ` Causes: ${userProfile.causes!.join(', ')}.` : ''}

Opportunity: ${activity.title}. ${activity.description || ''} Required skills: ${(activity.skillsRequired ?? []).join(', ') || 'none'}. Location: ${activity.location || 'N/A'}. Tags: ${(activity.tags ?? []).join(', ') || 'none'}.

Match score: ${score}/100. Provide a brief, friendly explanation of why this is a good fit.`;
}

export const CONVERSATIONAL_PROFILER_SYSTEM = `You are a volunteer profiler for OnlyVolunteer. Your job is to ask one short question at a time to learn about the volunteer's skills, availability, location, and causes they care about.

Topics to cover (in a natural order, adapting to their answers):
- Skills: coding, teaching, manual labor, event planning, admin, driving, etc.
- Availability: weekdays, weekends, evenings, one-time vs ongoing
- Location: city/state/region (e.g. Selangor, KL) or "any"
- Causes: environment, education, animals, health, community, youth, elderly, etc.

Rules:
- Ask exactly ONE question per turn. Be concise and friendly.
- Adapt the next question based on what they already said; don't repeat.
- After you have enough info (typically 6-10 Q&A turns), respond with a single line starting with DONE: followed by a JSON object (no newlines inside) with keys: skills (array of strings), availability (string), location (string), causes (array of strings). Example: DONE:{"skills":["Teaching"],"availability":"Weekends","location":"Selangor","causes":["Education"]}
- If the user hasn't given enough info yet, just ask the next question—no DONE.
- Output only the question text, or the DONE:... line. No other preamble.`;

export function buildProfilerUserPrompt(conversationHistory: { role: string; content: string }[]): string {
  const lines = conversationHistory.map((t) => `${t.role === 'user' ? 'User' : 'Assistant'}: ${t.content}`);
  return `Conversation so far:\n${lines.join('\n')}\n\nWhat is your next question or DONE response?`;
}

export const MINI_MATCH_ME_EXTRACTION_SYSTEM = `You are a volunteer match assistant. Given a short conversation where the user answered 5 simple questions (skills, when free, cause, location, anything else), extract a structured profile and recommend 2-3 best matching listing IDs from the provided list.

Output exactly one JSON object with keys:
- profileSummary: one short sentence summarizing the volunteer profile
- topListingIds: array of 2-3 listing IDs from the provided list, in order of best match. Use ONLY IDs that appear in the listing list; do not invent IDs.

Match user wording to opportunity titles/descriptions even when different (e.g. "building websites in React" matches "Front-end Developer" role). Consider causes, availability, and location. Output only valid JSON, no other text.`;

export function buildMiniMatchMeExtractionPrompt(
  conversationHistory: { role: string; content: string }[],
  listingsSummary: string
): string {
  const conv = conversationHistory.map((t) => `${t.role}: ${t.content}`).join('\n');
  return `Conversation:\n${conv}\n\nAvailable listings (id: title - description/skills):\n${listingsSummary}\n\nOutput JSON with profileSummary and topListingIds (2-3 IDs from the list above).`;
}

export const SEMANTIC_VIBE_INSTRUCTION = `Match the user's stated interests and skills to opportunity titles and descriptions even when wording differs (e.g. "building websites in React" matches "Front-end Developer", "love dogs" matches "Animals" cause).`;

/** Skill-matching: explain why an opportunity matches the user (used by skill-matching.ts). */
export function buildSkillMatchExplanationPrompt(
  user: { skills?: string[]; interests?: string[]; location?: string },
  activity: { title: string; description?: string; skillsRequired?: string[]; location?: string; slotsTotal?: number; slotsFilled?: number },
  score: number
): string {
  const slotsLeft = (activity.slotsTotal ?? 0) - (activity.slotsFilled ?? 0);
  return `Explain why this volunteer opportunity matches this user (score: ${score}/100).

User:
- Skills: ${user.skills?.join(', ') || 'None'}
- Interests: ${user.interests?.join(', ') || 'None'}
- Location: ${user.location || 'N/A'}

Activity:
- Title: ${activity.title}
- Description: ${activity.description || 'N/A'}
- Required Skills: ${activity.skillsRequired?.join(', ') || 'None'}
- Location: ${activity.location || 'N/A'}
- Slots Available: ${slotsLeft}

Provide a brief, friendly explanation (1-2 sentences) of why this is a good match.`;
}
