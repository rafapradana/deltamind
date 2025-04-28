import 'package:deltamind/core/config/gemini_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

/// Service for interacting with Google Gemini API
class GeminiService {
  static GenerativeModel? _model;

  /// Initialize Gemini model
  static Future<void> initialize() async {
    try {
      await dotenv.load();
      
      final apiKey = GeminiConfig.apiKeyFromEnv;
      _model = GenerativeModel(
        model: GeminiConfig.modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );
      
      debugPrint(
        'Gemini initialized successfully with model: ${GeminiConfig.modelName}',
      );
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
      rethrow;
    }
  }

  /// Get the initialized model
  static GenerativeModel get model {
    if (_model == null) {
      throw Exception('Gemini model not initialized');
    }
    return _model!;
  }

  /// Generate quiz from text content
  /// 
  /// [content] is the text material to generate quiz from
  /// [format] is the quiz format (Multiple Choice, True/False, etc.)
  /// [difficulty] is the difficulty level (Easy, Medium, Hard)
  /// [questionCount] is the number of questions to generate
  static Future<String> generateQuiz({
    required String content,
    required String format,
    required String difficulty,
    int questionCount = 5,
  }) async {
    try {
      final prompt = '''
Generate $questionCount $format questions at $difficulty difficulty level based on the following content:

$content

Format the output in JSON like this:
{
  "questions": [
    {
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"], 
      "answer": "Correct option here",
      "explanation": "Brief explanation of the answer"
    }
  ]
}

For True/False questions, options should be just ["True", "False"].
For Fill in the Blank questions, use "_____" to indicate the blank in the question, and options should be possible answers.
Make sure questions are varied and cover different parts of the content.
The answer must be the exact text of the correct option.

Important: Return only valid JSON, do not include any markdown formatting.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text;
      
      if (result == null || result.isEmpty) {
        throw Exception('Failed to generate quiz: Empty response');
      }
      
      // Process the response to extract JSON if it's in a markdown code block
      String processedResult = result;
      
      // Check if the response is wrapped in markdown code blocks
      if (result.contains('```json')) {
        // Extract content between ```json and ``` markers
        final startMarker = '```json';
        final endMarker = '```';
        final startIndex = result.indexOf(startMarker) + startMarker.length;
        final endIndex = result.lastIndexOf(endMarker);
        
        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult = result.substring(startIndex, endIndex).trim();
          debugPrint('Extracted JSON from markdown code block');
        }
      } else if (result.contains('```')) {
        // Handle case where code block doesn't specify language
        final startMarker = '```';
        final endMarker = '```';
        final startIndex = result.indexOf(startMarker) + startMarker.length;
        final endIndex = result.lastIndexOf(endMarker);
        
        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult = result.substring(startIndex, endIndex).trim();
          debugPrint('Extracted content from generic markdown code block');
        }
      }
      
      // Validate JSON structure (try parsing it)
      try {
        final jsonTest = jsonDecode(processedResult);
        if (!jsonTest.containsKey('questions')) {
          throw Exception('Invalid JSON structure: missing questions array');
        }
      } catch (e) {
        debugPrint('Warning: Response is not valid JSON: $e');
        debugPrint('Raw response: $result');
        // If we can't parse the processed result, attempt to parse various substrings
        // to find valid JSON
        
        // Look for opening brace
        final firstBrace = result.indexOf('{');
        final lastBrace = result.lastIndexOf('}');
        
        if (firstBrace >= 0 && lastBrace >= 0 && firstBrace < lastBrace) {
          processedResult = result.substring(firstBrace, lastBrace + 1);
          debugPrint('Attempting to extract JSON by finding braces');
          
          // Validate this extracted content
          try {
            final jsonTest = jsonDecode(processedResult);
            if (!jsonTest.containsKey('questions')) {
              throw Exception(
                'Extracted JSON is invalid: missing questions array',
              );
            }
          } catch (e) {
            // If we still can't parse it, throw the original exception
            throw Exception('Failed to parse AI response: $e');
          }
        } else {
          throw Exception('Failed to extract valid JSON from response');
        }
      }
      
      // Return the processed result
      debugPrint(
        'Generated quiz with ${questionCount} questions at ${difficulty} difficulty',
      );
      return processedResult;
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      throw Exception('Error generating quiz: $e');
    }
  }

  /// Extract key concepts from text content
  static Future<String> extractKeyConcepts(String content) async {
    try {
      final prompt = '''
Extract the 5-7 most important key concepts or facts from the following content. 
Format them as a bulleted list.

$content
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Failed to extract key concepts';
    } catch (e) {
      debugPrint('Error extracting key concepts: $e');
      return 'Error: $e';
    }
  }

