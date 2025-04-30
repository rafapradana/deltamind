import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/quill_delta.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

/// Type definition for image pick callback
typedef OnImagePickCallback = Future<String> Function(File file);

/// Rich text editor widget using Flutter Quill
class RichTextEditor extends StatefulWidget {
  /// Initial content in JSON format
  final String? initialContent;

  /// Callback when content changes
  final Function(String)? onContentChanged;

  /// Whether the editor is in read-only mode
  final bool readOnly;

  /// Constructor
  const RichTextEditor({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.readOnly = false,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent &&
        widget.initialContent !=
            jsonEncode(_controller.document.toDelta().toJson())) {
      _initializeController();
    }

    // Update readOnly state if it changed
    if (oldWidget.readOnly != widget.readOnly) {
      _controller.readOnly = widget.readOnly;
    }
  }

  void _initializeController() {
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.initialContent!);
        _controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback to empty document if JSON parsing fails
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    // Set the read-only property on the controller
    _controller.readOnly = widget.readOnly;

    _controller.document.changes.listen((event) {
      if (widget.onContentChanged != null) {
        setState(() {
          _isSaving = true;
        });

        final json = jsonEncode(_controller.document.toDelta().toJson());
        widget.onContentChanged!(json);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _onImagePickCallback(File file) async {
    // Save the image to a temporary directory and return the path
    final appDocDir = await getApplicationDocumentsDirectory();
    final filename = '${const Uuid().v4()}.${file.path.split('.').last}';
    final copiedFile = await file.copy('${appDocDir.path}/$filename');
    return copiedFile.path;
  }

  Future<String?> _webImagePickImpl(
      OnImagePickCallback onImagePickCallback) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return onImagePickCallback(File(pickedFile.path));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height -
              180, // Fixed height to avoid unbounded constraints
          child: Column(
            children: [
              // We're not using a toolbar for now to avoid compatibility issues
              Expanded(
                child: Container(
                  color: widget.readOnly
                      ? Colors.transparent
                      : theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20), // Match title field padding
                  child: QuillEditor.basic(
                    controller: _controller,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSaving)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget to display rich text content in read-only mode
class RichTextViewer extends StatelessWidget {
  /// Rich text content in JSON format
  final String? content;

  /// Max height for the viewer
  final double? maxHeight;

  /// Constructor
  const RichTextViewer({
    super.key,
    required this.content,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    QuillController controller;
    try {
      final json = jsonDecode(content!);
      controller = QuillController(
        document: Document.fromJson(json),
        selection: const TextSelection.collapsed(offset: 0),
      );
      // Set to read-only mode
      controller.readOnly = true;
    } catch (e) {
      return const Text('Error loading content');
    }

    return Container(
      constraints:
          maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      child: QuillEditor.basic(
        controller: controller,
      ),
    );
  }
}
