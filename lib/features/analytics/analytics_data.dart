import '../../models/app_user.dart';

/// Role-scoped analytics payloads for the analytical reporting page.

/// User (volunteer) – 3 metrics: hours volunteerism, RM donations, points.
class UserAnalyticsData {
  const UserAnalyticsData({
    required this.hoursVolunteerism,
    required this.rmDonations,
    required this.pointsCollected,
  });

  final double hoursVolunteerism;
  final double rmDonations;
  final int pointsCollected;

  static const empty = UserAnalyticsData(
    hoursVolunteerism: 0,
    rmDonations: 0,
    pointsCollected: 0,
  );
}

/// Organizer (NGO) – 3 metrics: total volunteers, active campaigns, impact funds.
class OrganizerAnalyticsData {
  const OrganizerAnalyticsData({
    required this.totalVolunteers,
    required this.activeCampaigns,
    required this.impactFunds,
  });

  final int totalVolunteers;
  final int activeCampaigns;
  final double impactFunds;

  static const empty = OrganizerAnalyticsData(
    totalVolunteers: 0,
    activeCampaigns: 0,
    impactFunds: 0,
  );
}

/// Admin – 3 metrics: number of users, number of organisations, active events.
class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.numberOfUsers,
    required this.numberOfOrganisations,
    required this.activeEvents,
  });

  final int numberOfUsers;
  final int numberOfOrganisations;
  final int activeEvents;

  static const empty = AdminAnalyticsData(
    numberOfUsers: 0,
    numberOfOrganisations: 0,
    activeEvents: 0,
  );
}

/// Union of role-specific analytics for the screen.
class AnalyticsPayload {
  const AnalyticsPayload({
    required this.role,
    this.userData,
    this.organizerData,
    this.adminData,
    this.error,
  });

  final UserRole role;
  final UserAnalyticsData? userData;
  final OrganizerAnalyticsData? organizerData;
  final AdminAnalyticsData? adminData;
  final String? error;

  bool get hasError => error != null && error!.isNotEmpty;
}
