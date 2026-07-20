/// Type of entity a report points at.
enum ReportTargetType {
  post('post'),
  stream('stream'),
  message('message'),
  user('user');

  const ReportTargetType(this.wireValue);

  final String wireValue;

  static ReportTargetType fromWire(String value) {
    return ReportTargetType.values.firstWhere(
      (t) => t.wireValue == value,
      orElse: () => ReportTargetType.post,
    );
  }
}
