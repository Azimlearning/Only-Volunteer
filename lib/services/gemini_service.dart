import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/app_user.dart';
import '../models/donation_drive.dart';
import '../models/volunteer_listing.dart';

/// Result from the orchestrator (text + optional tool result and suggestion chips).
class OrchestratorResult {
  const OrchestratorResult({
    required this.text,
    this.suggestions,
    this.toolUsed,
    this.data,
  });

  final String text;
  final List<String>? suggestions;
  /// Tool that produced the response (e.g. alerts, donation_drives, aidfinder, matching).
  final String? toolUsed;
  /// Raw tool payload for rendering type-specific cards (e.g. nearbyAid, drives, activeAlerts).
  final dynamic data;
}

class GeminiService {
  GeminiService({String? apiKey}) : _apiKey = apiKey ?? Config.geminiApiKey;

  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  static List<SafetySetting> get _safetySettings => [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
      ];

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      safetySettings: _safetySettings,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    return _model!;
  }

  void startChat() {
    _chatSession = model.startChat();
  }

  /// Starts a chat session with user context so replies can be personalized.
  void startChatWithContext({
    AppUser? user,
    String? locationSummary,
    List<String> recentActivitySummary = const [],
    String? fallbackMessage,
  }) {
    final contextBlock = _buildContextBlock(
      user: user,
      locationSummary: locationSummary,
      recentActivitySummary: recentActivitySummary,
    );
    if (contextBlock.isEmpty) {
      startChat();
      return;
    }
    final systemPrompt = '''
You are the OnlyVolunteer concierge. You help users with: finding volunteer opportunities, donation drives, how to sign up, how to list activities, e-certificates, leaderboards, and flood/SOS alerts. Be brief and helpful (2-4 sentences). When suggesting activities or drives, you can say "Check the suggestions below" so the user sees the recommended cards.

$contextBlock

Guidelines: Be friendly and concise. Use the user's location and interests when relevant. For "Where can I help today?" suggest opportunities or drives. If you don't know something, suggest they browse Aid Finder, Donation Drives, or Opportunities in the app.''';
    _chatSession = model.startChat(history: [Content.text(systemPrompt)]);
  }

  String _buildContextBlock({
    AppUser? user,
    String? locationSummary,
    List<String> recentActivitySummary = const [],
  }) {
    final parts = <String>[];
    if (user != null) {
      parts.add('User profile: ${user.displayName ?? user.email}; role: ${user.role.name}.');
      if (user.skills.isNotEmpty) parts.add('Skills: ${user.skills.join(", ")}.');
      if (user.interests.isNotEmpty) parts.add('Interests: ${user.interests.join(", ")}.');
      if (user.points > 0) parts.add('Points: ${user.points}.');
    }
    if (locationSummary != null && locationSummary.isNotEmpty) {
      parts.add('Location: $locationSummary');
    }
    if (recentActivitySummary.isNotEmpty) {
      parts.add('Recent activity: ${recentActivitySummary.join("; ")}');
    }
    if (parts.isEmpty) return '';
    return 'Context:\n${parts.join("\n")}';
  }

  /// Context-aware one-off response (no session). Use for first message or when not using session.
  Future<String> generateConciergeResponseWithContext({
    AppUser? user,
    String? locationSummary,
    List<String> recentActivitySummary = const [],
    required String userMessage,
    String? fallbackMessage,
  }) async {
    if (_apiKey.isEmpty) {
      return 'OnlyVolunteer connects volunteers with NGOs and donation drives. Sign in to browse opportunities, get matched by skills, and earn e-certificates. Set GEMINI_API_KEY for full AI help.';
    }
    final contextBlock = _buildContextBlock(
      user: user,
      locationSummary: locationSummary,
      recentActivitySummary: recentActivitySummary,
    );
    const basePrompt = '''
You are the OnlyVolunteer concierge. You help users with: finding volunteer opportunities, donation drives, how to sign up, how to list activities, e-certificates, leaderboards, and flood/SOS alerts. Be brief and helpful (2-4 sentences).''';
    final fullPrompt = contextBlock.isEmpty
        ? '$basePrompt\n\nUser: $userMessage\nAssistant:'
        : '$basePrompt\n\n$contextBlock\n\nUser: $userMessage\nAssistant:';
    try {
      final response = await model.generateContent([Content.text(fullPrompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return fallbackMessage ?? Config.chatbotFallbackMessage;
      }
      return text;
    } catch (_) {
      return fallbackMessage ?? Config.chatbotFallbackMessage;
    }
  }

  /// Session-based chat (use after startChat or startChatWithContext). Returns reply or fallback on error.
  Future<String> chat(String userMessage, {String? fallbackMessage}) async {
    if (_apiKey.isEmpty) {
      return 'OnlyVolunteer helps you find volunteer opportunities and donation drives. Add your GEMINI_API_KEY to enable the AI assistant.';
    }
    if (_chatSession == null) startChat();
    try {
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return fallbackMessage ?? Config.chatbotFallbackMessage;
      }
      return text;
    } catch (_) {
      return fallbackMessage ?? Config.chatbotFallbackMessage;
    }
  }

  /// Returns a short list of recommended drives and opportunities for the user (IDs and titles).
  /// [drives] and [listings] are fetched by the caller; this method ranks/filters them.
  Future<List<Map<String, String>>> getConciergeRecommendations({
    required AppUser user,
    required List<DonationDrive> drives,
    required List<VolunteerListing> listings,
    String? locationSummary,
    int limit = 5,
  }) async {
    if (drives.isEmpty && listings.isEmpty) return [];
    if (_apiKey.isEmpty) {
      final result = <Map<String, String>>[];
      for (final d in drives.take(limit)) {
        result.add({'type': 'drive', 'id': d.id, 'title': d.title});
      }
      for (final l in listings.take(limit - result.length)) {
        result.add({'type': 'listing', 'id': l.id, 'title': l.title});
      }
      return result;
    }
    final drivesSummary = drives.take(15).map((d) => '${d.id}: ${d.title} (${d.location ?? "—"})').join('\n');
    final listingsSummary = listings.take(15).map((l) => '${l.id}: ${l.title} (${l.location ?? "—"})').join('\n');
    final prompt = '''
You are a volunteer-opportunity recommender. User: ${user.displayName ?? user.email}. Skills: ${user.skills.join(", ")}. Interests: ${user.interests.join(", ")}.${locationSummary != null && locationSummary.isNotEmpty ? " Location: $locationSummary." : ""}

Donation drives:
$drivesSummary

Volunteer opportunities:
$listingsSummary

Return a JSON array of exactly $limit items. Each item: {"type":"drive" or "listing","id":"<id>"}. Order: best match first. No other text. Example: [{"type":"drive","id":"abc"},{"type":"listing","id":"xyz"}]''';
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '[]';
      final cleaned = text.replaceAll(RegExp(r'[^\d\w\s,"\[\]:{}\-]'), '');
      final decoded = jsonDecode(cleaned) as List<dynamic>?;
      if (decoded == null) return _defaultRecommendations(drives, listings, limit);
      final result = <Map<String, String>>[];
      final addedIds = <String>{};
      for (final e in decoded) {
        if (result.length >= limit) break;
        if (e is! Map) continue;
        final type = e['type']?.toString();
        final id = e['id']?.toString();
        if (id == null || addedIds.contains(id)) continue;
        if (type == 'drive') {
          final d = drives.cast<DonationDrive?>().firstWhere((x) => x?.id == id, orElse: () => null);
          if (d != null) {
            result.add({'type': 'drive', 'id': d.id, 'title': d.title});
            addedIds.add(id);
          }
        } else if (type == 'listing') {
          final l = listings.cast<VolunteerListing?>().firstWhere((x) => x?.id == id, orElse: () => null);
          if (l != null) {
            result.add({'type': 'listing', 'id': l.id, 'title': l.title});
            addedIds.add(id);
          }
        }
      }
      if (result.isEmpty) return _defaultRecommendations(drives, listings, limit);
      return result;
    } catch (_) {
      return _defaultRecommendations(drives, listings, limit);
    }
  }

  List<Map<String, String>> _defaultRecommendations(
    List<DonationDrive> drives,
    List<VolunteerListing> listings,
    int limit,
  ) {
    final result = <Map<String, String>>[];
    for (final d in drives.take(limit)) {
      result.add({'type': 'drive', 'id': d.id, 'title': d.title});
    }
    for (final l in listings.take(limit - result.length)) {
      result.add({'type': 'listing', 'id': l.id, 'title': l.title});
    }
    return result;
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

  /// One-off concierge response (no session). Prefer chat() with startChatWithContext for multi-turn.
  Future<String> generateConciergeResponse(String userMessage, {String? fallbackMessage}) async {
    return generateConciergeResponseWithContext(
      userMessage: userMessage,
      fallbackMessage: fallbackMessage,
    );
  }

  /// RAG-powered chat using Cloud Functions (with semantic search)
  Future<String> chatWithRAG(String message, String userId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('chatWithRAG');
      final result = await callable.call({
        'message': message,
        'userId': userId,
      });
      return result.data['response'] as String? ?? Config.chatbotFallbackMessage;
    } catch (e) {
      print('RAG chat error: $e');
      // Fallback to regular chat
      return chat(message);
    }
  }

  /// Main AI orchestrator: routes to tools (alerts, analytics, matching, aidfinder) and formats with Gemini.
  /// On web, uses HTTP endpoint with CORS to avoid callable CORS issues.
  Future<String> chatWithOrchestrator(String message, String userId, {String pageContext = 'chat'}) async {
    final result = await chatWithOrchestratorFull(message, userId, pageContext: pageContext);
    return result.text;
  }

  /// Orchestrator that returns both reply text and suggestion chips for quick replies.
  /// [metadata] optional, e.g. matchMeState for mini match-me flow in chatbot.
  Future<OrchestratorResult> chatWithOrchestratorFull(String message, String userId, {String pageContext = 'chat', Map<String, dynamic>? metadata}) async {
    if (kIsWeb) {
      return _chatWithOrchestratorHttpFull(message, userId, pageContext: pageContext, metadata: metadata);
    }
    return _chatWithOrchestratorCallableFull(message, userId, pageContext: pageContext, metadata: metadata);
  }

  /// Web: call HTTP endpoint with CORS so browser allows the request.
  Future<OrchestratorResult> _chatWithOrchestratorHttpFull(String message, String userId, {String pageContext = 'chat', Map<String, dynamic>? metadata}) async {
    try {
      final projectId = Firebase.app().options.projectId ?? 'onlyvolunteer-e3066';
      final url = Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/handleAIRequestHttp',
      );
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final body = jsonEncode({
        'userId': userId,
        'message': message,
        'pageContext': pageContext,
        'autoExecute': false,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      });
      print('Calling handleAIRequestHttp (web) with userId: $userId');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('handleAIRequestHttp timed out'),
          );
      if (response.statusCode != 200) {
        print('handleAIRequestHttp error: ${response.statusCode} ${response.body}');
        final fallback = await _fallbackToRagOrDirect(message, userId);
        return OrchestratorResult(text: fallback, suggestions: []);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      final text = data?['text'] as String?;
      final toolUsed = data?['toolUsed'] as String?;
      final toolData = data?['data'];
      List<String>? suggestions;
      final raw = data?['suggestions'];
      if (raw is List) {
        suggestions = raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      if (text != null && text.isNotEmpty) {
        return OrchestratorResult(
          text: text,
          suggestions: suggestions?.isNotEmpty == true ? suggestions : null,
          toolUsed: toolUsed,
          data: toolData,
        );
      }
      final fallback = await _fallbackToRagOrDirect(message, userId);
      return OrchestratorResult(text: fallback, suggestions: []);
    } catch (e) {
      print('Orchestrator HTTP error: $e');
      final fallback = await _fallbackToRagOrDirect(message, userId);
      return OrchestratorResult(text: fallback, suggestions: []);
    }
  }

  Future<String> _fallbackToRagOrDirect(String message, String userId) async {
    try {
      return chatWithRAG(message, userId);
    } catch (e) {
      print('RAG fallback failed: $e');
      return chat(message);
    }
  }

  /// Non-web (mobile/desktop): use callable.
  Future<OrchestratorResult> _chatWithOrchestratorCallableFull(String message, String userId, {String pageContext = 'chat', Map<String, dynamic>? metadata}) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('handleAIRequest');
      final result = await callable
          .call({
            'userId': userId,
            'message': message,
            'pageContext': pageContext,
            'autoExecute': false,
            if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
          })
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('handleAIRequest timed out'),
          );
      final data = result.data as Map<String, dynamic>?;
      final text = data?['text'] as String?;
      final toolUsed = data?['toolUsed'] as String?;
      final toolData = data?['data'];
      List<String>? suggestions;
      final raw = data?['suggestions'];
      if (raw is List) {
        suggestions = raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      if (text != null && text.isNotEmpty) {
        return OrchestratorResult(
          text: text,
          suggestions: suggestions?.isNotEmpty == true ? suggestions : null,
          toolUsed: toolUsed,
          data: toolData,
        );
      }
      final fallback = await _fallbackToRagOrDirect(message, userId);
      return OrchestratorResult(text: fallback, suggestions: []);
    } on FirebaseFunctionsException catch (e) {
      print('Orchestrator callable error: ${e.code} ${e.message}');
      final fallback = await _fallbackToRagOrDirect(message, userId);
      return OrchestratorResult(text: fallback, suggestions: []);
    } catch (e) {
      print('Orchestrator callable error: $e');
      final fallback = await _fallbackToRagOrDirect(message, userId);
      return OrchestratorResult(text: fallback, suggestions: []);
    }
  }
}
