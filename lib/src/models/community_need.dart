/// A community need report — represents scattered field data
/// from NGOs, surveys, and field workers that gets unified here.
class CommunityNeed {
  final String id;
  final String title;
  final String description;
  final String reportedBy; // NGO or field worker name
  final String area; // locality / ward
  final String category; // 'healthcare', 'resources', 'shelter', 'food'
  final NeedUrgency urgency;
  final DateTime reportedAt;
  final bool isResolved;
  final String? assignedVolunteerName;

  const CommunityNeed({
    required this.id,
    required this.title,
    required this.description,
    required this.reportedBy,
    required this.area,
    required this.category,
    required this.urgency,
    required this.reportedAt,
    this.isResolved = false,
    this.assignedVolunteerName,
  });

  String get urgencyLabel {
    switch (urgency) {
      case NeedUrgency.critical:
        return 'CRITICAL';
      case NeedUrgency.high:
        return 'HIGH';
      case NeedUrgency.medium:
        return 'MEDIUM';
      case NeedUrgency.low:
        return 'LOW';
    }
  }
}

enum NeedUrgency { critical, high, medium, low }
