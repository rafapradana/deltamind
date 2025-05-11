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

      // Create the improved prompt for Gemini with user preferences and enhanced content guidelines
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

4. **Detailed Module Descriptions**: For each module, provide:
   - A concise yet comprehensive description (2-3 sentences minimum)
   - Clear explanation of why this module is important to master
   - Real-world applications or contexts where this knowledge is used
   - Any key concepts or terminology that will be introduced

5. **Specific Learning Objectives**: Create clear, measurable learning objectives for each module using action verbs (explain, implement, analyze, evaluate, etc.). Make them specific enough to guide self-assessment.

6. **Highly Specific Resources**: For each module, recommend:
   - Specific courses with platform names and course titles (e.g., "Machine Learning by Andrew Ng on Coursera")
   - Specific articles with publication names (e.g., "Understanding Neural Networks on Medium by [author]")
   - Books with author names (e.g., "Deep Learning by Ian Goodfellow")
   - Specific GitHub repositories or code examples with links where applicable
   - YouTube channels or specific videos with creator names
   - Interactive tools or platforms for practice

7. **Detailed Prerequisites**: Clearly state what knowledge is required before starting each module.

8. **Practical Assessment Activities**: For each module, include:
   - A hands-on project idea related to the module content
   - Specific evaluation criteria to determine mastery
   - An estimate of how long the assessment should take

9. **Time Estimates**: Provide detailed time estimates for each module that:
   - Break down time needed for theory vs. practice
   - Account for the user's stated time commitment
   - Include time estimates for completing recommended resources

10. **Additional Notes**: Include important tips, common pitfalls to avoid, or alternative learning approaches based on the user's learning style.

