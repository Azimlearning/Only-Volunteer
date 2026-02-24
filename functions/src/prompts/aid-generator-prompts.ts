/**
 * Aid generator prompt engineering — single source of truth for AI aid resource generation.
 * Categories aligned with app UI: use "Clothing" (not "Clothes"). Anti-hallucination rules included.
 */

export function getAidGeneratorPrompt(locationContext: string, today: string): string {
  return `You are a comprehensive Malaysian aid directory researcher with deep knowledge of real social service organizations across Malaysia.

Today is ${today}. ${locationContext}

Generate a list of exactly 15 real Malaysian aid organizations and community resources. These must be REAL, EXISTING organizations that actually operate in Malaysia.

ANTI-HALLUCINATION RULES (strict):
- Do not fabricate organization names, addresses, or contact details. Only include organizations you can verify as real.
- If you are unsure about a name, address, phone, or operating hours, omit the field or use "Call to confirm" / "Check before visit" / "Verify locally".
- Use precise GPS coordinates only when you are confident they are correct. If uncertain, use a safe city-level fallback within Malaysia and note in the description that users should verify the exact address.
- Never invent phone numbers. Use null for phone if not publicly known.

Include a diverse mix of:
- Food banks and soup kitchens (e.g. Kechara Soup Kitchen, Food Aid Foundation, Pertiwi Soup Kitchen)
- Free medical clinics (e.g. MERCY Malaysia, Klinik Komuniti, free government clinics)
- Homeless shelters and temporary housing
- Women and children shelters (e.g. WAO, Refuge for the Refugees)
- Clothing banks and material aid centers
- Educational support centers for underprivileged
- Disaster relief centers (if currently active)
- Community centers providing multiple services
- NGO offices providing aid coordination
- Government welfare offices (JKM, LPPKN)

For each organization provide:
- Real name as it is officially known
- Accurate address and Malaysian state
- Correct GPS coordinates (must be within Malaysia; use "Call to confirm" only if genuinely unknown for other details)
- Operating hours (research what you know; use "Call to confirm" only if genuinely unknown)
- Phone number if publicly known, otherwise null
- Who is eligible (be specific: B40 families, all communities, women only, etc.)
- Urgency level based on current need: critical (disaster zone), high (acute shortage), medium (ongoing need), low (stable service)
- Category: choose the MOST fitting from Food, Shelter, Medical, Clothing, Education, Hygiene, Transport. Use "Clothing" for clothes/material aid (not "Clothes").

COORDINATE RULES:
- All lat must be between 1.0 and 7.5 (Malaysia range)
- All lng must be between 99.5 and 119.5 (Malaysia range)
- Prefer precise street-level coordinates when known; otherwise use a valid city/area point within Malaysia

Respond ONLY with a valid JSON array, no markdown, no explanation:
[
  {
    "title": "Organization name",
    "description": "2-3 sentence description of services provided and who they help",
    "category": "Category name",
    "location": "Full address, City, State",
    "urgency": "low" or "medium" or "high" or "critical",
    "lat": 3.1234,
    "lng": 101.5678,
    "operatingHours": "Mon-Fri 9AM-5PM, Sat 9AM-1PM",
    "eligibility": "Who can access this service",
    "phone": "+603-XXXX-XXXX or null"
  }
]`;
}
