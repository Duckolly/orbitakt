class ToiletVisit {
  final int? id;
  final DateTime timestamp;

  // Local calendar date at the time of the visit, in YYYY-MM-DD format.
  // Stored separately so later time zone changes do not regroup history.
  final String date;

  const ToiletVisit({this.id, required this.timestamp, required this.date});

  factory ToiletVisit.at(DateTime timestamp) {
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return ToiletVisit(timestamp: timestamp, date: '$year-$month-$day');
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'date': date,
    };
  }

  factory ToiletVisit.fromMap(Map<String, dynamic> map) {
    return ToiletVisit(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      date: map['date'] as String,
    );
  }
}
