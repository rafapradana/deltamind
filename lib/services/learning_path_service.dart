import 'package:deltamind/models/learning_path.dart';
import 'package:deltamind/services/gemini_service.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;

/// Service for managing learning paths
class LearningPathService {
  /// Get all learning paths for the current user
  static Future<List<LearningPath>> getAllLearningPaths() async {
    try {
      SupabaseService.checkAuthentication();
      final userId = SupabaseService.currentUser!.id;

      final response = await SupabaseService.client
          .from('learning_paths')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<LearningPath> paths = (response as List)
          .map((json) => LearningPath.fromJson(json))
          .toList();

      // For each path, fetch its modules
      for (var path in paths) {
        final modules = await getPathModules(path.id);
        path.modules.addAll(modules);
      }

      return paths;
    } catch (e) {
      debugPrint('Error getting learning paths: $e');
      rethrow;
    }
  }

  /// Get a specific learning path by ID, including its modules
  static Future<LearningPath> getLearningPath(String pathId) async {
    try {
      SupabaseService.checkAuthentication();

      final response = await SupabaseService.client
          .from('learning_paths')
          .select()
          .eq('id', pathId)
          .single();

      final path = LearningPath.fromJson(response);

      // Fetch modules for this path
      final modules = await getPathModules(pathId);
      path.modules.addAll(modules);

      return path;
    } catch (e) {
      debugPrint('Error getting learning path: $e');
      rethrow;
    }
  }

  /// Get the active learning path for the current user
  static Future<LearningPath?> getActiveLearningPath() async {
    try {
      SupabaseService.checkAuthentication();
      final userId = SupabaseService.currentUser!.id;

      final response = await SupabaseService.client
          .from('learning_paths')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final path = LearningPath.fromJson(response);

      // Fetch modules for this path
      final modules = await getPathModules(path.id);
      path.modules.addAll(modules);

      return path;
    } catch (e) {
      debugPrint('Error getting active learning path: $e');
      rethrow;
    }
  }

