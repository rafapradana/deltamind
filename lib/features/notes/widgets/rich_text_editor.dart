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

  /// Whether to show the toolbar
  final bool showToolbar;

  /// External controller for the editor
  final QuillController? controller;

  /// Constructor
  const RichTextEditor({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.readOnly = false,
    this.showToolbar = true,
    this.controller,
  });

  /// Creates only the toolbar widget for external use
  static Widget toolbarOnly() {
    final controller = QuillController.basic();
    return _buildToolbar(controller);
  }

  /// Creates a toolbar widget that connects to an existing controller
  static Widget toolbarWithController(QuillController controller) {
    return _buildToolbar(controller);
  }

  /// Utility method to convert hex color string to Color
  static Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Helper to build a toolbar for a given controller
  static Widget _buildToolbar(QuillController controller) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);

      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          children: [
            // First row - Text formatting and alignment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Text formatting group
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      QuillIconButton(
                        icon: Icons.format_bold,
                        isSelected:
                            controller.getSelectionStyle().containsKey('bold'),
                        onPressed: () {
                          final isBold = controller
                              .getSelectionStyle()
                              .containsKey('bold');
                          controller.formatSelection(
                            isBold
                                ? Attribute.clone(
                                    Attribute.bold, null) // Remove bold
                                : Attribute.bold, // Add bold
                          );
                        },
                        tooltip: 'Bold',
                      ),
                      QuillIconButton(
                        icon: Icons.format_italic,
                        isSelected: controller
                            .getSelectionStyle()
                            .containsKey('italic'),
                        onPressed: () {
                          final isItalic = controller
                              .getSelectionStyle()
                              .containsKey('italic');
                          controller.formatSelection(
                            isItalic
                                ? Attribute.clone(
                                    Attribute.italic, null) // Remove italic
                                : Attribute.italic, // Add italic
                          );
                        },
                        tooltip: 'Italic',
                      ),
                      QuillIconButton(
                        icon: Icons.format_underline,
                        isSelected: controller
                            .getSelectionStyle()
                            .containsKey('underline'),
                        onPressed: () {
                          final isUnderline = controller
                              .getSelectionStyle()
                              .containsKey('underline');
                          controller.formatSelection(
                            isUnderline
                                ? Attribute.clone(Attribute.underline,
                                    null) // Remove underline
                                : Attribute.underline, // Add underline
                          );
                        },
                        tooltip: 'Underline',
                      ),
                      QuillIconButton(
                        icon: Icons.format_strikethrough,
                        isSelected: controller
                            .getSelectionStyle()
                            .containsKey('strike'),
                        onPressed: () {
                          final isStrike = controller
                              .getSelectionStyle()
                              .containsKey('strike');
                          controller.formatSelection(
                            isStrike
                                ? Attribute.clone(Attribute.strikeThrough,
                                    null) // Remove strike
                                : Attribute.strikeThrough, // Add strike
                          );
                        },
                        tooltip: 'Strikethrough',
                      ),
                    ],
                  ),
                ),

                // Alignment group
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      QuillIconButton(
                        icon: Icons.format_align_left,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('align') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['align']
                                    ?.value ==
                                'left',
                        onPressed: () {
                          final currentAlign = controller
                              .getSelectionStyle()
                              .attributes['align']
                              ?.value;
                          if (currentAlign == 'left') {
                            // Remove alignment if already left-aligned
                            controller.formatSelection(
                                Attribute.clone(Attribute.align, null));
                          } else {
                            controller.formatSelection(Attribute.leftAlignment);
                          }
                        },
                        tooltip: 'Align left',
                      ),
                      QuillIconButton(
                        icon: Icons.format_align_center,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('align') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['align']
                                    ?.value ==
                                'center',
                        onPressed: () {
                          final currentAlign = controller
                              .getSelectionStyle()
                              .attributes['align']
                              ?.value;
                          if (currentAlign == 'center') {
                            // Remove alignment if already center-aligned
                            controller.formatSelection(
                                Attribute.clone(Attribute.align, null));
                          } else {
                            controller
                                .formatSelection(Attribute.centerAlignment);
                          }
                        },
                        tooltip: 'Align center',
                      ),
                      QuillIconButton(
                        icon: Icons.format_align_right,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('align') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['align']
                                    ?.value ==
                                'right',
                        onPressed: () {
                          final currentAlign = controller
                              .getSelectionStyle()
                              .attributes['align']
                              ?.value;
                          if (currentAlign == 'right') {
                            // Remove alignment if already right-aligned
                            controller.formatSelection(
                                Attribute.clone(Attribute.align, null));
                          } else {
                            controller
                                .formatSelection(Attribute.rightAlignment);
                          }
                        },
                        tooltip: 'Align right',
                      ),
                    ],
                  ),
                ),

                // Color button
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: PopupMenuButton<Color?>(
                    icon: Icon(
                      Icons.color_lens,
                      color: controller.getSelectionStyle().containsKey('color')
                          ? RichTextEditor._getColorFromHex(controller
                                  .getSelectionStyle()
                                  .attributes['color']
                                  ?.value ??
                              '#000000')
                          : theme.iconTheme.color,
                      size: 20,
                    ),
                    tooltip: 'Text Color',
                    itemBuilder: (context) => [
                      // Clear color option
                      PopupMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.format_color_reset,
                                color: theme.iconTheme.color),
                            const SizedBox(width: 8),
                            const Text('Clear color'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Colors.black,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            const Text('Black'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Colors.red,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            const Text('Red'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Colors.blue,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            const Text('Blue'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Colors.green,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            const Text('Green'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Colors.orange,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            const Text('Orange'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Colors.purple,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            const Text('Purple'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (color) {
                      if (color == null) {
                        // Clear color
                        controller.formatSelection(
                            Attribute.clone(Attribute.color, null));
                      } else {
                        final hex =
                            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                        controller.formatSelection(ColorAttribute(hex));
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Second row - Lists, headings and special functions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Lists group
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      QuillIconButton(
                        icon: Icons.format_list_bulleted,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('list') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['list']
                                    ?.value ==
                                'bullet',
                        onPressed: () {
                          final currentList = controller
                              .getSelectionStyle()
                              .attributes['list']
                              ?.value;
                          if (currentList == 'bullet') {
                            // Remove list if already bullet list
                            controller.formatSelection(
                                Attribute.clone(Attribute.list, null));
                          } else {
                            controller.formatSelection(Attribute.ul);
                          }
                        },
                        tooltip: 'Bullet list',
                      ),
                      QuillIconButton(
                        icon: Icons.format_list_numbered,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('list') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['list']
                                    ?.value ==
                                'ordered',
                        onPressed: () {
                          final currentList = controller
                              .getSelectionStyle()
                              .attributes['list']
                              ?.value;
                          if (currentList == 'ordered') {
                            // Remove list if already ordered list
                            controller.formatSelection(
                                Attribute.clone(Attribute.list, null));
                          } else {
                            controller.formatSelection(Attribute.ol);
                          }
                        },
                        tooltip: 'Numbered list',
                      ),
                      QuillIconButton(
                        icon: Icons.check_box,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('list') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['list']
                                    ?.value ==
                                'checked',
                        onPressed: () {
                          final currentList = controller
                              .getSelectionStyle()
                              .attributes['list']
                              ?.value;
                          if (currentList == 'checked') {
                            // Remove list if already checklist
                            controller.formatSelection(
                                Attribute.clone(Attribute.list, null));
                          } else {
                            controller.formatSelection(Attribute.checked);
                          }
                        },
                        tooltip: 'Checklist',
                      ),
                    ],
                  ),
                ),

                // Heading and quote
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      QuillIconButton(
                        icon: Icons.title,
                        isSelected: controller
                                .getSelectionStyle()
                                .containsKey('heading') &&
                            controller
                                    .getSelectionStyle()
                                    .attributes['heading']
                                    ?.value ==
                                1,
                        onPressed: () {
                          final isHeading = controller
                                  .getSelectionStyle()
                                  .containsKey('heading') &&
                              controller
                                      .getSelectionStyle()
                                      .attributes['heading']
                                      ?.value ==
                                  1;
                          if (isHeading) {
                            // Remove heading if already heading - use string key approach
                            final headingAttr =
                                Attribute.fromKeyValue('heading', null);
                            controller.formatSelection(headingAttr);
                          } else {
                            controller.formatSelection(Attribute.h1);
                          }
                        },
                        tooltip: 'Heading',
                      ),
                      QuillIconButton(
                        icon: Icons.format_quote,
                        isSelected: controller
                            .getSelectionStyle()
                            .containsKey('blockquote'),
                        onPressed: () {
                          final isQuote = controller
                              .getSelectionStyle()
                              .containsKey('blockquote');
                          if (isQuote) {
                            // Remove blockquote if already blockquote
                            controller.formatSelection(
                                Attribute.clone(Attribute.blockQuote, null));
                          } else {
                            controller.formatSelection(Attribute.blockQuote);
                          }
                        },
                        tooltip: 'Quote',
                      ),
                    ],
                  ),
                ),

                // Insert/clear functions
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      // Insert image button (disabled in toolbar-only mode)
                      IconButton(
                        icon: const Icon(Icons.image, size: 20),
                        tooltip: 'Insert Image',
                        onPressed: null, // Disabled in standalone toolbar
                      ),
                      // Clear formatting button
                      IconButton(
                        icon: const Icon(Icons.format_clear, size: 20),
                        tooltip: 'Clear Formatting',
                        onPressed: () {
                          // Clear all formatting in one step
                          controller.formatSelection(
                              Attribute.clone(Attribute.link, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.bold, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.italic, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.underline, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.strikeThrough, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.color, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.background, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.align, null));
                          controller.formatSelection(
                              Attribute.clone(Attribute.list, null));
                          // Clear heading formatting with string key
                          final headingAttr =
                              Attribute.fromKeyValue('heading', null);
                          controller.formatSelection(headingAttr);
                          controller.formatSelection(
                              Attribute.clone(Attribute.blockQuote, null));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

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

    // Request focus after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.readOnly && mounted) {
        _focusNode.requestFocus();
      }
    });
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
    if (widget.controller != null) {
      // Use the provided controller
      _controller = widget.controller!;
    } else if (widget.initialContent != null &&
        widget.initialContent!.isNotEmpty) {
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

    return Column(
      children: [
        // Toolbar at the top - First row (Text formatting)
        if (!widget.readOnly && widget.showToolbar)
          RichTextEditor._buildToolbar(_controller),

        // Editor
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!widget.readOnly) {
                _focusNode.requestFocus();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Stack(
                children: [
                  // Editor
                  QuillEditor.basic(
                    controller: _controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                  ),

                  // Saving indicator
                  if (_isSaving)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menyimpan...',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom QuillIconButton for toolbar
class QuillIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final String? tooltip;

  const QuillIconButton({
    Key? key,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
              size: 20,
            ),
          ),
        ),
      ),
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
      // If can't parse as JSON, display as plain text
      return Text(
        content!,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      );
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
