/// App configuration. Replace with values from Firebase Console and Google AI Studio.
class Config {
  Config._();

  /// Gemini API key from https://aistudio.google.com/apikey
  /// Pass at run: flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key
  static String get geminiApiKey =>
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const String appName = 'OnlyVolunteer';

  /// Chatbot: max characters per user message.
  static const int chatbotMaxInputLength = 500;

  /// Chatbot: message shown when API fails or content is blocked.
  static const String chatbotFallbackMessage =
      "I couldn't process that. Try asking about volunteer opportunities, donation drives, or how to earn e-certificates.";

  /// Leaderboard: points per verified volunteer hour.
  static const int pointsPerVolunteerHour = 10;
  /// Leaderboard: bonus points per donation (fixed per donation; or use pointsPerDonationDollar).
  static const int pointsPerDonationBonus = 5;
}
