class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.productIds = const [],
    this.suggestedQuestions = const [],
  });

  final String role;
  final String content;
  final DateTime? timestamp;
  final List<String> productIds;
  final List<String> suggestedQuestions;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] ?? 'assistant',
        content: json['content'] ?? json['answer'] ?? json['message'] ?? '',
        timestamp: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        productIds:
            (json['productIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        suggestedQuestions: (json['suggestedQuestions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
