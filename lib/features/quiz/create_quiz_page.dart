import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/quiz/quiz_controller.dart';
import 'package:deltamind/services/gemini_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Page for creating a new quiz
class CreateQuizPage extends ConsumerStatefulWidget {
  /// Default constructor
  const CreateQuizPage({super.key});

  @override
  ConsumerState<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends ConsumerState<CreateQuizPage> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedQuizType = AppConstants.quizTypes.first;
  String _selectedDifficulty = AppConstants.quizDifficulties.first;
  int _questionCount = 5;
  bool _isLoading = false;
  String? _errorMessage;
  String? _filePath;
  String? _fileName;
  Uint8List? _fileBytes;
  // Define max file size constant if not in AppConstants
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true, // Ensures bytes are available for web platform
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size
        if (file.size > maxFileSize) {
          setState(() {
            _errorMessage = 'File is too large. Maximum size is 5MB.';
          });
          return;
        }

        // Validate if we have bytes for web platform
        if (kIsWeb && file.bytes == null) {
          setState(() {
            _errorMessage = 'Error: Cannot access file data on web platform.';
          });
          return;
        }

        final String fileExtension = file.name.split('.').last.toLowerCase();
        if (![
          'txt',
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
        ].contains(fileExtension)) {
          setState(() {
            _errorMessage =
                'Unsupported file format. Please upload a text, document, PDF, or image file.';
          });
          return;
        }

        setState(() {
          _fileName = file.name;
          _fileBytes = file.bytes; // This works on all platforms including web
          // Only set path if not on web platform
          if (!kIsWeb) {
            _filePath = file.path;
          }
          _errorMessage = null;
        });

