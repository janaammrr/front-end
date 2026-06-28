class WorkshopModel {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final int? capacity;

  const WorkshopModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.capacity,
  });

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    return WorkshopModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
    );
  }
}
