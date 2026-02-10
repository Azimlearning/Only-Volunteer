import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config.dart';
import '../models/app_user.dart';
import '../models/volunteer_listing.dart';

class GeminiService {
  GeminiService({String? apiKey}) : _apiKey = apiKey ?? Config.geminiApiKey;

  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  GenerativeModel get model {
    _model ??= GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    return _model!;
  }

  void startChat() {
    _chatSession = model.startChat();
  }

  /// Smart Skill & Activity Matcher: returns ranked listing IDs or JSON.
  Future<List<String>> matchListingsForUser(AppUser user, List<VolunteerListing> listings) async {
    if (_apiKey.isEmpty) return listings.take(5).map((e) => e.id).toList();
    final skillsStr = user.skills.join(', ');
    final interestsStr = user.interests.join(', ');
    final listingsSummary = listings.map((l) => '${l.id}: ${l.title} (${l.skillsRequired.join(", ")})').take(30).join('\n');
    final prompt = '''
You are a volunteer-opportunity matcher. Given this user profile and list of opportunities, return only a JSON array of listing IDs in order of best match (best first). No other text.
User skills: $skillsStr. User interests: $interestsStr.
Listings:
$listingsSummary
JSON array of IDs:''';
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '[]';
      final cleaned = text.replaceAll(RegExp(r'[^\d\w\s,"\[\]]'), '');
      final decoded = jsonDecode(cleaned) as List<dynamic>?;
      if (decoded != null) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return listings.take(5).map((e) => e.id).toList();
  }

  /// Contextual Search: natural language query to filters/suggestions.
  Future<String> contextualSearch(String query, String userType) async {
    if (_apiKey.isEmpty) return 'Try searching by keyword: education, health, environment, or location.';
    final prompt = '''
You are a search assistant for a volunteer and aid platform. User type: $userType. Query: "$query".
In 1-2 short sentences, suggest what they might be looking for and keywords to try (e.g. category, location, skill). Keep it friendly and concise.''';
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Try refining your search.';
    } catch (_) {
      return 'Try refining your search.';
    }
  }

  /// Proactive SOS/Flood: summarize or draft alert text.
  Future<String> draftAlertSummary(String rawInfo, String type) async {
    if (_apiKey.isEmpty) return rawInfo;
    final prompt = '''
You are an emergency alert assistant. Type: $type. Raw info: $rawInfo
Draft a short, clear alert title and 1-2 sentence summary for volunteers. Be factual and actionable.''';
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? rawInfo;
    } catch (_) {
      return rawInfo;
    }
  }

  /// Universal Concierge Chatbot.
  Future<String> chat(String userMessage) async {
    if (_apiKey.isEmpty) {
      return 'OnlyVolunteer helps you find volunteer opportunities and donation drives. Add your GEMINI_API_KEY to enable the AI assistant.';
    }
    if (_chatSession == null) startChat();
    try {
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      return response.text?.trim() ?? 'I couldn\'t generate a response.';
    } catch (e) {
      return 'Sorry, something went wrong. Please try again.';
    }
  }

  /// One-off concierge response (no session).
  Future<String> generateConciergeResponse(String userMessage) async {
    if (_apiKey.isEmpty) {
      return 'OnlyVolunteer connects volunteers with NGOs and donation drives. Sign in to browse opportunities, get matched by skills, and earn e-certificates. Set GEMINI_API_KEY for full AI help.';
    }
    const systemContext = '''
You are the OnlyVolunteer concierge. You help users with: finding volunteer opportunities, donation drives, how to sign up, how to list activities, e-certificates, leaderboards, and flood/SOS alerts. Be brief and helpful (2-4 sentences).''';
    try {
      final response = await model.generateContent([Content.text('$systemContext\n\nUser: $userMessage\nAssistant:')]);
      return response.text?.trim() ?? 'I\'m not sure how to help with that. Try "How do I volunteer?" or "List a drive".';
    } catch (_) {
      return 'I\'m having trouble responding. Please try again.';
    }
  }
}
