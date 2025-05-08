import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/models/flashcard.dart';
import 'package:deltamind/services/flashcard_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// FlashcardDeckDetailPage shows flashcard deck details and allows editing
class FlashcardDeckDetailPage extends StatefulWidget {
  /// The flashcard deck ID
  final String deckId;

  /// Creates a FlashcardDeckDetailPage
  const FlashcardDeckDetailPage({
    Key? key,
    required this.deckId,
  }) : super(key: key);

  @override
  State<FlashcardDeckDetailPage> createState() =>
      _FlashcardDeckDetailPageState();
}

class _FlashcardDeckDetailPageState extends State<FlashcardDeckDetailPage> {
  late Future<FlashcardDeck> _deckFuture;
  late Future<List<Flashcard>> _flashcardsFuture;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadData() {
    _deckFuture = FlashcardService.getDeckById(widget.deckId);
    _flashcardsFuture = FlashcardService.getFlashcardsForDeck(widget.deckId);

    // Initialize the text controllers when the deck loads
    _deckFuture.then((deck) {
      _titleController.text = deck.title;
      _descriptionController.text = deck.description ?? '';
    }).catchError((e) {
      setState(() {
        _errorMessage = 'Error loading deck: $e';
      });
    });
  }

  Future<void> _deleteDeck() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: const Text(
          'Are you sure you want to delete this deck? '
          'This will delete all flashcards in the deck and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FlashcardService.deleteDeck(widget.deckId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard deck deleted'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/flashcards');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error deleting deck: $e';
        });
      }
    }
  }

  Future<void> _updateDeck() async {
    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Title cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FlashcardService.updateDeck(
        deckId: widget.deckId,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      // Reload data
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error updating deck: $e';
      });
    }
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard'),
        content: const Text(
          'Are you sure you want to delete this flashcard? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FlashcardService.deleteFlashcard(flashcard.id);

        // Reload flashcards
        setState(() {
          _flashcardsFuture =
              FlashcardService.getFlashcardsForDeck(widget.deckId);
          _deckFuture = FlashcardService.getDeckById(widget.deckId);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error deleting flashcard: $e';
        });
      }
    }
  }

  Future<void> _editFlashcard(Flashcard flashcard) async {
    final questionController = TextEditingController(text: flashcard.question);
    final answerController = TextEditingController(text: flashcard.answer);
    final hintController = TextEditingController(text: flashcard.hint ?? '');

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Front of the flashcard',
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  hintText: 'Back of the flashcard',
                ),
                maxLines: 5,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: 'Hint (Optional)',
                  hintText: 'Optional hint to help recall',
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (questionController.text.isEmpty ||
                  answerController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Question and answer cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop({
                'question': questionController.text,
                'answer': answerController.text,
                'hint': hintController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FlashcardService.updateFlashcard(
          flashcardId: flashcard.id,
          question: result['question'],
          answer: result['answer'],
          hint: result['hint']!.isNotEmpty ? result['hint'] : null,
        );

        // Reload flashcards
        setState(() {
          _flashcardsFuture =
              FlashcardService.getFlashcardsForDeck(widget.deckId);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error updating flashcard: $e';
        });
      }
    }
  }

  Future<void> _addFlashcard() async {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final hintController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Front of the flashcard',
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  hintText: 'Back of the flashcard',
                ),
                maxLines: 5,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: 'Hint (Optional)',
                  hintText: 'Optional hint to help recall',
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (questionController.text.isEmpty ||
                  answerController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Question and answer cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop({
                'question': questionController.text,
                'answer': answerController.text,
                'hint': hintController.text,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FlashcardService.createFlashcard(
          deckId: widget.deckId,
          question: result['question']!,
          answer: result['answer']!,
          hint: result['hint']!.isNotEmpty ? result['hint'] : null,
        );

        // Reload flashcards
        setState(() {
          _flashcardsFuture =
              FlashcardService.getFlashcardsForDeck(widget.deckId);
          _deckFuture = FlashcardService.getDeckById(widget.deckId);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard added'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error adding flashcard: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Deck'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(PhosphorIconsRegular.pencilSimple),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Deck',
            ),
            IconButton(
              icon: Icon(PhosphorIconsRegular.trash),
              onPressed: _deleteDeck,
              tooltip: 'Delete Deck',
            ),
          ] else ...[
            IconButton(
              icon: Icon(PhosphorIconsRegular.checkCircle),
              onPressed: _updateDeck,
              tooltip: 'Save Changes',
            ),
            IconButton(
              icon: Icon(PhosphorIconsRegular.x),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset controllers
                  _deckFuture.then((deck) {
                    _titleController.text = deck.title;
                    _descriptionController.text = deck.description ?? '';
                  });
                });
              },
              tooltip: 'Cancel Editing',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _loadData();
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
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
                    _buildDeckInfo(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Flashcards',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context
                                  .push('/flashcards/${widget.deckId}/view'),
                              icon: Icon(PhosphorIconsRegular.play,
                                  size: 18, color: AppColors.primary),
                              label: const Text('Study'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addFlashcard,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFlashcardsList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: !_isEditing && !_isLoading
          ? FloatingActionButton(
              onPressed: () =>
                  context.push('/flashcards/${widget.deckId}/view'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.play_arrow, color: Colors.white),
              tooltip: 'Study Now',
            )
          : null,
    );
  }

  Widget _buildDeckInfo() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Deck Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      );
    }

    return FutureBuilder<FlashcardDeck>(
      future: _deckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(
            'Error loading deck: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData) {
          return const Text('Deck not found');
        }

        final deck = snapshot.data!;
        return Hero(
          tag: 'deck-${deck.id}',
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (deck.description != null &&
                      deck.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      deck.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsRegular.cards,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${deck.cardCount} cards',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (deck.sourceName != null &&
                          deck.sourceName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            deck.sourceName!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashcardsList() {
    return FutureBuilder<List<Flashcard>>(
      future: _flashcardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Error loading flashcards: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    PhosphorIconsRegular.stackSimple,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No flashcards in this deck',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add some flashcards to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addFlashcard,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Flashcard'),
                  ),
                ],
              ),
            ),
          );
        }

        final flashcards = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flashcards.length,
          itemBuilder: (context, index) {
            final flashcard = flashcards[index];
            return _buildFlashcardItem(flashcard, index);
          },
        );
      },
    );
  }

  Widget _buildFlashcardItem(Flashcard flashcard, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flashcard.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.check,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Answer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              flashcard.answer,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (flashcard.hint != null &&
                          flashcard.hint!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIconsRegular.lightbulb,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hint',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      flashcard.hint!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editFlashcard(flashcard),
                  icon: Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteFlashcard(flashcard),
                  icon: Icon(PhosphorIconsRegular.trash, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
