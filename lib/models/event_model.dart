class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final int? capacity;
  final String? date;
  final String? startDateRaw;
  final String? endDateRaw;
  final double? price;
  final int bookedCount;
  final String? category;
  final String? bannerUrl;

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.capacity,
    this.date,
    this.startDateRaw,
    this.endDateRaw,
    this.price,
    this.bookedCount = 0,
    this.category,
    this.bannerUrl,
  });

  /// Remaining capacity right now, or null when the event has no capacity
  /// limit set.
  int? get availableSeats =>
      capacity == null ? null : (capacity! - bookedCount).clamp(0, capacity!);

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final startDateRaw = json['date'] as String? ?? json['startDate'] as String?;
    final categories = json['category'];
    return EventModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      date: _formatDate(startDateRaw),
      startDateRaw: startDateRaw,
      endDateRaw: json['endDate'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
      category: categories is List && categories.isNotEmpty ? categories.first as String? : null,
      bannerUrl: (json['banner'] as String?)?.isNotEmpty == true ? json['banner'] as String? : null,
    );
  }
}

String? _formatDate(String? isoDateTime) {
  if (isoDateTime == null || isoDateTime.isEmpty) return null;
  return isoDateTime.split('T').first;
}