  /// Generate explanation for a topic
  static Future<String> generateExplanation({
    required String topic,
    String complexity = 'Medium',
  }) async {
    try {
      final prompt = '''
Explain the following topic in a clear, concise manner at a $complexity complexity level:

$topic

Include examples if relevant.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Failed to generate explanation';
    } catch (e) {
      debugPrint('Error generating explanation: $e');
      return 'Error: $e';
    }
  }
  
  /// Review quiz answers and provide feedback
  static Future<String> reviewQuizAnswers({
    required List<Map<String, dynamic>> questions,
    required List<String> userAnswers,
  }) async {
    try {
      if (questions.length != userAnswers.length) {
        throw Exception('Number of questions and answers do not match');
      }
      
      final questionsAndAnswers = <String>[];
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final userAnswer = userAnswers[i];
        final correctAnswer = question['answer'] as String;
        
        questionsAndAnswers.add('''
Question ${i + 1}: ${question['question']}
Options: ${(question['options'] as List).join(', ')}
Correct answer: $correctAnswer
User's answer: $userAnswer
Explanation: ${question['explanation'] ?? 'No explanation provided'}
        ''');
      }
      
      final prompt = '''
Review the following quiz answers and provide detailed feedback to the user. 

${questionsAndAnswers.join('\n')}

Format your response in clear markdown with the following sections:
## Overall Assessment
Provide a brief assessment of how the user did, considering their score, pattern of mistakes, and overall understanding.

## Analysis of Incorrect Answers
For any incorrect answers, explain why they were wrong and what misconceptions they might reveal.

## Key Concepts to Review
List 3-5 specific concepts the user should focus on based on their performance.

## Study Recommendations
Suggest specific study approaches, resources, or techniques that would help the user improve.

## Next Steps
Recommend what the user should do next to deepen their understanding.

Make your feedback constructive, encouraging, and personalized. Keep the total response under 800 words.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final feedback = response.text ?? 'Failed to review quiz answers';
      
      // If the response is empty or very short, provide a generic response
      if (feedback.isEmpty || feedback.length < 100) {
        // Count correct answers
        int correctCount = 0;
        for (int i = 0; i < questions.length; i++) {
          if (questions[i]['answer'] == userAnswers[i]) {
            correctCount++;
          }
        }
        
        return '''
## Quiz Review

### Performance Summary
You answered $correctCount out of ${questions.length} questions correctly.

### Suggestions for Improvement
- Review the explanations for questions you answered incorrectly
- Focus on understanding the key concepts rather than memorizing answers
- Consider revisiting the study material for better understanding
- Practice with similar questions to reinforce your knowledge
''';
      }
      
      return feedback;
    } catch (e) {
      debugPrint('Error reviewing quiz answers: $e');
      return '''
## Quiz Review

Sorry, I was unable to generate a detailed review at this time.

### General Suggestions
- Take time to review the questions you answered incorrectly
- Look at the explanations provided for each question
- Consider retaking the quiz after studying the material again

Error details: $e
''';
    }
  }
  
