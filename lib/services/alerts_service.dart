import 'package:http/http.dart' as http;
import 'dart:convert';

const String _triggerUrl =
    'https://us-central1-onlyvolunteer-e3066.cloudfunctions.net/triggerNewsAlerts';

class AlertGenerationResult {
  final bool ok;
  final String message;
  final int articlesProcessed;
  final int alertsCreated;

  AlertGenerationResult({
    required this.ok,
    required this.message,
    required this.articlesProcessed,
    required this.alertsCreated,
  });

  factory AlertGenerationResult.fromJson(Map<String, dynamic> json) {
    return AlertGenerationResult(
      ok: json['ok'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      articlesProcessed: json['articlesProcessed'] as int? ?? 0,
      alertsCreated: json['alertsCreated'] as int? ?? 0,
    );
  }

  factory AlertGenerationResult.error(String message) {
    return AlertGenerationResult(
      ok: false,
      message: message,
      articlesProcessed: 0,
      alertsCreated: 0,
    );
  }
}

/// Triggers AI alert generation. Pass userLocation (e.g. "Selangor") if known.
Future<AlertGenerationResult> triggerNewsAlertsGeneration({String? userLocation}) async {
  try {
    final uri = Uri.parse(_triggerUrl).replace(
      queryParameters: userLocation != null ? {'location': userLocation} : null,
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 55));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AlertGenerationResult.fromJson(json);
    } else {
      return AlertGenerationResult.error('Server error ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    return AlertGenerationResult.error('Failed: $e');
  }
}
