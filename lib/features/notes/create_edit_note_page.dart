import 'dart:async';
import 'dart:convert';
import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/notes/notes_controller.dart';
import 'package:deltamind/features/notes/widgets/note_tags_editor.dart';
import 'package:deltamind/features/notes/widgets/rich_text_editor.dart';
import 'package:deltamind/models/note.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Timer for auto-save feature
final autoSaveTimerProvider = Provider<int>((ref) => 3000); // 3 seconds

/// Page to create or edit a note
class CreateEditNotePage extends ConsumerStatefulWidget {
  /// Note ID to edit, or null to create a new note
  final String? noteId;

  /// Constructor
  const CreateEditNotePage({
    super.key,
    this.noteId,
  });

  @override
  ConsumerState<CreateEditNotePage> createState() => _CreateEditNotePageState();
}

class _CreateEditNotePageState extends ConsumerState<CreateEditNotePage> {
  final TextEditingController _titleController = TextEditingController();
  String? _content;
  final FocusNode _titleFocusNode = FocusNode();

  bool _isPinned = false;
  String? _noteColor;
  List<String> _tags = [];

  Note? _existingNote;
  bool _isLoading = false;
  bool _isDirty = false;
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNote();

    // Set up title change listener for auto-save
    _titleController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }

    // Reset the auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      Duration(milliseconds: ref.read(autoSaveTimerProvider)),
      _autoSave,
    );
  }

  void _onEditorContentChanged(String newContent) {
    _content = newContent;
    _onContentChanged();
  }

  Future<void> _autoSave() async {
    if (!_isDirty || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    await _saveNote(showFeedback: false);

    setState(() {
      _isDirty = false;
      _isSaving = false;
    });
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notesController = ref.read(notesControllerProvider.notifier);
      final note = await notesController.getNoteById(widget.noteId!);

      if (note != null && mounted) {
        _existingNote = note;
        _titleController.text = note.title;
        _content = note.content;
        _isPinned = note.isPinned;
        _noteColor = note.color;
        _tags = List.from(note.tags);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _saveNote(
      {bool showFeedback = true, bool popWhenDone = false}) async {
    // Validate title is not empty
    if (_titleController.text.trim().isEmpty) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title cannot be empty')),
        );
      }
      return false;
    }

    final notesController = ref.read(notesControllerProvider.notifier);
    final userId = SupabaseService.currentUser?.id;

    if (userId == null) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save notes')),
        );
      }
      return false;
    }

    try {
      if (_existingNote != null) {
        // Update existing note
        await notesController.updateNote(
          _existingNote!.copyWith(
            title: _titleController.text,
            content: _content,
            tags: _tags,
            color: _noteColor,
            isPinned: _isPinned,
          ),
        );
      } else {
        // Create new note
        await notesController.createNote(
          Note.create(
            title: _titleController.text,
            content: _content,
            tags: _tags,
            userId: userId,
            color: _noteColor,
            isPinned: _isPinned,
          ),
        );
      }

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingNote != null ? 'Note updated' : 'Note created',
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isDirty = false;
        });
      }

      if (popWhenDone && mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/notes');
        }
      }

      return true;
    } catch (e) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
      return false;
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('DISCARD'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result == true) {
      return await _saveNote();
    }

    return true;
  }

  void _showTagsEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NoteTagsEditor(
        initialTags: _tags,
        availableTags: ref.read(notesControllerProvider).availableTags,
        onTagsChanged: (tags) {
          setState(() {
            _tags = tags;
            _isDirty = true;
          });
        },
      ),
    );
  }

  void _showColorPicker() {
    final colors = {
      'Default': null,
      'Red': 'red',
      'Orange': 'orange',
      'Yellow': 'yellow',
      'Green': 'green',
      'Teal': 'teal',
      'Blue': 'blue',
      'Purple': 'purple',
      'Pink': 'pink',
      'Gray': 'gray',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.entries.map((entry) {
            Color displayColor = Colors.white;
            switch (entry.value) {
              case 'red':
                displayColor = Colors.red[100]!;
                break;
              case 'orange':
                displayColor = Colors.orange[100]!;
                break;
              case 'yellow':
                displayColor = Colors.yellow[100]!;
                break;
              case 'green':
                displayColor = Colors.green[100]!;
                break;
              case 'teal':
                displayColor = Colors.teal[100]!;
                break;
              case 'blue':
                displayColor = Colors.blue[100]!;
                break;
              case 'purple':
                displayColor = Colors.purple[100]!;
                break;
              case 'pink':
                displayColor = Colors.pink[100]!;
                break;
              case 'gray':
                displayColor = Colors.grey[200]!;
                break;
            }

            return InkWell(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _noteColor = entry.value;
                  _isDirty = true;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: displayColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _noteColor == entry.value
                    ? const Icon(Icons.check, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    if (_existingNote == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(notesControllerProvider.notifier)
                  .deleteNote(_existingNote!.id);
              if (mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/notes');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create a background color based on the note color
    Color? backgroundColor;
    Color? appBarColor;
    if (_noteColor != null) {
      switch (_noteColor) {
        case 'red':
          backgroundColor = Colors.red[50];
          appBarColor = Colors.red[100];
          break;
        case 'orange':
          backgroundColor = Colors.orange[50];
          appBarColor = Colors.orange[100];
          break;
        case 'yellow':
          backgroundColor = Colors.yellow[50];
          appBarColor = Colors.yellow[100];
          break;
        case 'green':
          backgroundColor = Colors.green[50];
          appBarColor = Colors.green[100];
          break;
        case 'teal':
          backgroundColor = Colors.teal[50];
          appBarColor = Colors.teal[100];
          break;
        case 'blue':
          backgroundColor = Colors.blue[50];
          appBarColor = Colors.blue[100];
          break;
        case 'purple':
          backgroundColor = Colors.purple[50];
          appBarColor = Colors.purple[100];
          break;
        case 'pink':
          backgroundColor = Colors.pink[50];
          appBarColor = Colors.pink[100];
          break;
        case 'gray':
          backgroundColor = Colors.grey[100];
          appBarColor = Colors.grey[200];
          break;
      }
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor ?? Colors.white,
        appBar: AppBar(
          title: Text(
            _existingNote != null ? 'Edit Note' : 'New Note',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          backgroundColor: appBarColor ?? theme.scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            // Pin/Unpin
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _isDirty = true;
                });
              },
              tooltip: _isPinned ? 'Unpin' : 'Pin',
            ),

            // Color picker
            IconButton(
              icon: const Icon(
                Icons.color_lens_outlined,
                size: 22,
              ),
              onPressed: _showColorPicker,
              tooltip: 'Change color',
            ),

            // Tags
            IconButton(
              icon: const Icon(
                Icons.label_outline,
                size: 22,
              ),
              onPressed: _showTagsEditor,
              tooltip: 'Edit tags',
            ),

            // Delete (only for existing notes)
            if (_existingNote != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 22,
                ),
                onPressed: _confirmDelete,
                tooltip: 'Delete',
              ),

            // Save
            IconButton(
              icon: const Icon(
                Icons.save_outlined,
                size: 22,
              ),
              onPressed: () => _saveNote(popWhenDone: true),
              tooltip: 'Save',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Tags display
                  if (_tags.isNotEmpty)
                    Container(
                      margin:
                          const EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.08),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            deleteIcon: Icon(
                              Icons.close,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            onDeleted: () {
                              setState(() {
                                _tags.remove(tag);
                                _isDirty = true;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  // Title field
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 16),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: theme.hintColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        height: 1.3,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  // Rich text editor
                  Expanded(
                    child: RichTextEditor(
                      initialContent: _content,
                      onContentChanged: _onEditorContentChanged,
                      readOnly: false,
                    ),
                  ),

                  // Auto-save indicator - very subtle
                  if (_isSaving)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