Format your response as a JSON object with the following structure:
```json
{
  "title": "Learning Path: [Topic Name]",
  "description": "A comprehensive learning path for [topic], designed for [knowledge level] learners focused on [learning goals].",
  "modules": [
    {
      "module_id": "1",
      "title": "Module Title",
      "description": "Detailed module description covering why this module matters, what it builds toward, and how it applies in real-world contexts.",
      "prerequisites": "Specific prerequisites required for this module",
      "dependencies": ["list of module_ids this depends on"],
      "resources": [
        "Specific course: [Course Name] by [Instructor] on [Platform]", 
        "Book: [Title] by [Author]",
        "Video: [Title] by [Creator] on YouTube",
        "Tool: [Name] for interactive practice"
      ],
      "learning_objectives": ["Specific objective 1 using action verbs", "Objective 2", "..."],
      "estimated_duration": "Detailed time breakdown (e.g., 10 hours: 4h theory, 6h practice)",
      "assessment": "Detailed project idea with evaluation criteria",
      "additional_notes": "Tips, common pitfalls, and learning approach suggestions"
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

    // Determine appropriate resources based on learning style
    final List<String> resourcesByStyle = _getResourcesByLearningStyle(
        topic: topic, learningStyle: learningStyle ?? 'balanced');

    // Create more specific assessment activities
    final String assessmentActivity = _getAssessmentByLevel(
      topic: topic,
      knowledgeLevel: knowledgeLevel,
    );

    return {
      "title": "Learning Path: $capitalizedTopic",
      "description": pathDescription,
      "is_fallback": true,
      "modules": [
        {
          "module_id": "1",
          "title": "$levelLabel Introduction to $capitalizedTopic",
          "description":
              "This foundational module provides a comprehensive introduction to $topic, covering core concepts and terminology. Understanding these fundamentals is essential as they form the building blocks for all further learning in this subject. This knowledge will enable you to communicate effectively about $topic and recognize its applications in real-world scenarios.",
          "prerequisites": knowledgeLevel == 'beginner'
              ? "No prior knowledge required"
              : "Basic understanding of the subject area",
          "dependencies": [],
          "resources": [
            ...resourcesByStyle.take(3),
            "Interactive exercises: Practice basic $topic concepts through hands-on activities on reputable learning platforms",
            "Community: Join online forums like Reddit r/${topic.replaceAll(' ', '')}, Discord groups, or Stack Overflow to connect with others learning $topic"
          ],
          "learning_objectives": [
            "Define and explain key terminology and concepts in $topic",
            "Identify the main components and principles of $topic systems",
            "Recognize how $topic is applied in various real-world contexts",
            "Build a solid conceptual foundation for more advanced $topic learning"
          ],
          "estimated_duration": knowledgeLevel == 'beginner'
              ? (timeCommitment != null
                  ? "2 weeks (8-10 hours total: 4h theory, 6h practice)"
                  : "1-2 weeks (10-12 hours total: 5h theory, 7h practice)")
              : "1 week (6-8 hours total: 3h theory, 5h practice)",
          "assessment": assessmentActivity,
          "additional_notes":
              "Focus on understanding the 'why' behind concepts rather than just memorizing information. Creating your own notes and diagrams will significantly improve retention. If you find certain concepts challenging, don't hesitate to explore multiple explanations from different resources."
        },
        {
          "module_id": "2",
          "title": "Core $capitalizedTopic Skills",
          "description":
              "This module builds on the foundational knowledge to develop essential practical skills in $topic. These core skills represent the most commonly used techniques and approaches in real-world applications. Mastering these skills will allow you to solve standard problems in the field and prepare you for more specialized applications in later modules.",
          "prerequisites": "$levelLabel understanding of $topic fundamentals",
          "dependencies": ["1"],
          "resources": [
            ...resourcesByStyle.skip(1).take(3),
            "Documentation: Official guides and documentation for $topic platforms and tools",
            "Practice Projects: Complete guided projects that implement core $topic techniques",
            "Video Series: Comprehensive tutorials walking through practical $topic implementations"
          ],
          "learning_objectives": [
            "Apply fundamental $topic techniques to solve common problems",
            "Implement basic $topic solutions with proper structure and organization",
            "Analyze and debug issues in simple $topic implementations",
            "Combine multiple $topic concepts to build functional applications"
          ],
          "estimated_duration": knowledgeLevel == 'beginner'
              ? (timeCommitment != null
                  ? "3 weeks (15-18 hours total: 6h theory, 12h practice)"
                  : "2-3 weeks (18-20 hours total: 8h theory, 12h practice)")
              : "2 weeks (12-15 hours total: 5h theory, 10h practice)",
          "assessment":
              "Develop a small but complete project implementing the core concepts of $topic. Your implementation should demonstrate proper use of standard techniques, include appropriate error handling, and follow established best practices. Have peers or mentors review your code and provide feedback.",
          "additional_notes":
              "${learningStyle == 'visual' ? 'Consider creating diagrams or flowcharts to visualize how different components of your project interact.' : learningStyle == 'practical' ? 'Spend extra time on hands-on exercises, focusing on writing code and solving problems.' : learningStyle == 'theoretical' ? 'Make sure to understand the underlying principles and mathematics behind the techniques.' : 'Balance theoretical understanding with practical implementation for the best results.'} Keep track of challenges you encounter to revisit later."
        },
        {
          "module_id": "3",
          "title": "Advanced $capitalizedTopic Concepts",
          "description":
              "This advanced module explores sophisticated techniques and specialized areas within $topic. These concepts represent the cutting edge of the field and will enable you to tackle complex, non-standard problems. Understanding these advanced topics will differentiate you as a $topic specialist and allow you to contribute to innovative solutions in the field.",
          "prerequisites": "Solid grasp of core $topic skills and techniques",
          "dependencies": ["2"],
          "resources": [
            "Academic Papers: Recent research publications on advanced $topic techniques",
            "Advanced Courses: Specialized courses focusing on cutting-edge $topic approaches",
            "Expert Blogs: In-depth articles from leading practitioners in the $topic field",
            "GitHub Repositories: Study code from advanced open-source $topic projects",
            focusAreas != null && focusAreas.isNotEmpty
                ? "Specialized Resources: Materials focusing specifically on ${focusAreas.join(' and ')}"
                : "Industry Case Studies: Real-world examples of advanced $topic implementations"
          ],
          "learning_objectives": [
            "Implement advanced $topic techniques to solve complex problems",
            "Evaluate and select appropriate approaches for different $topic scenarios",
            "Design comprehensive, scalable solutions using $topic principles",
            "Critically analyze existing $topic implementations and suggest improvements"
          ],
          "estimated_duration": knowledgeLevel == 'advanced'
              ? (timeCommitment != null
                  ? "3 weeks (18-20 hours total: 7h theory, 13h practice)"
                  : "3-4 weeks (20-25 hours total: 8h theory, 17h practice)")
              : "4 weeks (25-30 hours total: 10h theory, 20h practice)",
          "assessment":
              "Design and implement a comprehensive project that addresses a real-world problem using advanced $topic techniques. Your solution should demonstrate mastery of complex concepts, efficient implementation, and should include documentation explaining your approach and design decisions. Present your project to peers for feedback.",
          "additional_notes":
              "At this advanced stage, consider contributing to open-source projects related to $topic or publishing your own findings and implementations. Joining professional communities and participating in discussions will further enhance your expertise. Stay updated with the latest developments in the field through research papers and conference proceedings."
        }
      ]
    };
  }

  /// Get curated resources based on learning style
  static List<String> _getResourcesByLearningStyle({
    required String topic,
    required String learningStyle,
  }) {
    final capitalizedTopic = topic[0].toUpperCase() + topic.substring(1);

    switch (learningStyle.toLowerCase()) {
      case 'visual':
        return [
          "Video Course: Comprehensive visual guide to $topic on Coursera or Udemy",
          "YouTube Channel: Illustrated tutorials on $topic fundamentals by established educators",
          "Infographics: Visual summaries of key $topic concepts on websites like Visual.ly",
          "Interactive Diagrams: Explore $topic through interactive visualizations on platforms like Observable",
          "Animated Tutorials: Step-by-step animated explanations of $topic processes"
        ];

      case 'practical':
        return [
          "Hands-on Workshop: Interactive $topic workshops on platforms like Codecademy or DataCamp",
          "Project-based Course: Build practical $topic projects on platforms like Pluralsight",
          "GitHub Repository: Annotated example projects implementing $topic concepts",
          "Interactive Tutorials: Step-by-step exercises on $topic with immediate feedback",
          "Coding Challenges: Progressive $topic challenges on platforms like HackerRank or LeetCode"
        ];

      case 'theoretical':
        return [
          "Textbook: '$capitalizedTopic Fundamentals' by respected authors in the field",
          "Academic Course: University-level lectures on $topic theory from MIT OCW or Stanford Online",
          "Research Papers: Foundational papers explaining core $topic principles",
          "In-depth Articles: Theoretical explanations of $topic concepts on platforms like Medium or arXiv",
          "Mathematics: Exploring the mathematical foundations of $topic on Khan Academy"
        ];

      case 'interactive':
        return [
          "Interactive Platform: Hands-on learning through platforms like Codecademy or freeCodeCamp",
          "Tutorial Projects: Guided interactive projects building $topic applications",
          "Simulation Tools: Interactive simulators demonstrating $topic principles",
          "Live Workshops: Participate in online workshops focused on $topic implementation",
          "Community Challenges: Engage with $topic problems in community platforms"
        ];

      case 'balanced':
      default:
        return [
          "Comprehensive Course: Well-rounded $topic course on platforms like Coursera or edX",
          "Book: '$capitalizedTopic - A Practical Approach' with both theory and implementation",
          "YouTube Series: Balanced tutorials covering theory and practice of $topic",
          "Tutorial Website: Step-by-step guides with explanations and exercises on $topic",
          "Documentation: Official guides and resources for $topic frameworks and tools"
        ];
    }
  }

  /// Get appropriate assessment activity based on knowledge level
  static String _getAssessmentByLevel({
    required String topic,
    required String knowledgeLevel,
  }) {
    switch (knowledgeLevel.toLowerCase()) {
      case 'beginner':
        return "Create a concept map of $topic fundamentals and explain the relationships between key concepts. Then implement a simple project that demonstrates basic principles. Document your learning process and the challenges you encountered.";

      case 'intermediate':
        return "Develop a medium-sized project that incorporates multiple aspects of $topic. Include proper documentation, testing, and follow best practices. Present your implementation choices and explain how you solved specific challenges in the project.";

      case 'advanced':
        return "Design and implement a complex $topic solution that addresses a real-world problem. Your implementation should demonstrate advanced techniques, optimization considerations, and thorough documentation. Include a detailed analysis of your approach compared to alternatives and a reflection on potential improvements.";

      default:
        return "Create a comprehensive project applying $topic concepts and principles. Document your process, justify your design decisions, and reflect on what you've learned. Share your project with peers for feedback and suggestions for improvement.";
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
