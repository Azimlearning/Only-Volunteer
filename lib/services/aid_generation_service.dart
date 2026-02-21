import 'package:http/http.dart' as http;
import 'dart:convert';

const String _generateUrl =
    'https://us-central1-onlyvolunteer-e3066.cloudfunctions.net/generateAidResources';

class AidGenerationResult {
  final bool ok;
  final String message;
  final int resourcesCreated;

  AidGenerationResult({
    required this.ok,
    required this.message,
    required this.resourcesCreated,
  });

  factory AidGenerationResult.fromJson(Map<String, dynamic> json) {
    return AidGenerationResult(
      ok: json['ok'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      resourcesCreated: json['resourcesCreated'] as int? ?? 0,
    );
  }

  factory AidGenerationResult.error(String message) =>
      AidGenerationResult(ok: false, message: message, resourcesCreated: 0);
}

class AidGenerationService {
  /// Generate AI aid resources. Optionally pass GPS coords and location name.
  static Future<AidGenerationResult> generate({
    double? lat,
    double? lng,
    String? location,
  }) async {
    try {
      final params = <String, String>{};
      if (lat != null) params['lat'] = lat.toStringAsFixed(6);
      if (lng != null) params['lng'] = lng.toStringAsFixed(6);
      if (location != null && location.isNotEmpty) params['location'] = location;

      final uri = Uri.parse(_generateUrl).replace(queryParameters: params.isEmpty ? null : params);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 55));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AidGenerationResult.fromJson(json);
      } else {
        return AidGenerationResult.error('Server error ${response.statusCode}');
      }
    } catch (e) {
      return AidGenerationResult.error('Failed: $e');
    }
  }
}
