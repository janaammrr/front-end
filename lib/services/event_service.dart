import '../models/event_model.dart';
import 'api_client.dart';

class EventService {
  static Future<List<Map<String, dynamic>>> getBookedRows() async {
    final response = await ApiClient.instance.get('/api/events/bookings');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<List<EventModel>> getAll() async {
    final response = await ApiClient.instance.get(
      '/api/events',
      options: ApiClient.publicOptions,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<EventModel> getById(int id) async {
    final response = await ApiClient.instance.get(
      '/api/events/$id',
      options: ApiClient.publicOptions,
    );
    return EventModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> bookEvent(int eventId) async {
    await ApiClient.instance.post(
      '/api/events/$eventId/book',
      data: {'ticketCount': 1},
    );
  }

  static Future<void> createEvent({
    required String title,
    String description = '',
    String location = '',
    String date = '',
    double price = 0,
  }) async {
    await ApiClient.instance.post(
      '/api/events',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'startDate': _toIsoDateTime(date),
        'price': price,
      },
    );
  }

  static Future<void> updateEvent(
    int id, {
    required String title,
    String description = '',
    String location = '',
    String date = '',
    double price = 0,
  }) async {
    await ApiClient.instance.put(
      '/api/events/$id',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'startDate': _toIsoDateTime(date),
        'price': price,
      },
    );
  }

  static Future<List<EventModel>> getBooked() async {
    final list = await getBookedRows();
    return list.map((row) {
      final item = row['item'] as Map<String, dynamic>;
      return EventModel.fromJson(item);
    }).toList();
  }

  static Future<List<EventModel>> getCreated() async {
    final response = await ApiClient.instance.get(
      '/api/users/listings/events',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> cancelBooking(int bookingId) =>
      ApiClient.instance.delete('/api/events/bookings/$bookingId');

  static Future<void> deleteEvent(int eventId) =>
      ApiClient.instance.delete('/api/events/$eventId');
}

String? _toIsoDateTime(String date) {
  final trimmed = date.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.contains('T') ? trimmed : '${trimmed}T00:00:00';
}
