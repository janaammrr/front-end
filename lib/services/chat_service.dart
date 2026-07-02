import 'api_client.dart';

class ChatUser {
  final int id;
  final String firstname;
  final String lastname;
  final String? profileUrl;

  ChatUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.profileUrl,
  });

  String get displayName => '$firstname $lastname'.trim();
  String get initials {
    final f = firstname.isNotEmpty ? firstname[0] : '';
    final l = lastname.isNotEmpty ? lastname[0] : '';
    return (f + l).toUpperCase();
  }

  factory ChatUser.fromJson(Map<String, dynamic> j) => ChatUser(
    id: (j['id'] as num).toInt(),
    firstname: j['firstname'] as String? ?? j['firstName'] as String? ?? '',
    lastname: j['lastname'] as String? ?? j['lastName'] as String? ?? '',
    profileUrl: j['profileUrl'] as String?,
  );
}

class InboxItem {
  final ChatUser otherUser;
  final String lastMessage;
  final bool isRead;
  final int unreadCount;

  InboxItem({
    required this.otherUser,
    required this.lastMessage,
    required this.isRead,
    required this.unreadCount,
  });

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
    otherUser: ChatUser.fromJson(j['otherUser'] as Map<String, dynamic>),
    lastMessage: j['lastMessage'] as String? ?? '',
    isRead: j['isRead'] as bool? ?? true,
    unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
  );
}

class ChatMessage {
  final int id;
  final String content;
  final bool isMine;
  final String sentAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isMine,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j, int myUserId) {
    final sender = ChatUser.fromJson(j['sender'] as Map<String, dynamic>);
    return ChatMessage(
      id: (j['id'] as num).toInt(),
      content: j['content'] as String? ?? '',
      isMine: sender.id == myUserId,
      sentAt: _formatTime(j['sentAt'] as String?),
    );
  }

  static String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return raw;
    }
  }
}

class ChatService {
  static Future<List<InboxItem>> getInbox() async {
    final res = await ApiClient.instance.get('/api/chat/inbox');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => InboxItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ChatMessage>> getConversation(
    int otherUserId,
    int myUserId,
  ) async {
    final res = await ApiClient.instance.get('/api/chat/$otherUserId');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, myUserId))
        .toList();
  }

  static Future<ChatMessage> sendMessage(
    int receiverId,
    String content,
    int myUserId,
  ) async {
    final res = await ApiClient.instance.post(
      '/api/chat/send',
      data: {'receiverId': receiverId, 'content': content},
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>, myUserId);
  }
}
