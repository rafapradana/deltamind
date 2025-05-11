import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/services/learning_path_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Dialog to generate a new AI learning path
class GeneratePathDialog extends StatefulWidget {
  const GeneratePathDialog({Key? key}) : super(key: key);

  @override
  State<GeneratePathDialog> createState() => _GeneratePathDialogState();
}

class _GeneratePathDialogState extends State<GeneratePathDialog> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  /// Generate a learning path
  Future<void> _generatePath() async {
    if (!_formKey.currentState!.validate()) return;

    final topic = _topicController.text.trim();

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // First, generate the learning path content using AI
      final generatedPath = await LearningPathService.generateLearningPath(
        topic,
      );

      if (!mounted) return;

      // Check if this is a fallback path
      bool isFallback = false;
      if (generatedPath['is_fallback'] == true ||
          generatedPath['additional_notes'] ==
              'Created as fallback due to AI generation error' ||
          (generatedPath['modules'] != null &&
              generatedPath['modules'] is List &&
              generatedPath['modules'].isNotEmpty &&
              generatedPath['modules'][0]['additional_notes'] ==
                  'Created as fallback due to AI generation error')) {
        isFallback = true;
      }

      // Create the learning path in the database
      await LearningPathService.createFromGeneratedPath(generatedPath);

      if (!mounted) return;

      // Close dialog with success
      Navigator.of(context).pop(true);

      // If it was a fallback path, show a notification
      if (isFallback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Created a basic learning path. AI generation had issues. You may want to edit this path later.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to generate path';

        // Show more user-friendly error messages based on error type
        if (e
            .toString()
            .contains('Gemini AI service is currently unavailable')) {
          errorMsg =
              'AI service is temporarily unavailable. Please try again later.';
        } else if (e.toString().contains('authentication')) {
          errorMsg = 'Authentication error. Please log in again.';
        } else if (e.toString().contains('internet')) {
          errorMsg = 'Network error. Please check your internet connection.';
        } else {
          errorMsg = 'Error: ${e.toString().split(':').last.trim()}';
        }

        setState(() {
          _errorMessage = errorMsg;
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsFill.brain,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Generate Learning Path',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      PhosphorIconsFill.x,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Topic input field
              TextFormField(
                controller: _topicController,
                decoration: InputDecoration(
                  labelText: 'Learning Topic',
                  hintText: 'e.g. Machine Learning, Web Development, Flutter',
                  prefixIcon:
                      Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.regular)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic';
                  }
                  if (value.trim().length < 3) {
                    return 'Topic is too short';
                  }
                  return null;
                },
                enabled: !_isGenerating,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _generatePath(),
              ),

              const SizedBox(height: 8),

              // Help text
              Text(
                'The AI will create a customized learning path with multiple modules for your selected topic.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsFill.warning,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isGenerating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _generatePath,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: _isGenerating
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Generating...'),
                            ],
                          )
                        : const Text('Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
