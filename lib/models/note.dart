import 'package:uuid/uuid.dart';

/// Model for a note
class Note {
  /// Note ID
  final String id;

  /// Title of the note
  final String title;

  /// Content of the note
  final String? content;

  /// Tags for the note
  final List<String> tags;

  /// User ID that created the note
  final String userId;

  /// Created at timestamp
  final DateTime createdAt;

  /// Updated at timestamp
  final DateTime? updatedAt;

  /// Color of the note (hex code)
  final String? color;

  /// Whether the note is pinned
  final bool isPinned;

  /// Note Constructor
  const Note({
    required this.id,
    required this.title,
    this.content,
    required this.tags,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.color,
    this.isPinned = false,
  });

  /// Create a new note
  factory Note.create({
    required String title,
    String? content,
    List<String>? tags,
    required String userId,
    String? color,
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    return Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      tags: tags ?? [],
      userId: userId,
      createdAt: now,
      updatedAt: now,
      color: color,
      isPinned: isPinned,
    );
  }

  /// Create a note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      color: json['color'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  /// Convert note to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'color': color,
      'is_pinned': isPinned,
    };
  }

  /// Create a copy of this note with the given values
  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
