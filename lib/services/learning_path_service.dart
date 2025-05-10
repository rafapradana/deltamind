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

  /// Generate a learning path using Gemini AI
  static Future<Map<String, dynamic>> generateLearningPath(
    String topic,
  ) async {
    try {
      SupabaseService.checkAuthentication();

      // Create the prompt for Gemini
      final prompt = '''
Generate a comprehensive learning path for the topic '$topic'. The learning path should contain 5–10 modules, each with the following information:

1. **Module Title**: A concise title describing the module.
2. **Module Description**: A detailed description of the module's content, objectives, and the skills or knowledge the learner will gain.
3. **Prerequisites**: List of any prior knowledge or skills required for this module (optional but recommended).
4. **Dependencies**: For each module, specify any modules that need to be completed first (e.g., a module might depend on completion of 'Module 1' before proceeding).
5. **Learning Resources**: Provide recommendations for resources like articles, books, videos, or tools relevant to the module's content. Include URLs if applicable.
6. **Learning Objectives**: Clear, measurable goals that learners should achieve upon completion of the module. For example, "Understand the basics of X" or "Be able to implement Y using Z."
7. **Estimated Duration**: Estimate how long it might take to complete the module (e.g., '2 hours', '1 day').
8. **Assessment/Checkpoint**: Describe the type of assessment or checkpoint that should be included at the end of the module (e.g., quiz, project, or practical exercise).
9. **Additional Notes**: Any extra information that may be relevant, such as advanced tips, challenges, or optional deep dives into specific subtopics.

**Output Format:**

Return the response as a structured JSON with the following structure:

{
  "title": "[Learning Path Title]",
  "description": "[Learning Path Brief Description]",
  "modules": [
    {
      "module_id": "1",
      "title": "[Module 1 Title]",
      "description": "[Module 1 Description]",
      "prerequisites": "[Any prerequisites]",
      "dependencies": "[Module(s) that must be completed first]",
      "resources": [
        "[Resource 1 URL]",
        "[Resource 2 URL]"
      ],
      "learning_objectives": [
        "[Objective 1]",
        "[Objective 2]"
      ],
      "estimated_duration": "[Estimated Duration]",
      "assessment": "[Type of Assessment]",
      "additional_notes": "[Any extra notes]"
    },
    {
      "module_id": "2",
      "title": "[Module 2 Title]",
      "description": "[Module 2 Description]",
      "prerequisites": "[Any prerequisites]",
      "dependencies": "[Module(s) that must be completed first]",
      "resources": [
        "[Resource 1 URL]",
        "[Resource 2 URL]"
      ],
      "learning_objectives": [
        "[Objective 1]",
        "[Objective 2]"
      ],
      "estimated_duration": "[Estimated Duration]",
      "assessment": "[Type of Assessment]",
      "additional_notes": "[Any extra notes]"
    }
  ]
}
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
        // If we can't parse it, attempt to extract JSON
        final firstBrace = generatedText.indexOf('{');
        final lastBrace = generatedText.lastIndexOf('}');

        if (firstBrace >= 0 && lastBrace >= 0 && firstBrace < lastBrace) {
          processedResult = generatedText.substring(firstBrace, lastBrace + 1);

          try {
            return jsonDecode(processedResult);
          } catch (e) {
            throw Exception('Failed to parse AI response: $e');
          }
        } else {
          throw Exception('Failed to extract valid JSON from response');
        }
      }
    } catch (e) {
      debugPrint('Error generating learning path: $e');
      rethrow;
    }
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
