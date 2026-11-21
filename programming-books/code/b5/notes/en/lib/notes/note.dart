// One note: plain data, with copyWith to change it without changing the original.
class Note {
  const Note({
    required this.id,
    required this.title,
    this.body = '',
    this.pinned = false,
    required this.edited,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    pinned: json['pinned'] as bool,
    edited: DateTime.parse(json['edited'] as String),
  );

  final String id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime edited;

  Note copyWith({
    String? title,
    String? body,
    bool? pinned,
    DateTime? edited,
  }) => Note(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    pinned: pinned ?? this.pinned,
    edited: edited ?? this.edited,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'pinned': pinned,
    'edited': edited.toIso8601String(),
  };
}
