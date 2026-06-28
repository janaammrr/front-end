import '../models/workshop_model.dart';
import 'api_client.dart';

class WorkshopService {
  static Future<List<WorkshopModel>> getAll() async {
    final response = await ApiClient.instance.get('/api/workshops');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => WorkshopModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<WorkshopModel> getById(int id) async {
    final response = await ApiClient.instance.get('/api/workshops/$id');
    return WorkshopModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> bookWorkshop(int workshopId) async {
    await ApiClient.instance.post(
      '/api/customer/workshops/$workshopId/book',
      data: {'ticketCount': 1},
    );
  }

  static Future<void> createWorkshop({
    required String title,
    String description = '',
    String location = '',
    int capacity = 0,
  }) async {
    await ApiClient.instance.post('/api/provider/workshops', data: {
      'title': title,
      'description': description,
      'location': location,
      'capacity': capacity,
    });
  }

  static Future<List<WorkshopModel>> getBooked() async {
    final response = await ApiClient.instance.get('/api/customer/workshops/booked');
    final list = response.data as List<dynamic>;
    return list.map((row) {
      final item = (row as Map<String, dynamic>)['item'] as Map<String, dynamic>;
      return WorkshopModel.fromJson(item);
    }).toList();
  }

  static Future<List<WorkshopModel>> getCreated() async {
    final response = await ApiClient.instance.get('/api/provider/workshops');
    final list = response.data as List<dynamic>;
    return list.map((json) => WorkshopModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
