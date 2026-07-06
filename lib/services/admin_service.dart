import '../components/listing_widgets.dart' show stripCategoryTag;
import 'api_client.dart';

class AdminUserItem {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String role;
  final bool suspended;

  const AdminUserItem({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.role,
    required this.suspended,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory AdminUserItem.fromJson(Map<String, dynamic> j) => AdminUserItem(
    id: (j['id'] as num).toInt(),
    firstname: j['firstname'] as String? ?? j['firstName'] as String? ?? '',
    lastname: j['lastname'] as String? ?? j['lastName'] as String? ?? '',
    email: j['email'] as String? ?? '',
    role: j['role'] as String? ?? 'USER',
    suspended: j['suspended'] as bool? ?? false,
  );
}

class AdminPostItem {
  final int id;
  final String content;
  final String authorName;
  final bool suspended;

  const AdminPostItem({
    required this.id,
    required this.content,
    required this.authorName,
    required this.suspended,
  });

  factory AdminPostItem.fromJson(Map<String, dynamic> j) {
    final author = j['author'] as Map<String, dynamic>? ?? j['user'] as Map<String, dynamic>? ?? const {};
    final firstName = author['firstName'] as String? ?? author['firstname'] as String? ?? '';
    final lastName = author['lastName'] as String? ?? author['lastname'] as String? ?? '';
    return AdminPostItem(
      id: (j['id'] as num).toInt(),
      content: j['content'] as String? ?? '',
      authorName: '$firstName $lastName'.trim(),
      suspended: j['suspended'] as bool? ?? false,
    );
  }
}

class AdminListingItem {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final String? date;
  final double? price;
  final int? capacity;
  final bool suspended;

  const AdminListingItem({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.date,
    this.price,
    this.capacity,
    required this.suspended,
  });

  factory AdminListingItem.fromJson(Map<String, dynamic> j) => AdminListingItem(
    id: (j['id'] as num).toInt(),
    title: j['title'] as String? ?? '',
    description: j['description'] == null ? null : stripCategoryTag(j['description'] as String),
    location: j['location'] as String?,
    date: (j['date'] as String? ?? j['startDate'] as String?)?.split('T').first,
    price: (j['price'] as num?)?.toDouble(),
    capacity: (j['capacity'] as num?)?.toInt(),
    suspended: j['suspended'] as bool? ?? false,
  );
}

class AdminReportItem {
  final int id;
  final String targetType;
  final int? targetId;
  final String reason;
  final String status;
  final String reporterName;

  const AdminReportItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.reporterName,
  });

  factory AdminReportItem.fromJson(Map<String, dynamic> j) {
    final reporter = j['reporter'] as Map<String, dynamic>? ?? const {};
    final firstName = reporter['firstName'] as String? ?? reporter['firstname'] as String? ?? '';
    final lastName = reporter['lastName'] as String? ?? reporter['lastname'] as String? ?? '';
    return AdminReportItem(
      id: (j['id'] as num).toInt(),
      targetType: j['targetType'] as String? ?? '',
      targetId: (j['targetId'] as num?)?.toInt(),
      reason: j['reason'] as String? ?? '',
      status: j['status'] as String? ?? 'PENDING',
      reporterName: '$firstName $lastName'.trim(),
    );
  }
}

/// Backs the /admin/* area of the web app (Users, Posts, Providers, Reports,
/// Events, Workshops). All endpoints require an ADMIN-role account.
class AdminService {
  static Future<List<AdminUserItem>> getUsers() async {
    final res = await ApiClient.instance.get('/api/admin/users');
    return (res.data as List<dynamic>)
        .map((e) => AdminUserItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteUser(int id) =>
      ApiClient.instance.delete('/api/admin/users/$id');

  static Future<void> setUserRole(int id, String role) => ApiClient.instance.put(
    '/api/admin/users/$id/role',
    data: {'role': role},
  );

  static Future<void> setUserSuspended(int id, bool suspended, {String reason = ''}) =>
      ApiClient.instance.put(
        '/api/admin/users/$id/suspension',
        data: {'suspended': suspended, 'reason': reason},
      );

  static Future<List<AdminPostItem>> getPosts() async {
    final res = await ApiClient.instance.get('/api/admin/posts');
    return (res.data as List<dynamic>)
        .map((e) => AdminPostItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deletePost(int id) =>
      ApiClient.instance.delete('/api/admin/posts/$id');

  static Future<void> setPostSuspended(int id, bool suspended, {String reason = ''}) =>
      ApiClient.instance.put(
        '/api/admin/posts/$id/suspension',
        data: {'suspended': suspended, 'reason': reason},
      );

  static Future<List<AdminUserItem>> getProviders() async {
    final res = await ApiClient.instance.get('/api/admin/providers');
    return (res.data as List<dynamic>)
        .map((e) => AdminUserItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteProvider(int id) =>
      ApiClient.instance.delete('/api/admin/providers/$id');

  static Future<void> setProviderSuspended(int id, bool suspended, {String reason = ''}) =>
      ApiClient.instance.put(
        '/api/admin/providers/$id/suspension',
        data: {'suspended': suspended, 'reason': reason},
      );

  static Future<List<AdminListingItem>> getEvents() async {
    final res = await ApiClient.instance.get('/api/admin/events');
    return (res.data as List<dynamic>)
        .map((e) => AdminListingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteEvent(int id) =>
      ApiClient.instance.delete('/api/admin/events/$id');

  static Future<void> setEventSuspended(int id, bool suspended, {String reason = ''}) =>
      ApiClient.instance.put(
        '/api/admin/events/$id/suspension',
        data: {'suspended': suspended, 'reason': reason},
      );

  static Future<void> updateEvent(
    int id, {
    required String title,
    String description = '',
    String location = '',
    String date = '',
    double price = 0,
  }) =>
      ApiClient.instance.put(
        '/api/admin/events/$id',
        data: {
          'title': title,
          'description': description,
          'location': location,
          'startDate': date.isEmpty ? null : (date.contains('T') ? date : '${date}T00:00:00'),
          'price': price,
        },
      );

  static Future<List<AdminListingItem>> getWorkshops() async {
    final res = await ApiClient.instance.get('/api/admin/workshops');
    return (res.data as List<dynamic>)
        .map((e) => AdminListingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteWorkshop(int id) =>
      ApiClient.instance.delete('/api/admin/workshops/$id');

  static Future<void> setWorkshopSuspended(int id, bool suspended, {String reason = ''}) =>
      ApiClient.instance.put(
        '/api/admin/workshops/$id/suspension',
        data: {'suspended': suspended, 'reason': reason},
      );

  static Future<void> updateWorkshop(
    int id, {
    required String title,
    String description = '',
    String location = '',
    int capacity = 0,
    String date = '',
    double price = 0,
  }) =>
      ApiClient.instance.put(
        '/api/admin/workshops/$id',
        data: {
          'title': title,
          'description': description,
          'location': location,
          'capacity': capacity > 0 ? capacity : null,
          'startDate': date.isEmpty ? null : (date.contains('T') ? date : '${date}T00:00:00'),
          'price': price,
        },
      );

  static Future<List<AdminReportItem>> getReports({String status = 'PENDING'}) async {
    final res = await ApiClient.instance.get(
      '/api/admin/reports',
      queryParameters: {'status': status},
    );
    return (res.data as List<dynamic>)
        .map((e) => AdminReportItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateReportStatus(
    int id,
    String status, {
    String reviewNote = '',
  }) =>
      ApiClient.instance.put(
        '/api/admin/reports/$id/status',
        data: {'status': status, 'reviewNote': reviewNote},
      );
}
