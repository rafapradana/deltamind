import 'dart:io';
import 'dart:typed_data';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/models/flashcard.dart';
import 'package:deltamind/services/flashcard_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// CreateFlashcardDeckPage allows creating flashcards from files
class CreateFlashcardDeckPage extends StatefulWidget {
  /// Creates a CreateFlashcardDeckPage
  const CreateFlashcardDeckPage({Key? key}) : super(key: key);

  @override
  State<CreateFlashcardDeckPage> createState() =>
      _CreateFlashcardDeckPageState();
}

class _CreateFlashcardDeckPageState extends State<CreateFlashcardDeckPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  Uint8List? _webFileBytes;
  String? _selectedFileName;
  String? _selectedFileType;
  int _cardCount = 10;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  Future<void> _createDeck() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedFile == null && _webFileBytes == null) {
      setState(() {
        _errorMessage = 'Please select a file to generate flashcards';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final deck = await FlashcardService.createFlashcardsFromFile(
        file: _selectedFile,
        fileBytes: _webFileBytes,
        fileName: _selectedFileName!,
        fileType: _selectedFileType!,
        title: _titleController.text,
        description: _descriptionController.text,
        cardCount: _cardCount,
      );

      if (mounted) {
        // Show success and navigate to the deck detail page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${deck.cardCount} flashcards'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/flashcards/${deck.id}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error creating flashcards: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Flashcard Deck'),
      ),
      body: _isProcessing
          ? _buildLoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    _buildFileSelector(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Deck Title',
                        hintText: 'Enter a title for your flashcard deck',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add a description for your flashcards',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildCardCountSelector(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_selectedFile != null || _webFileBytes != null)
                                ? _createDeck
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Generate Flashcards',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Generating Flashcards...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Using AI to create ${_cardCount} flashcards from ${_selectedFileName ?? 'your file'}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Text(
            'This may take a minute or two depending on the file size.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelector() {
    final bool hasSelectedFile = _selectedFile != null || _webFileBytes != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          const Text(
            'Upload File to Generate Flashcards',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a PDF, TXT, or DOC file',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (!hasSelectedFile) ...[
            Icon(
              PhosphorIconsFill.fileArrowUp,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select File'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _fileTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_selectedFileType?.toUpperCase()} file',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _webFileBytes = null;
                        _selectedFileName = null;
                        _selectedFileType = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.grey),
                    tooltip: 'Remove file',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload, size: 16),
              label: const Text('Choose a different file'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fileTypeIcon() {
    if (_selectedFileType == null) {
      return Icon(PhosphorIconsRegular.file, color: Colors.grey[600]);
    }

    switch (_selectedFileType) {
      case 'pdf':
        return Icon(PhosphorIconsRegular.filePdf, color: Colors.red[600]);
      case 'doc':
      case 'docx':
        return Icon(PhosphorIconsRegular.fileDoc, color: Colors.blue[600]);
      case 'txt':
        return Icon(PhosphorIconsRegular.fileTxt, color: Colors.grey[600]);
      default:
        return Icon(PhosphorIconsRegular.file, color: Colors.grey[600]);
    }
  }

  Widget _buildCardCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Flashcards to Generate: $_cardCount',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _cardCount.toDouble(),
          min: 5,
          max: 30,
          divisions: 25,
          label: _cardCount.toString(),
          onChanged: (value) {
            setState(() {
              _cardCount = value.round();
            });
          },
        ),
        const Text(
          'Tip: Start with fewer cards for better quality. You can always add more later.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
