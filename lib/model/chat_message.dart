class ChatMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
  });

  bool get isBot => type == MessageType.bot;

  bool get isUser => type == MessageType.user;
}

enum MessageType { bot, user }
