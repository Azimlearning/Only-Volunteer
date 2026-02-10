import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { flood, sos, general }

class Alert {
  Alert({
    required this.id,
    required this.title,
    this.body,
    this.type = AlertType.general,
    this.region,
    this.severity,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String? body;
  final AlertType type;
  final String? region;
  final String? severity;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory Alert.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return Alert(
      id: doc.id,
      title: m['title'] as String? ?? '',
      body: m['body'] as String?,
      type: _typeFrom(m['type']),
      region: m['region'] as String?,
      severity: m['severity'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  static AlertType _typeFrom(dynamic v) {
    if (v == 'flood') return AlertType.flood;
    if (v == 'sos') return AlertType.sos;
    return AlertType.general;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'region': region,
      'severity': severity,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}
