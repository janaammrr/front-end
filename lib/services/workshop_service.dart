import '../models/workshop_model.dart';
import 'api_client.dart';

class WorkshopService {
  static Future<List<Map<String, dynamic>>> getBookedRows() async {
    final response = await ApiClient.instance.get('/api/workshops/bookings');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<List<WorkshopModel>> getAll() async {
    final response = await ApiClient.instance.get(
      '/api/workshops',
      options: ApiClient.publicOptions,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => WorkshopModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<WorkshopModel> getById(int id) async {
    final response = await ApiClient.instance.get(
      '/api/workshops/$id',
      options: ApiClient.publicOptions,
    );
    return WorkshopModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> bookWorkshop(int workshopId) async {
    await ApiClient.instance.post(
      '/api/workshops/$workshopId/book',
      data: {'ticketCount': 1},
    );
  }

  static Future<void> createWorkshop({
    required String title,
    String description = '',
    String location = '',
    int capacity = 0,
    String date = '',
    double price = 0,
  }) async {
    await ApiClient.instance.post(
      '/api/workshops',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'capacity': capacity > 0 ? capacity : null,
        'startDate': _toIsoDateTime(date),
        'price': price,
      },
    );
  }

  static Future<void> updateWorkshop(
    int id, {
    required String title,
    String description = '',
    String location = '',
    int capacity = 0,
    String date = '',
    double price = 0,
  }) async {
    await ApiClient.instance.put(
      '/api/workshops/$id',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'capacity': capacity > 0 ? capacity : null,
        'startDate': _toIsoDateTime(date),
        'price': price,
      },
    );
  }

  static Future<List<WorkshopModel>> getBooked() async {
    final list = await getBookedRows();
    return list.map((row) {
      final item = row['item'] as Map<String, dynamic>;
      return WorkshopModel.fromJson(item);
    }).toList();
  }

  static Future<List<WorkshopModel>> getCreated() async {
    final response = await ApiClient.instance.get(
      '/api/users/listings/workshops',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => WorkshopModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> cancelBooking(int bookingId) =>
      ApiClient.instance.delete('/api/workshops/bookings/$bookingId');

  static Future<void> deleteWorkshop(int workshopId) =>
      ApiClient.instance.delete('/api/workshops/$workshopId');
}

String? _toIsoDateTime(String date) {
  final trimmed = date.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.contains('T') ? trimmed : '${trimmed}T00:00:00';
}
