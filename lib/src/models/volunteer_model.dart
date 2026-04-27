import 'dart:math';

enum VolunteerStatus { available, enRoute, unavailable }

class Volunteer {
  final String id;
  final String name;
  final String vehicleType; // "Sedan", "Van", "Pickup"
  final double latitude;
  final double longitude;
  final VolunteerStatus status;
  final int capacityKg;
  final String phone;

  const Volunteer({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.capacityKg,
    required this.phone,
  });

  String get statusLabel {
    switch (status) {
      case VolunteerStatus.available:
        return 'Available';
      case VolunteerStatus.enRoute:
        return 'Assigned';
      case VolunteerStatus.unavailable:
        return 'Unavailable';
    }
  }

  /// Haversine distance in km to a target lat/lng.
  double distanceTo(double targetLat, double targetLng) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(targetLat - latitude);
    final dLng = _toRad(targetLng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(latitude)) *
            cos(_toRad(targetLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
