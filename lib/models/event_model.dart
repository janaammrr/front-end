class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final int? capacity;
  final String? date;
  final double? price;

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.capacity,
    this.date,
    this.price,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      date: _formatDate(json['date'] as String? ?? json['startDate'] as String?),
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

String? _formatDate(String? isoDateTime) {
  if (isoDateTime == null || isoDateTime.isEmpty) return null;
  return isoDateTime.split('T').first;
}