  /// Generate detailed AI recommendations for a completed quiz
  /// 
  /// This method analyzes user performance and provides personalized recommendations
  /// [quizData] is information about the quiz (title, type, difficulty)
  /// [userAnswers] contains the user's answers with correctness information
  /// [content] optional original content used to generate the quiz
  static Future<Map<String, dynamic>> generateQuizRecommendations({
    required Map<String, dynamic> quizData,
    required List<Map<String, dynamic>> userAnswers,
    String? quizContent,
  }) async {
    try {
      final correctAnswers =
          userAnswers.where((a) => a['is_correct'] == true).length;
      final totalQuestions = userAnswers.length;
      final percentageScore =
          totalQuestions > 0
          ? (correctAnswers / totalQuestions * 100).round() 
          : 0;
          
      // Build information about questions and answers
      final questionsAndAnswers = <String>[];
      for (var answer in userAnswers) {
        final question = answer['questions'];
        final userAnswer = answer['user_answer'];
        final isCorrect = answer['is_correct'];
        final correctAnswer = question['correct_answer'];
        
        questionsAndAnswers.add('''
Question: ${question['question_text']}
Options: ${question['options'] is String ? question['options'] : jsonEncode(question['options'])}
Correct answer: $correctAnswer
User's answer: $userAnswer
Is correct: $isCorrect
Explanation: ${question['explanation'] ?? 'No explanation provided'}
        ''');
      }
      
      // Create a comprehensive prompt for detailed recommendations
      final prompt = '''
I need you to analyze a user's quiz performance and provide detailed, personalized recommendations.

QUIZ INFORMATION:
- Title: ${quizData['quizzes']['title']}
- Type: ${quizData['quizzes']['quiz_type']}
- Difficulty: ${quizData['quizzes']['difficulty']}
- Score: $correctAnswers out of $totalQuestions ($percentageScore%)

QUESTIONS AND ANSWERS:
${questionsAndAnswers.join('\n')}

${quizContent != null && quizContent.isNotEmpty ? "ORIGINAL STUDY CONTENT:\n$quizContent" : ""}

Based on this information, please provide a detailed analysis and personalized recommendations in JSON format with the following structure:

{
  "overall_assessment": "A comprehensive assessment of the user's performance, strengths, weaknesses, and patterns observed",
  
  "weak_areas": "Identify specific topics or concepts the user struggled with based on incorrect answers",
  
  "strong_areas": "Identify specific topics or concepts the user showed mastery of based on correct answers",
  
  "learning_recommendations": "Detailed, actionable learning strategies tailored to the user's performance patterns",
  
  "study_resources": "Recommend specific types of resources that would help this user improve (books, videos, practice problems, etc.)",
  
  "next_steps": "Clear, specific next steps the user should take to improve their understanding"
}

Make the recommendations specific, detailed, and personalized to this user's actual performance. Focus on being helpful, constructive, and motivational. The recommendations should be actionable and practical.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text;
      
      if (result == null || result.isEmpty) {
        throw Exception('Failed to generate recommendations: Empty response');
      }
      
      // Process the response to extract JSON
      String processedResult = result;
      
      // Extract JSON content from response
      if (result.contains('{') && result.contains('}')) {
        final startIndex = result.indexOf('{');
        final endIndex = result.lastIndexOf('}') + 1;
        
        if (startIndex >= 0 && endIndex > startIndex) {
          processedResult = result.substring(startIndex, endIndex);
        }
      }
      
      try {
        final jsonResult = jsonDecode(processedResult);
        return jsonResult;
      } catch (e) {
        // If we can't parse JSON, return a fallback recommendation
        debugPrint('Error parsing AI recommendations: $e');
        final scoreMessage =
            percentageScore >= 70
            ? 'Great job!' 
            : percentageScore >= 50 
                ? 'Good effort, but there\'s room for improvement.' 
                : 'You might need more practice with this material.';
        
        return {
          // New field names
          'performance_overview':
              'You scored $correctAnswers out of $totalQuestions ($percentageScore%). $scoreMessage',
          'strengths':
              'Continue building on concepts you already understand well.',
          'areas_for_improvement':
              'Review the questions you answered incorrectly to identify knowledge gaps.',
          'learning_strategies':
              'Focus on understanding the core concepts rather than memorizing answers. Try creating your own questions to test your understanding.',
          'action_plan':
              'Review your incorrect answers, create a study plan focusing on weak areas, and consider retaking a similar quiz in a week to measure improvement.',
          
          // Old field names for backward compatibility
          'overall_assessment':
              'You scored $correctAnswers out of $totalQuestions ($percentageScore%). $scoreMessage',
          'strong_areas':
              'Continue building on concepts you already understand well.',
          'weak_areas':
              'Review the questions you answered incorrectly to identify knowledge gaps.',
          'learning_recommendations':
              'Focus on understanding the core concepts rather than memorizing answers. Try creating your own questions to test your understanding.',
          'study_resources':
              'Consider using flashcards for key terms, watching video tutorials for complex topics, and finding practice problems related to topics you struggled with.',
          'next_steps':
              'Review your incorrect answers, create a study plan focusing on weak areas, and consider retaking a similar quiz in a week to measure improvement.',
        };
      }
    } catch (e) {
      debugPrint('Error generating quiz recommendations: $e');
      return {
        // New field names
        'performance_overview':
            'Sorry, we encountered an issue generating detailed recommendations.',
        'strengths': 'Continue to build on your strengths.',
        'areas_for_improvement':
            'Review the questions you answered incorrectly.',
        'learning_strategies':
            'Consider reviewing the material again and focusing on fundamentals.',
        'action_plan':
            'Review incorrect answers and try another quiz to practice.',
        
        // Old field names for backward compatibility
        'overall_assessment':
            'Sorry, we encountered an issue generating detailed recommendations.',
        'strong_areas': 'Continue to build on your strengths.',
        'weak_areas': 'Review the questions you answered incorrectly.',
        'learning_recommendations':
            'Consider reviewing the material again and focusing on fundamentals.',
        'study_resources':
            'Textbooks, online courses, and practice problems can help reinforce your understanding.',
        'next_steps':
            'Review incorrect answers and try another quiz to practice.',
      };
    }
  }

  /// Generate quiz from file content
  ///
  /// [fileBytes] is the raw bytes of the file
  /// [fileName] is the name of the file with extension
  /// [fileType] is the type of file (e.g., 'pdf', 'txt', 'image')
  /// [format] is the quiz format (Multiple Choice, True/False, etc.)
  /// [difficulty] is the difficulty level (Easy, Medium, Hard)
  /// [questionCount] is the number of questions to generate
  static Future<String> generateQuizFromFile({
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    required String format,
    required String difficulty,
    int questionCount = 5,
  }) async {
    try {
      String promptIntro;
      // Handle different file types
      switch (fileType.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
        case 'png':
          promptIntro =
              'Generate $questionCount $format questions at $difficulty difficulty level based on the content shown in this image:';
          // Currently images are not directly supported by the API setup being used
          // Instead we'll use a text prompt to simulate image content processing
          promptIntro =
              'I am analyzing an image titled "$fileName". Based on this image, please:';
          break;
        case 'doc':
        case 'docx':
          promptIntro =
              'Generate $questionCount $format questions at $difficulty difficulty level based on the content in this document:';
          break;
        case 'pdf':
        case 'txt':
        default:
          promptIntro =
              'Generate $questionCount $format questions at $difficulty difficulty level based on the following content:';
          break;
      }

      final prompt = '''
$promptIntro

[File content from: $fileName]

Format the output in JSON like this:
{
  "questions": [
    {
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"], 
      "answer": "Correct option here",
      "explanation": "Brief explanation of the answer"
    }
  ]
}

For True/False questions, options should be just ["True", "False"].
For Fill in the Blank questions, use "_____" to indicate the blank in the question, and options should be possible answers.
Make sure questions are varied and cover different parts of the content.
The answer must be the exact text of the correct option.

Important: Return only valid JSON, do not include any markdown formatting.
''';

      // For actual implementation with Gemini's multimodal features:
      // final response = await model.generateContent([
      //   Content.multi([
      //     Parts.text(prompt),
      //     if (['jpg', 'jpeg', 'png'].contains(fileType.toLowerCase()))
      //       Parts.bytes(fileBytes, mimeType: 'image/${fileType.toLowerCase()}')
      //   ])
      // ]);

      // For now, we'll use the text-only API
      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result == null || result.isEmpty) {
        throw Exception('Failed to generate quiz: Empty response');
      }

      // Process the response to extract JSON
      String processedResult = result;

      // Check if the response is wrapped in markdown code blocks
      if (result.contains('```json')) {
        // Extract content between ```json and ``` markers
        final startMarker = '```json';
        final endMarker = '```';
        final startIndex = result.indexOf(startMarker) + startMarker.length;
        final endIndex = result.lastIndexOf(endMarker);

        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult = result.substring(startIndex, endIndex).trim();
          debugPrint('Extracted JSON from markdown code block');
        }
      } else if (result.contains('```')) {
        // Handle case where code block doesn't specify language
        final startMarker = '```';
        final endMarker = '```';
        final startIndex = result.indexOf(startMarker) + startMarker.length;
        final endIndex = result.lastIndexOf(endMarker);

        if (startIndex >= 0 && endIndex >= 0 && startIndex < endIndex) {
          processedResult = result.substring(startIndex, endIndex).trim();
          debugPrint('Extracted content from generic markdown code block');
        }
      }

      // Validate JSON structure
      try {
        final jsonTest = jsonDecode(processedResult);
        if (!jsonTest.containsKey('questions')) {
          throw Exception('Invalid JSON structure: missing questions array');
        }
      } catch (e) {
        debugPrint('Warning: Response is not valid JSON: $e');

        // Look for opening brace
        final firstBrace = result.indexOf('{');
        final lastBrace = result.lastIndexOf('}');

        if (firstBrace >= 0 && lastBrace >= 0 && firstBrace < lastBrace) {
          processedResult = result.substring(firstBrace, lastBrace + 1);

          try {
            final jsonTest = jsonDecode(processedResult);
            if (!jsonTest.containsKey('questions')) {
              throw Exception(
                'Extracted JSON is invalid: missing questions array',
              );
            }
          } catch (e) {
            throw Exception('Failed to parse AI response: $e');
          }
        } else {
          throw Exception('Failed to extract valid JSON from response');
        }
      }

      debugPrint(
        'Generated quiz with $questionCount questions at $difficulty difficulty from file $fileName',
      );
      return processedResult;
    } catch (e) {
      debugPrint('Error generating quiz from file: $e');
      throw Exception('Error generating quiz from file: $e');
    }
  }
}
