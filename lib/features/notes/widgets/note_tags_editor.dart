import 'package:flutter/material.dart';

/// Widget for editing note tags
class NoteTagsEditor extends StatefulWidget {
  /// Initial tags for the note
  final List<String> initialTags;

  /// Available tags to choose from
  final List<String> availableTags;

  /// Callback when tags are changed
  final Function(List<String>) onTagsChanged;

  /// Constructor
  const NoteTagsEditor({
    Key? key,
    required this.initialTags,
    required this.availableTags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  State<NoteTagsEditor> createState() => _NoteTagsEditorState();
}

class _NoteTagsEditorState extends State<NoteTagsEditor> {
  late List<String> _tags;
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    // Normalize the tag
    final normalizedTag = tag.trim().toLowerCase();

    // Don't add empty tags or duplicates
    if (normalizedTag.isEmpty || _tags.contains(normalizedTag)) {
      _tagController.clear();
      return;
    }

    setState(() {
      _tags.add(normalizedTag);
      _tagController.clear();
    });

    widget.onTagsChanged(_tags);
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });

    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    // Get suggested tags (available tags not already added)
    final suggestedTags =
        widget.availableTags.where((tag) => !_tags.contains(tag)).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Tags',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current tags
            if (_tags.isNotEmpty) ...[
              const Text(
                'Current Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Add new tag
            TextField(
              controller: _tagController,
              focusNode: _tagFocusNode,
              decoration: InputDecoration(
                labelText: 'Add Tag',
                hintText: 'Enter a new tag',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_tagController.text.isNotEmpty) {
                      _addTag(_tagController.text);
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addTag(value);
                  // Keep focus on the field
                  _tagFocusNode.requestFocus();
                }
              },
            ),

            const SizedBox(height: 16),

            // Suggested tags
            if (suggestedTags.isNotEmpty) ...[
              const Text(
                'Suggested Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: suggestedTags.map((tag) {
                  return ActionChip(
                    label: Text(tag),
                    onPressed: () => _addTag(tag),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Done button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
