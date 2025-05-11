import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Learning path status values
enum ModuleStatus {
  locked,
  inProgress,
  done,
}

/// Learning path model
class LearningPath {
  final String id;
  final String userId;
  String title;
  String? description;
  bool isActive;
  int progress;
  List<String> tags;
  String? category;
  String difficulty;
  final DateTime createdAt;
  DateTime updatedAt;
  List<LearningPathModule> modules;

  LearningPath({
    String? id,
    required this.userId,
    required this.title,
    this.description,
    this.isActive = false,
    this.progress = 0,
    this.tags = const [],
    this.category,
    this.difficulty = 'beginner',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.modules = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from JSON
  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      isActive: json['is_active'] ?? false,
      progress: json['progress'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      category: json['category'],
      difficulty: json['difficulty'] ?? 'beginner',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      modules: json['modules'] != null
          ? List<LearningPathModule>.from(
              json['modules'].map((x) => LearningPathModule.fromJson(x)))
          : [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_active': isActive,
      'progress': progress,
      'tags': tags,
      'category': category,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'modules': modules.map((x) => x.toJson()).toList(),
    };
  }

  /// Convert to database JSON (without modules)
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_active': isActive,
      'progress': progress,
      'tags': tags,
      'category': category,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  LearningPath copyWith({
    String? title,
    String? description,
    bool? isActive,
    int? progress,
    List<String>? tags,
    String? category,
    String? difficulty,
    List<LearningPathModule>? modules,
  }) {
    return LearningPath(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      progress: progress ?? this.progress,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      modules: modules ?? this.modules,
    );
  }

  @override
  String toString() {
    return 'LearningPath{id: $id, title: $title, isActive: $isActive, progress: $progress%, category: $category, difficulty: $difficulty, tags: $tags, moduleCount: ${modules.length}}';
  }
}

/// Learning path module
class LearningPathModule {
  final String id;
  final String pathId;
  String title;
  String description;
  String? prerequisites;
  List<String> dependencies;
  List<String> resources;
  List<String> learningObjectives;
  String? estimatedDuration;
  String? assessment;
  String? additionalNotes;
  String moduleId;
  ModuleStatus status;
  int position;
  DateTime createdAt;
  DateTime updatedAt;

  // Optional linked content
  String? noteId;
  String? quizId;
  String? deckId;

  LearningPathModule({
    String? id,
    required this.pathId,
    required this.title,
    required this.description,
    this.prerequisites,
    this.dependencies = const [],
    this.resources = const [],
    this.learningObjectives = const [],
    this.estimatedDuration,
    this.assessment,
    this.additionalNotes,
    required this.moduleId,
    this.status = ModuleStatus.locked,
    required this.position,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.noteId,
    this.quizId,
    this.deckId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from JSON
  factory LearningPathModule.fromJson(Map<String, dynamic> json) {
    return LearningPathModule(
      id: json['id'],
      pathId: json['path_id'],
      title: json['title'],
      description: json['description'] ?? '',
      prerequisites: json['prerequisites'],
      dependencies: json['dependencies'] != null
          ? List<String>.from(json['dependencies'])
          : [],
      resources:
          json['resources'] != null ? List<String>.from(json['resources']) : [],
      learningObjectives: json['learning_objectives'] != null
          ? List<String>.from(json['learning_objectives'])
          : [],
      estimatedDuration: json['estimated_duration'],
      assessment: json['assessment'],
      additionalNotes: json['additional_notes'],
      moduleId: json['module_id'] ?? '',
      status: _parseStatus(json['status'] ?? 'locked'),
      position: json['position'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      noteId: json['note_id'],
      quizId: json['quiz_id'],
      deckId: json['deck_id'],
    );
  }

  /// Parse status from string
  static ModuleStatus _parseStatus(String status) {
    switch (status) {
      case 'in-progress':
        return ModuleStatus.inProgress;
      case 'done':
        return ModuleStatus.done;
      case 'locked':
      default:
        return ModuleStatus.locked;
    }
  }

  /// Convert status to string
  static String statusToString(ModuleStatus status) {
    switch (status) {
      case ModuleStatus.inProgress:
        return 'in-progress';
      case ModuleStatus.done:
        return 'done';
      case ModuleStatus.locked:
      default:
        return 'locked';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path_id': pathId,
      'title': title,
      'description': description,
      'prerequisites': prerequisites,
      'dependencies': dependencies,
      'resources': resources,
      'learning_objectives': learningObjectives,
      'estimated_duration': estimatedDuration,
      'assessment': assessment,
      'additional_notes': additionalNotes,
      'module_id': moduleId,
      'status': statusToString(status),
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'note_id': noteId,
      'quiz_id': quizId,
      'deck_id': deckId,
    };
  }

  /// Convert to database JSON
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'path_id': pathId,
      'title': title,
      'description': description,
      'prerequisites': prerequisites,
      'dependencies': dependencies,
      'resources': resources,
      'learning_objectives': learningObjectives,
      'estimated_duration': estimatedDuration,
      'assessment': assessment,
      'additional_notes': additionalNotes,
      'module_id': moduleId,
      'status': statusToString(status),
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'note_id': noteId,
      'quiz_id': quizId,
      'deck_id': deckId,
    };
  }

  /// Copy with
  LearningPathModule copyWith({
    String? title,
    String? description,
    String? prerequisites,
    List<String>? dependencies,
    List<String>? resources,
    List<String>? learningObjectives,
    String? estimatedDuration,
    String? assessment,
    String? additionalNotes,
    ModuleStatus? status,
    int? position,
    String? noteId,
    String? quizId,
    String? deckId,
  }) {
    return LearningPathModule(
      id: id,
      pathId: pathId,
      title: title ?? this.title,
      description: description ?? this.description,
      prerequisites: prerequisites ?? this.prerequisites,
      dependencies: dependencies ?? this.dependencies,
      resources: resources ?? this.resources,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      assessment: assessment ?? this.assessment,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      moduleId: moduleId,
      status: status ?? this.status,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      noteId: noteId ?? this.noteId,
      quizId: quizId ?? this.quizId,
      deckId: deckId ?? this.deckId,
    );
  }

  @override
  String toString() {
    return 'LearningPathModule{id: $id, title: $title, status: ${statusToString(status)}, position: $position}';
  }
}
