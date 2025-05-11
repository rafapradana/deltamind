import 'package:deltamind/services/learning_path_service.dart';

/// A simple test function to verify that our enhanced AI Learning Path Generator
/// works correctly with Supabase integration
void main() async {
  try {
    print('Testing Enhanced AI Learning Path Generator...');

    // Test with detailed user preferences
    final generatedPath = await LearningPathService.generateLearningPath(
      topic: 'Flutter Development',
      knowledgeLevel: 'intermediate',
      learningGoals: 'Build production-ready mobile applications',
      timeCommitment: '2 hours daily for 4 weeks',
      learningStyle: 'practical',
      focusAreas: ['State Management', 'UI/UX', 'API Integration'],
    );

    print('Successfully generated learning path:');
    print('Title: ${generatedPath['title']}');
    print('Description: ${generatedPath['description']}');
    print('Number of modules: ${generatedPath['modules'].length}');

    // Print a sample module to verify content
    if (generatedPath['modules'].isNotEmpty) {
      final firstModule = generatedPath['modules'][0];
      print('\nSample Module:');
      print('Title: ${firstModule['title']}');
      print('Description: ${firstModule['description']}');
      print('Prerequisites: ${firstModule['prerequisites']}');
      print(
          'Learning Objectives: ${firstModule['learning_objectives'].join(', ')}');
      print('Resources: ${firstModule['resources'].join(', ')}');
      print('Estimated Duration: ${firstModule['estimated_duration']}');
    }
  } catch (e) {
    print('Error testing learning path generator: $e');
  }
}