        // Update the UI to show the file is ready for processing
        setState(() {
          _contentController.text =
              'File uploaded: $_fileName\n\n'
              '${_getFileTypeDescription(fileExtension)} ready for processing.\n\n'
              'Click "Generate Quiz" to create a quiz from this file content.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  String _getFileTypeDescription(String extension) {
    switch (extension) {
      case 'pdf':
        return 'PDF document';
      case 'doc':
      case 'docx':
        return 'Word document';
      case 'txt':
        return 'Text file';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'Image file';
      default:
        return 'File';
    }
  }

  Future<void> _generateQuiz() async {
    if (_contentController.text.trim().isEmpty && _fileBytes == null) {
      setState(() {
        _errorMessage = 'Please enter some content or upload a file';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Process file if available
      if (_fileBytes != null && _fileName != null) {
        final String fileExtension = _fileName!.split('.').last.toLowerCase();

        // Update loading state with file processing info
        setState(() {
          _contentController.text =
              'Processing ${fileExtension.toUpperCase()} file...';
        });

        if (fileExtension == 'pdf') {
          try {
            // Load PDF document from bytes (works on all platforms)
            final PdfDocument document = PdfDocument(inputBytes: _fileBytes);
            final PdfTextExtractor extractor = PdfTextExtractor(document);

            // Extract text from all pages
            final buffer = StringBuffer();
            for (int i = 1; i <= document.pages.count; i++) {
              setState(() {
                _contentController.text =
                    'Processing PDF page $i of ${document.pages.count}...';
              });

              String text = extractor.extractText(
                startPageIndex: i - 1,
                endPageIndex: i - 1,
              );
              buffer.write(text);
              buffer.write('\n\n');
            }

            // Update text content
            setState(() {
              _contentController.text = buffer.toString();
            });

            // Dispose the document
            document.dispose();
          } catch (e) {
            setState(() {
              _errorMessage = 'Error processing PDF: $e';
              _isLoading = false;
            });
            return;
          }
        } else if (fileExtension == 'txt') {
          try {
            // Use file bytes for consistent behavior across platforms
            final fileContent = utf8.decode(_fileBytes!);
            setState(() {
              _contentController.text = fileContent;
            });
          } catch (e) {
            setState(() {
              _errorMessage = 'Error reading text file: $e';
              _isLoading = false;
            });
            return;
          }
        } else if ([
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
        ].contains(fileExtension)) {
          // For complex file types like documents and images, use the specialized method
          // Process directly with Gemini

          // Extract a title from the filename
          final title =
              _fileName!.split('.').first.length > 3
                  ? _fileName!.split('.').first
                  : 'Quiz on ${DateTime.now().toString().substring(0, 10)}';

          final sanitizedTitle =
              title.length > 50 ? title.substring(0, 50) : title;

          // Use the Riverpod controller to generate the quiz directly from file
          final quizController = ref.read(quizControllerProvider.notifier);

          final quiz = await quizController.generateQuizFromFile(
            title: sanitizedTitle,
            description: 'Generated quiz based on ${_fileName!}',
            quizType: _selectedQuizType,
            difficulty: _selectedDifficulty,
            fileBytes: _fileBytes!,
            fileName: _fileName!,
            questionCount: _questionCount,
          );

          if (!mounted) return;

          if (quiz != null) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Quiz generated successfully!'),
                backgroundColor: AppTheme.successColor,
              ),
            );

            // Navigate to the quiz details page
            Navigator.of(context).pop();
            context.go('/quiz/${quiz.id}');
            return; // Exit early as we've already handled this case
          } else {
            throw Exception('Failed to generate quiz from file');
          }
        } else {
          setState(() {
            _errorMessage = 'Unsupported file type: $fileExtension';
            _isLoading = false;
          });
          return;
        }
      }

      // If we get here, we're processing text content
      // Extract a title from the first line of the content
      final contentLines = _contentController.text.split('\n');
      final title =
          contentLines.first.isNotEmpty
              ? contentLines.first.trim()
              : 'Quiz on ${DateTime.now().toString().substring(0, 10)}';

      // Update UI to show we're generating the quiz
      setState(() {
        _contentController.text =
            '${_contentController.text}\n\nGenerating quiz questions...';
      });

      // Use the Riverpod controller to generate the quiz
      final quizController = ref.read(quizControllerProvider.notifier);

      final quiz = await quizController.generateQuiz(
        title: title.length > 50 ? title.substring(0, 50) : title,
        description: 'Generated quiz based on provided content',
        quizType: _selectedQuizType,
        difficulty: _selectedDifficulty,
        content: _contentController.text,
        questionCount: _questionCount,
      );

      if (!mounted) return;

      if (quiz != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quiz generated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to the quiz details page
        Navigator.of(context).pop();
        context.go('/quiz/${quiz.id}');
      } else {
        throw Exception('Failed to generate quiz');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error generating quiz: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Text('Create a new quiz', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Enter your study material below or upload a file to generate questions.',
              style: AppTheme.bodyText.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Content input
            Text(
              'Study Material',
              style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText:
                    'Paste your notes, text, or learning material here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickFile,
              icon: Icon(PhosphorIcons.upload()),
              label: Text(_fileName != null ? 'Change File' : 'Upload File'),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(PhosphorIcons.file(), size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName!,
                      style: AppTheme.smallText.copyWith(
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x()),
                    onPressed: () {
                      setState(() {
                        _filePath = null;
                        _fileName = null;
                      });
                    },
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Quiz type selection
            Text(
              'Quiz Type',
              style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedQuizType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
              ),
              items:
                  AppConstants.quizTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedQuizType = value;
                          });
                        }
                      },
            ),
            const SizedBox(height: 16),

            // Difficulty selection
            Text(
              'Difficulty',
              style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
              ),
              items:
                  AppConstants.quizDifficulties.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty),
                    );
                  }).toList(),
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDifficulty = value;
                          });
                        }
                      },
            ),
            const SizedBox(height: 16),

            // Question count
            Text(
              'Number of Questions',
              style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _questionCount.toDouble(),
                    min: 3,
                    max: 10,
                    divisions: 7,
                    label: _questionCount.toString(),
                    onChanged:
                        _isLoading
                            ? null
                            : (value) {
                              setState(() {
                                _questionCount = value.round();
                              });
                            },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                  ),
                  child: Text(
                    _questionCount.toString(),
                    style: AppTheme.subtitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.warning(), color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Generate button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateQuiz,
                child:
                    _isLoading
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Generating Quiz...'),
                          ],
                        )
                        : const Text('Generate Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
