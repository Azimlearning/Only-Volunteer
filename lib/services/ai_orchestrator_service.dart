import 'package:cloud_functions/cloud_functions.dart';

/// Page context sent to the AI orchestrator (must match backend PageContext).
enum PageContext {
  home,
  analytics,
  aidfinder,
  alerts,
  match,
  chat,
}

/// Response from handleAIRequest.
class AIOrchestratorResponse {
  AIOrchestratorResponse({
    required this.text,
    this.data,
    this.toolUsed,
    this.suggestions,
  });

  final String text;
  final dynamic data;
  final String? toolUsed;
  final List<String>? suggestions;

  factory AIOrchestratorResponse.fromMap(Map<String, dynamic> map) {
    return AIOrchestratorResponse(
      text: map['text'] as String? ?? '',
      data: map['data'],
      toolUsed: map['toolUsed'] as String?,
      suggestions: (map['suggestions'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// Calls the central AI orchestrator (handleAIRequest).
/// Use for: main chatbot (tool routing) and page auto-execute.
class AIOrchestratorService {
  final _functions = FirebaseFunctions.instance;

  /// Call the orchestrator. [message] can be null for page auto-execute.
  Future<AIOrchestratorResponse> request({
    required String userId,
    String? message,
    PageContext pageContext = PageContext.chat,
    bool autoExecute = false,
    Map<String, dynamic>? metadata,
  }) async {
    final callable = _functions.httpsCallable('handleAIRequest');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      if (message != null && message.isNotEmpty) 'message': message,
      'pageContext': _pageContextToString(pageContext),
      'autoExecute': autoExecute,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    });
    return AIOrchestratorResponse.fromMap(Map<String, dynamic>.from(result.data));
  }

  String _pageContextToString(PageContext ctx) {
    switch (ctx) {
      case PageContext.home:
        return 'home';
      case PageContext.analytics:
        return 'analytics';
      case PageContext.aidfinder:
        return 'aidfinder';
      case PageContext.alerts:
        return 'alerts';
      case PageContext.match:
        return 'match';
      case PageContext.chat:
        return 'chat';
    }
  }
}
