/// Classification of hospital bed types for targeted resource matching.
enum BedType {
  general('General', 'Standard inpatient beds'),
  icu('ICU', 'Intensive Care Unit beds'),
  trauma('Trauma', 'Emergency trauma beds'),
  pediatric('Pediatric', 'Pediatric ward beds');

  const BedType(this.label, this.description);

  final String label;
  final String description;

  /// Maps patient-type keywords to the most relevant bed type.
  static BedType fromQuery(String query) {
    final q = query.toLowerCase();
    if (q.contains('icu') || q.contains('critical') || q.contains('intensive')) {
      return BedType.icu;
    }
    if (q.contains('trauma') || q.contains('accident') || q.contains('injury')) {
      return BedType.trauma;
    }
    if (q.contains('child') || q.contains('pediatric') || q.contains('infant')) {
      return BedType.pediatric;
    }
    return BedType.general;
  }
}
