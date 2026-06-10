class Paste {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  Paste({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Paste.fromJson(Map<String, dynamic> json) {
    return Paste(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Paste copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
  }) {
    return Paste(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
