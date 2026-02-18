// Script to call deployed embedding functions via HTTP
// Requires: npm install axios (already installed)

const axios = require('axios');

// Your deployed function URLs
const PROJECT_ID = 'onlyvolunteer-e3066';
const REGION = 'us-central1';

const FUNCTIONS = {
  activities: `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/embedAllActivities`,
  drives: `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/embedAllDrives`,
  resources: `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/embedAllResources`,
};

async function callFunction(url, name) {
  console.log(`\n📦 Calling ${name}...`);
  try {
    // Note: These functions require authentication
    // You'll need to get an ID token from Firebase Auth
    console.log(`   URL: ${url}`);
    console.log('   ⚠️  This function requires authentication.');
    console.log('   💡 Use Firebase Console instead: https://console.firebase.google.com/project/onlyvolunteer-e3066/functions');
    console.log('   💡 Or get an ID token and use it in the Authorization header');
  } catch (error) {
    console.error(`   ✗ Error: ${error.message}`);
  }
}

console.log('🚀 Embedding Functions Caller');
console.log('═══════════════════════════════════════');
console.log('\n⚠️  These functions require authentication.');
console.log('\n📋 Options:');
console.log('   1. Use Firebase Console (easiest):');
console.log('      https://console.firebase.google.com/project/onlyvolunteer-e3066/functions');
console.log('\n   2. Get ID token and call via HTTP:');
console.log('      - Log in to your Flutter app');
console.log('      - Get the ID token from Firebase Auth');
console.log('      - Use it in Authorization header');
console.log('\n   3. Use Firebase Shell with auth context:');
console.log('      - The shell needs to simulate auth');
console.log('      - Or modify functions temporarily to allow admin');

console.log('\n📝 Function URLs:');
Object.entries(FUNCTIONS).forEach(([key, url]) => {
  console.log(`   ${key}: ${url}`);
});
