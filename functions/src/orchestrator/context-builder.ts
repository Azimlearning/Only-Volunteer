import * as admin from 'firebase-admin';

export type PageContext = 'home' | 'analytics' | 'aidfinder' | 'alerts' | 'match' | 'chat';

export interface UserContext {
  userId: string;
  displayName?: string;
  email?: string;
  role?: string;
  skills: string[];
  interests: string[];
  location?: string;
  totalHours?: number;
  recentActivitySummary: string[];
  pageContext: PageContext;
}

const db = admin.firestore();

/**
 * Build user context for the AI orchestrator.
 * Injects profile, location, volunteer history, and current page.
 */
export async function buildContext(
  userId: string,
  pageContext: PageContext
): Promise<UserContext> {
  const context: UserContext = {
    userId,
    skills: [],
    interests: [],
    recentActivitySummary: [],
    pageContext,
  };

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const user = userDoc.data();
    if (user) {
      context.displayName = user.displayName;
      context.email = user.email;
      context.role = user.role;
      context.skills = user.skills || [];
      context.interests = user.interests || [];
      context.location = user.location;
    }

    // Optional: recent attendances for "total hours" and summary
    try {
      let attendancesSnap;
      try {
        // Try with orderBy first
        attendancesSnap = await db
          .collection('attendances')
          .where('userId', '==', userId)
          .orderBy('createdAt', 'desc')
          .limit(5)
          .get();
      } catch (orderByError) {
        // Fallback: get without orderBy and sort in memory
        attendancesSnap = await db
          .collection('attendances')
          .where('userId', '==', userId)
          .limit(20)
          .get();
      }

      let totalHours = 0;
      const summaries: string[] = [];
      const docs = attendancesSnap.docs.sort((a, b) => {
        const aTime = a.data().createdAt?.toMillis?.() || 0;
        const bTime = b.data().createdAt?.toMillis?.() || 0;
        return bTime - aTime;
      });
      
      docs.slice(0, 5).forEach((doc) => {
        const d = doc.data();
        const hrs = d.hours ?? 0;
        totalHours += typeof hrs === 'number' ? hrs : 0;
        if (d.listingTitle) summaries.push(`Volunteered: ${d.listingTitle}`);
      });
      context.totalHours = totalHours;
      context.recentActivitySummary = summaries.slice(0, 3);
    } catch (attendanceError) {
      console.warn('Failed to load attendances:', attendanceError);
      // Continue without attendance data
    }
  } catch (e) {
    console.warn('Context build partial failure:', e);
  }

  return context;
}

/**
 * Serialize context for Gemini system prompt.
 */
export function contextToPromptBlock(ctx: UserContext): string {
  const parts: string[] = [
    `User: ${ctx.displayName || ctx.email || 'User'}`,
    `Role: ${ctx.role || 'volunteer'}`,
    `Location: ${ctx.location || 'Not set'}`,
    `Skills: ${ctx.skills.length ? ctx.skills.join(', ') : 'None'}`,
    `Interests: ${ctx.interests.length ? ctx.interests.join(', ') : 'None'}`,
    `Total volunteer hours: ${ctx.totalHours ?? 0}`,
    `Current page: ${ctx.pageContext}`,
  ];
  if (ctx.recentActivitySummary.length) {
    parts.push(`Recent activity: ${ctx.recentActivitySummary.join('; ')}`);
  }
  return parts.join('\n');
}
