import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/quiz/quiz_controller.dart';
import 'package:deltamind/services/gemini_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

/// Page for creating a new quiz
class CreateQuizPage extends ConsumerStatefulWidget {
  /// Default constructor
  const CreateQuizPage({super.key});

  @override
  ConsumerState<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends ConsumerState<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedQuizType = AppConstants.quizTypes.first;
  String _selectedDifficulty = AppConstants.quizDifficulties.first;
  int _questionCount = 5;
  bool _isLoading = false;
  String? _errorMessage;
  String? _filePath;
  String? _fileName;
  Uint8List? _fileBytes;
  String? _selectedFileType;
  String? _selectedFileName;
  File? _selectedFile;
  Uint8List? _webFileBytes;
  // Define max file size constant if not in AppConstants
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'txt', 'doc', 'docx'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        final fileName = file.name;
        final fileExt = fileName.split('.').last.toLowerCase();

        setState(() {
          _selectedFileName = fileName;
          _selectedFileType = fileExt;

          // Handle file differently based on platform
          if (kIsWeb) {
            // For web, store bytes
            file.readAsBytes().then((bytes) {
              setState(() {
                _webFileBytes = bytes;
              });
            });
            _selectedFile = null;
          } else {
            // For mobile platforms, create File object from path
            _selectedFile = File(file.path);
            _webFileBytes = null;
          }

          // Default title from filename without extension
          if (_titleController.text.isEmpty) {
            _titleController.text = fileName.split('.').first;
          }
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
    if (_formKey.currentState?.validate() != true) {
      return;
    }

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

          // Use the title from the title field
          final title = _titleController.text.trim();

          // Use the Riverpod controller to generate the quiz directly from file
          final quizController = ref.read(quizControllerProvider.notifier);

          final quiz = await quizController.generateQuizFromFile(
            title: title,
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
      // Use the title from the title field
      final title = _titleController.text.trim();

      // Update UI to show we're generating the quiz
      setState(() {
        _contentController.text =
            '${_contentController.text}\n\nGenerating quiz questions...';
      });

      // Use the Riverpod controller to generate the quiz
      final quizController = ref.read(quizControllerProvider.notifier);

      final quiz = await quizController.generateQuiz(
        title: title,
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
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.sparkle(),
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Quiz Generator',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppColors.primary,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new quiz by entering your study material or uploading a file. Our AI will generate quiz questions for you.',
                      style: AppTheme.bodyText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quiz title field
              Text(
                'Quiz Title',
                style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quiz title';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter a title for your quiz',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    PhosphorIcons.textT(),
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Settings card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.gearSix(),
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quiz Settings',
                          style: AppTheme.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quiz type selection
                    Text(
                      'Quiz Type',
                      style: AppTheme.smallText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedQuizType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items:
                          AppConstants.quizTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
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
                      style: AppTheme.smallText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
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
                      'Number of Questions: $_questionCount',
                      style: AppTheme.smallText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withOpacity(0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: _questionCount.toDouble(),
                        min: 3,
                        max: 10,
                        divisions: 7,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content section
              Text(
                'Study Material',
                style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your notes, text, or learning material, or upload a file.',
                style: AppTheme.smallText.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Upload button and file indicator
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.fileArrowUp(),
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'File Upload',
                          style: AppTheme.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: Icon(
                        PhosphorIcons.upload(),
                        color: AppColors.primary,
                      ),
                      label: Text(
                        _fileName != null ? 'Change File' : 'Upload File',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.file(),
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fileName!,
                                style: AppTheme.smallText,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                PhosphorIcons.x(),
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _filePath = null;
                                  _fileName = null;
                                  _fileBytes = null;
                                });
                              },
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Text content
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText:
                      'Paste your notes, text, or learning material here...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.warning(), color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Generate Quiz'),
                              const SizedBox(width: 8),
                              Icon(PhosphorIcons.sparkle()),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
