/// App configuration. Replace with values from Firebase Console and Google AI Studio.
class Config {
  Config._();

  /// Gemini API key from https://aistudio.google.com/apikey
  /// Pass at run: flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key
  static String get geminiApiKey =>
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const String appName = 'OnlyVolunteer';
}
