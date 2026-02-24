import '../features/analytics/analytics_data.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

/// Data ingestion for the analytical reporting page: one API per role.
/// Uses a short-lived cache to avoid hammering the DB on repeated visits.
class AnalyticsDataService {
  AnalyticsDataService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  static const _timeout = Duration(seconds: 10);
  static const _cacheValidFor = Duration(minutes: 2);

  String? _cachedKey;
  AnalyticsPayload? _cachedPayload;
  DateTime? _cachedAt;

  /// Returns role-scoped analytics payload; on error returns payload with defaults and optional error message.
  /// Uses in-memory cache for [duration] (default 2 min) to reduce read load.
  Future<AnalyticsPayload> getData(String userId, UserRole role, {bool bypassCache = false}) async {
    final key = '$userId|${role.name}';
    if (!bypassCache && _cachedKey == key && _cachedPayload != null && _cachedAt != null) {
      if (DateTime.now().difference(_cachedAt!) < _cacheValidFor) {
        return _cachedPayload!;
      }
    }

    try {
      AnalyticsPayload payload;
      switch (role) {
        case UserRole.volunteer:
          final m = await _firestore.getUserAnalyticsMetrics(userId).timeout(
                _timeout,
                onTimeout: () => (hoursVolunteerism: 0.0, rmDonations: 0.0, points: 0),
              );
          payload = AnalyticsPayload(
            role: role,
            userData: UserAnalyticsData(
              hoursVolunteerism: m.hoursVolunteerism,
              rmDonations: m.rmDonations,
              pointsCollected: m.points,
            ),
          );
          break;
        case UserRole.ngo:
          final m = await _firestore.getOrganizerAnalyticsMetrics(userId).timeout(
                _timeout,
                onTimeout: () => (totalVolunteers: 0, activeCampaigns: 0, impactFunds: 0.0),
              );
          payload = AnalyticsPayload(
            role: role,
            organizerData: OrganizerAnalyticsData(
              totalVolunteers: m.totalVolunteers,
              activeCampaigns: m.activeCampaigns,
              impactFunds: m.impactFunds,
            ),
          );
          break;
        case UserRole.admin:
          final m = await _firestore.getAdminAnalyticsMetrics().timeout(
                _timeout,
                onTimeout: () => (numberOfUsers: 0, numberOfOrganisations: 0, activeEvents: 0),
              );
          payload = AnalyticsPayload(
            role: role,
            adminData: AdminAnalyticsData(
              numberOfUsers: m.numberOfUsers,
              numberOfOrganisations: m.numberOfOrganisations,
              activeEvents: m.activeEvents,
            ),
          );
          break;
      }
      _cachedKey = key;
      _cachedPayload = payload;
      _cachedAt = DateTime.now();
      return payload;
    } catch (e) {
      switch (role) {
        case UserRole.volunteer:
          return AnalyticsPayload(role: role, userData: UserAnalyticsData.empty, error: e.toString());
        case UserRole.ngo:
          return AnalyticsPayload(role: role, organizerData: OrganizerAnalyticsData.empty, error: e.toString());
        case UserRole.admin:
          return AnalyticsPayload(role: role, adminData: AdminAnalyticsData.empty, error: e.toString());
      }
    }
  }
}
