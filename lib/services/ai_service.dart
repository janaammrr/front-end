import 'api_client.dart';

class AiMessage {
  final String role;
  final String content;
  const AiMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role.toLowerCase(), 'text': content};
}

class AiService {
  static Future<String> chat(
    String message, {
    List<AiMessage> context = const [],
  }) async {
    final response = await ApiClient.instance.post(
      '/api/assistant/chat',
      data: {
        'message': message,
        'history': context.map((m) => m.toJson()).toList(),
      },
    );
    return response.data['reply'] as String;
  }
}
