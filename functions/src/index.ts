import 'dotenv/config';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Export all functions
export * from './news-alerts';
export * from './chatbot-rag';
export * from './analytics';
export * from './skill-matching';
export * from './orchestrator';