  /// Get modules for a specific learning path
  static Future<List<LearningPathModule>> getPathModules(String pathId) async {
    try {
      final response = await SupabaseService.client
          .from('learning_path_modules')
          .select()
          .eq('path_id', pathId)
          .order('position', ascending: true);

      return (response as List)
          .map((json) => LearningPathModule.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting path modules: $e');
      return [];
    }
  }

  /// Create a new learning path
  static Future<LearningPath> createLearningPath(LearningPath path) async {
    try {
      SupabaseService.checkAuthentication();

      final response = await SupabaseService.client
          .from('learning_paths')
          .insert(path.toDatabaseJson())
          .select()
          .single();

      return LearningPath.fromJson(response);
    } catch (e) {
      debugPrint('Error creating learning path: $e');
      rethrow;
    }
  }

  /// Update an existing learning path
  static Future<LearningPath> updateLearningPath(LearningPath path) async {
    try {
      SupabaseService.checkAuthentication();

      final response = await SupabaseService.client
          .from('learning_paths')
          .update(path.toDatabaseJson())
          .eq('id', path.id)
          .select()
          .single();

      return LearningPath.fromJson(response);
    } catch (e) {
      debugPrint('Error updating learning path: $e');
      rethrow;
    }
  }

  /// Delete a learning path and all its modules
  static Future<void> deleteLearningPath(String pathId) async {
    try {
      SupabaseService.checkAuthentication();

      await SupabaseService.client
          .from('learning_paths')
          .delete()
          .eq('id', pathId);
    } catch (e) {
      debugPrint('Error deleting learning path: $e');
      rethrow;
    }
  }

  /// Set a learning path as active (and deactivate others)
  static Future<void> setActiveLearningPath(String pathId) async {
    try {
      SupabaseService.checkAuthentication();
      final userId = SupabaseService.currentUser!.id;

      await SupabaseService.client.rpc(
        'set_active_learning_path',
        params: {
          'path_uuid': pathId,
          'user_uuid': userId,
        },
      );
    } catch (e) {
      debugPrint('Error setting active learning path: $e');
      rethrow;
    }
  }

  /// Create or update a learning path module
  static Future<LearningPathModule> saveModule(
      LearningPathModule module) async {
    try {
      SupabaseService.checkAuthentication();

      final response = await SupabaseService.client
          .from('learning_path_modules')
          .upsert(module.toDatabaseJson())
          .select()
          .single();

      return LearningPathModule.fromJson(response);
    } catch (e) {
      debugPrint('Error saving module: $e');
      rethrow;
    }
  }

  /// Update a module's status
  static Future<LearningPathModule> updateModuleStatus(
    String moduleId,
    ModuleStatus status,
  ) async {
    try {
      SupabaseService.checkAuthentication();

      final response = await SupabaseService.client
          .from('learning_path_modules')
          .update({
            'status': LearningPathModule.statusToString(status),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', moduleId)
          .select()
          .single();

      return LearningPathModule.fromJson(response);
    } catch (e) {
      debugPrint('Error updating module status: $e');
      rethrow;
    }
  }

  /// Delete a module
  static Future<void> deleteModule(String moduleId) async {
    try {
      SupabaseService.checkAuthentication();

      await SupabaseService.client
          .from('learning_path_modules')
          .delete()
          .eq('id', moduleId);
    } catch (e) {
      debugPrint('Error deleting module: $e');
      rethrow;
    }
  }

  /// Generate a learning path using Gemini AI with user preferences
  static Future<Map<String, dynamic>> generateLearningPath({
    required String topic,
    String knowledgeLevel = 'beginner', // beginner, intermediate, advanced
    String? learningGoals,
    String? timeCommitment, // e.g. "2 hours daily for 3 weeks"
    String? learningStyle, // e.g. "visual", "practical", "theoretical"
    List<String>? focusAreas,
  }) async {
    try {
      SupabaseService.checkAuthentication();

      // Create the improved prompt for Gemini with user preferences
      final prompt = '''
Generate a comprehensive, visually structured learning path for the topic '$topic'. This will be displayed in a node-based graph visualization, with dependencies between modules shown as connecting lines.

USER PREFERENCES:
- Knowledge Level: ${knowledgeLevel.isNotEmpty ? knowledgeLevel : 'beginner'}
- Learning Goals: ${learningGoals?.isNotEmpty == true ? learningGoals : 'Comprehensive understanding of the topic'}
- Time Commitment: ${timeCommitment?.isNotEmpty == true ? timeCommitment : 'Flexible'}
- Learning Style: ${learningStyle?.isNotEmpty == true ? learningStyle : 'Balanced approach'}
- Focus Areas: ${focusAreas != null && focusAreas.isNotEmpty ? focusAreas.join(', ') : 'All aspects of the topic'}

Please create 5-8 modules that follow a logical progression from ${knowledgeLevel.isNotEmpty ? knowledgeLevel : 'beginner'} to advanced, with consideration for:

1. **Module Sequencing**: Ensure a clear progression from fundamentals to advanced concepts, tailored to the user's knowledge level. Each module should build on previous modules when appropriate.

2. **Visual Structure**: Create a balanced structure that flows well visually in a graph format. Consider both linear and branching progressions where appropriate.

3. **Dependencies**: Explicitly define which modules depend on other modules. This creates the connecting lines in the graph view.

4. **Learning Objectives**: Create clear, measurable learning objectives for each module that align with the user's specified learning goals.

5. **Resources**: Recommend highly specific, high-quality resources for each module. Include a mix of:
   - Video tutorials (from platforms like YouTube, Coursera, etc.)
   - Reading materials (articles, documentation, books)
   - Interactive exercises or projects
   - Communities or forums for support

6. **Time Estimates**: Provide realistic time estimates for each module based on the user's time commitment.

7. **Assessment**: Include practical assessment suggestions to verify understanding before proceeding to dependent modules.

Format your response as a JSON object with the following structure:
```json
{
  "title": "Learning Path: [Topic Name]",
  "description": "A comprehensive learning path for [topic], designed for [knowledge level] learners focused on [learning goals].",
  "modules": [
    {
      "module_id": "1",
      "title": "Module Title",
      "description": "Detailed module description",
      "prerequisites": "Any prerequisites for this module",
      "dependencies": ["list of module_ids this depends on"],
      "resources": ["Specific, high-quality resource 1", "Resource 2", "..."],
      "learning_objectives": ["Objective 1", "Objective 2", "..."],
      "estimated_duration": "Realistic time estimate",
      "assessment": "Specific assessment activity",
      "additional_notes": "Any additional guidance"
    },
    // Additional modules...
  ]
}
```

Your response MUST be valid JSON that can be parsed directly. Do not include any explanatory text before or after the JSON.
''';

      // Send to Gemini
      final response = await GeminiService.model.generateContent([
        ai.Content.text(prompt),
      ]);

      final generatedText = response.text;

      if (generatedText == null || generatedText.isEmpty) {
        throw Exception('Failed to generate learning path');
      }

      // Process the response to extract JSON
      String processedResult = generatedText;

      // Check if the response is wrapped in markdown code blocks
      if (generatedText.contains('```json')) {
        // Extract content between ```json and ``` markers
        final startMarker = '```json';
        final endMarker = '```';
        final startIndex =
            generatedText.indexOf(startMarker) + startMarker.length;
        final endIndex = generatedText.lastIndexOf(endMarker);

        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult =
              generatedText.substring(startIndex, endIndex).trim();
        }
      } else if (generatedText.contains('```')) {
        // Handle case where code block doesn't specify language
        final startMarker = '```';
        final endMarker = '```';
        final startIndex =
            generatedText.indexOf(startMarker) + startMarker.length;
        final endIndex = generatedText.lastIndexOf(endMarker);

        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult =
              generatedText.substring(startIndex, endIndex).trim();
        }
      }

      // Try to parse the JSON
      try {
        final result = jsonDecode(processedResult);
        return result;
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        // If we can't parse it, attempt to extract JSON
        final firstBrace = generatedText.indexOf('{');
        final lastBrace = generatedText.lastIndexOf('}');

        if (firstBrace >= 0 && lastBrace >= 0 && firstBrace < lastBrace) {
          processedResult = generatedText.substring(firstBrace, lastBrace + 1);

          try {
            return jsonDecode(processedResult);
          } catch (jsonError) {
            debugPrint('Second JSON parsing attempt failed: $jsonError');

            // Fallback: Generate a basic learning path structure as a last resort
            final fallbackPath = _createFallbackPath(
              topic: topic,
              knowledgeLevel: knowledgeLevel,
              learningGoals: learningGoals,
              timeCommitment: timeCommitment,
              learningStyle: learningStyle,
              focusAreas: focusAreas,
            );
            return fallbackPath;
          }
        } else {
          // If we can't extract JSON either, return a fallback
          debugPrint('Could not extract JSON structure, using fallback path');
          return _createFallbackPath(
            topic: topic,
            knowledgeLevel: knowledgeLevel,
            learningGoals: learningGoals,
            timeCommitment: timeCommitment,
            learningStyle: learningStyle,
            focusAreas: focusAreas,
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating learning path: $e');
      // Check for service unavailability (503) error
      if (e.toString().contains('503') ||
          e.toString().contains('UNAVAILABLE')) {
        throw Exception(
            'Gemini AI service is currently unavailable. Please try again later.');
      }
      // Return a fallback path with user preferences
      return _createFallbackPath(
        topic: topic,
        knowledgeLevel: knowledgeLevel,
        learningGoals: learningGoals,
        timeCommitment: timeCommitment,
        learningStyle: learningStyle,
        focusAreas: focusAreas,
      );
    }
  }

  /// Create a fallback learning path when AI generation fails
  static Map<String, dynamic> _createFallbackPath({
    required String topic,
    String knowledgeLevel = 'beginner',
    String? learningGoals,
    String? timeCommitment,
    String? learningStyle,
    List<String>? focusAreas,
  }) {
    final capitalizedTopic = topic[0].toUpperCase() + topic.substring(1);
    final String levelLabel =
        knowledgeLevel[0].toUpperCase() + knowledgeLevel.substring(1);

    // Default time estimates based on knowledge level
    final Map<String, String> defaultDurations = {
      'beginner': '1-2 weeks',
      'intermediate': '2-3 weeks',
      'advanced': '3-4 weeks',
    };

    // Handle focus areas if provided
    final focusAreasText = focusAreas != null && focusAreas.isNotEmpty
        ? ' with a focus on ${focusAreas.join(', ')}'
        : '';

    final String pathDescription =
        'A comprehensive learning path for $topic designed for $knowledgeLevel learners'
        '${learningGoals != null ? ' to $learningGoals' : ''}'
        '$focusAreasText.';

    return {
      "title": "Learning Path: $capitalizedTopic",
      "description": pathDescription,
      "is_fallback": true,
      "modules": [
        {
          "module_id": "1",
          "title": "$levelLabel Introduction to $capitalizedTopic",
          "description": "Learn the fundamentals and core concepts of $topic.",
          "prerequisites": knowledgeLevel == 'beginner'
              ? "No prior knowledge required"
              : "Basic understanding of the subject area",
          "dependencies": [],
          "resources": [
            "Search for '$topic fundamentals' on YouTube",
            "Look for beginner guides on $topic online",
            "Join online communities focused on $topic for support"
          ],
          "learning_objectives": [
            "Understand basic terminology related to $topic",
            "Identify the key components and concepts of $topic",
            "Build a foundation for more advanced learning"
          ],
          "estimated_duration": knowledgeLevel == 'beginner'
              ? (timeCommitment != null
                  ? "Approximately ${timeCommitment.contains('hour') ? '1-2 weeks' : '1 week'}"
                  : defaultDurations[knowledgeLevel])
              : "1 week",
          "assessment": "Create a concept map of $topic fundamentals",
          "additional_notes": "Created as fallback due to AI generation error"
        },
        {
          "module_id": "2",
          "title": "Core $capitalizedTopic Skills",
          "description":
              "Develop the essential skills needed for $topic mastery.",
          "prerequisites": "$levelLabel understanding of $topic",
          "dependencies": ["1"],
          "resources": [
            "Practice exercises for $topic skills",
            "Intermediate tutorials on $topic",
            learningStyle == 'visual'
                ? "Video courses on $topic"
                : learningStyle == 'practical'
                    ? "Hands-on projects for $topic"
                    : learningStyle == 'theoretical'
                        ? "Academic papers on $topic fundamentals"
                        : "Mixed media resources on $topic"
          ],
          "learning_objectives": [
            "Apply basic $topic techniques to simple problems",
            "Develop proficiency in core $topic methods",
            "Create simple solutions using $topic approaches"
          ],
          "estimated_duration": knowledgeLevel == 'beginner'
              ? (timeCommitment != null
                  ? "Approximately ${timeCommitment.contains('hour') ? '2-3 weeks' : '2 weeks'}"
                  : defaultDurations[knowledgeLevel])
              : "2 weeks",
          "assessment": "Complete practice exercises",
          "additional_notes": "Focus on practical application"
        },
        {
          "module_id": "3",
          "title": "Advanced $capitalizedTopic",
          "description":
              "Explore advanced topics and specialized areas within $topic.",
          "prerequisites": "Core skills in $topic",
          "dependencies": ["2"],
          "resources": [
            "Advanced online courses on $topic",
            "Research papers and articles on $topic",
            focusAreas != null && focusAreas.isNotEmpty
                ? "Specialized resources on ${focusAreas.join(' and ')}"
                : "Deep dive materials on $topic specializations"
          ],
          "learning_objectives": [
            "Apply advanced techniques to complex problems",
            "Analyze and evaluate $topic approaches",
            "Design comprehensive solutions using $topic"
          ],
          "estimated_duration": knowledgeLevel == 'advanced'
              ? (timeCommitment != null
                  ? "Approximately ${timeCommitment.contains('hour') ? '2-3 weeks' : '2 weeks'}"
                  : defaultDurations[knowledgeLevel])
              : "3 weeks",
          "assessment": "Create a capstone project",
          "additional_notes":
              "Customize this module based on your specific interests in $topic"
        }
      ]
    };
  }

  /// Create a learning path from Gemini-generated data
  static Future<LearningPath> createFromGeneratedPath(
    Map<String, dynamic> generatedPath,
  ) async {
    try {
      SupabaseService.checkAuthentication();
      final userId = SupabaseService.currentUser!.id;

      // Create the learning path
      final LearningPath path = LearningPath(
        userId: userId,
        title: generatedPath['title'] ?? 'Learning Path',
        description: generatedPath['description'] ?? '',
      );

      // Save the path first
      final createdPath = await createLearningPath(path);

      // Create modules
      if (generatedPath['modules'] != null &&
          generatedPath['modules'] is List) {
        final List<dynamic> modules = generatedPath['modules'];

        for (int i = 0; i < modules.length; i++) {
          final module = modules[i];

          // Create module
          final LearningPathModule pathModule = LearningPathModule(
            pathId: createdPath.id,
            title: module['title'] ?? 'Module ${i + 1}',
            description: module['description'] ?? '',
            prerequisites: module['prerequisites'] ?? '',
            dependencies:
                module['dependencies'] != null && module['dependencies'] is List
                    ? List<String>.from(module['dependencies'])
                    : [],
            resources:
                module['resources'] != null && module['resources'] is List
                    ? List<String>.from(module['resources'])
                    : [],
            learningObjectives: module['learning_objectives'] != null &&
                    module['learning_objectives'] is List
                ? List<String>.from(module['learning_objectives'])
                : [],
            estimatedDuration: module['estimated_duration'] ?? '',
            assessment: module['assessment'] ?? '',
            additionalNotes: module['additional_notes'] ?? '',
            moduleId: module['module_id']?.toString() ?? (i + 1).toString(),
            position: i,
            status: i == 0 ? ModuleStatus.inProgress : ModuleStatus.locked,
          );

          // Save module
          await saveModule(pathModule);
        }
      }

      // Fetch the complete path with modules
      return await getLearningPath(createdPath.id);
    } catch (e) {
      debugPrint('Error creating path from generated data: $e');
      rethrow;
    }
  }
}
