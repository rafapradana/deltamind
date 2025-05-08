import 'dart:math';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/models/flashcard.dart';
import 'package:deltamind/services/flashcard_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// FlashcardViewerPage for studying flashcards
class FlashcardViewerPage extends StatefulWidget {
  /// The flashcard deck ID
  final String deckId;

  /// Creates a FlashcardViewerPage
  const FlashcardViewerPage({
    Key? key,
    required this.deckId,
  }) : super(key: key);

  @override
  State<FlashcardViewerPage> createState() => _FlashcardViewerPageState();
}

class _FlashcardViewerPageState extends State<FlashcardViewerPage> {
  late Future<FlashcardDeck> _deckFuture;
  late Future<List<Flashcard>> _flashcardsFuture;

  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  bool _showHint = false;
  List<Flashcard> _flashcards = [];
  Set<int> _completedCards = {};
  FlashcardDeck? _deck;
  String? _errorMessage;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _deckFuture = FlashcardService.getDeckById(widget.deckId);
      _flashcardsFuture = FlashcardService.getFlashcardsForDeck(widget.deckId);

      _deck = await _deckFuture;
      _flashcards = await _flashcardsFuture;

      // Shuffle the flashcards for better learning
      _flashcards.shuffle(Random());

      setState(() {
        _isLoading = false;
        _currentIndex = 0;
        _isFlipped = false;
        _showHint = false;
        _completedCards = {};
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading flashcards: $e';
      });
    }
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      // Mark the current card as completed if it was flipped
      if (_isFlipped) {
        _completedCards.add(_currentIndex);
      }

      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _showHint = false;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_flashcards.isNotEmpty) {
      // Complete the last card if it was flipped
      if (_isFlipped) {
        _completedCards.add(_currentIndex);
      }

      // Show completion dialog if all cards were viewed
      if (_completedCards.length == _flashcards.length) {
        _showCompletionDialog();
      }
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _showHint = false;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
      _showHint = false;
    });
  }

  void _resetDeck() {
    setState(() {
      _flashcards.shuffle(Random());
      _currentIndex = 0;
      _isFlipped = false;
      _showHint = false;
      _completedCards.clear();
    });
    _pageController.jumpToPage(0);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great job!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsFill.trophy,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve completed all ${_flashcards.length} flashcards in this deck!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to deck details
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetDeck();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Study Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _deck?.title ?? 'Flashcards',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _isLoading ? null : _resetDeck,
            tooltip: 'Shuffle Cards',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.warning,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_flashcards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.stackSimple,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No flashcards in this deck',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add some flashcards to start studying',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),

        // Hint button (if applicable)
        if (_flashcards[_currentIndex].hint != null &&
            _flashcards[_currentIndex].hint!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _toggleHint,
                icon: Icon(
                  _showHint
                      ? PhosphorIconsRegular.lightbulbFilament
                      : PhosphorIconsRegular.lightbulb,
                  size: 16,
                  color: Colors.amber[700],
                ),
                label: Text(
                  _showHint ? 'Hide Hint' : 'Show Hint',
                  style: TextStyle(
                    color: Colors.amber[700],
                  ),
                ),
              ),
            ),
          ),

        // Flashcard
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0) {
                  // Swipe right - previous card
                  _previousCard();
                } else {
                  // Swipe left - next card
                  _nextCard();
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _flashcards.length,
              onPageChanged: _onPageChanged,
              physics: const PageScrollPhysics(),
              itemBuilder: (context, index) {
                final flashcard = _flashcards[index];
                return _buildFlashcard(flashcard);
              },
            ),
          ),
        ),

        // Navigation controls
        _buildNavigationControls(),
      ],
    );
  }

  Widget _buildFlashcard(Flashcard flashcard) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(
            begin: _isFlipped ? 0 : 180,
            end: _isFlipped ? 180 : 0,
          ),
          duration: const Duration(milliseconds: 300),
          builder: (BuildContext context, double value, Widget? child) {
            // Calculate the percentage of the animation
            var percentage = value / 180;

            // Determine which side to show based on the animation progress
            final showFront = percentage < 0.5;

            // This fixes the upside-down text issue
            final frontOpacity = percentage < 0.5 ? 1.0 : 0.0;
            final backOpacity = percentage >= 0.5 ? 1.0 : 0.0;

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Stack(
                children: [
                  // Front card
                  Opacity(
                    opacity: frontOpacity,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective
                        ..rotateY(value * pi / 180),
                      alignment: Alignment.center,
                      child: _buildCardSide(
                        color: Colors.white,
                        iconColor: Colors.blue.shade700,
                        icon: PhosphorIconsFill.question,
                        title: 'Question',
                        content: flashcard.question,
                        hint: _showHint ? flashcard.hint : null,
                      ),
                    ),
                  ),

                  // Back card
                  Opacity(
                    opacity: backOpacity,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective
                        ..rotateY((value - 180) * pi / 180), // Offset by 180
                      alignment: Alignment.center,
                      child: _buildCardSide(
                        color: Colors.blue.shade50,
                        iconColor: Colors.green.shade700,
                        icon: PhosphorIconsFill.check,
                        title: 'Answer',
                        content: flashcard.answer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build a card side
  Widget _buildCardSide({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String content,
    String? hint,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon to indicate which side
            Icon(
              icon,
              size: 36,
              color: iconColor,
            ),
            const SizedBox(height: 16),

            // Card content
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Hint
            if (hint != null && hint.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsFill.lightbulb,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hint',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Navigation controls updated to prevent overflow
  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentIndex > 0 ? _previousCard : null,
            icon: Icon(
              PhosphorIconsRegular.caretLeft,
              size: 28,
              color: _currentIndex > 0 ? AppColors.primary : Colors.grey[400],
            ),
            tooltip: 'Previous Card',
          ),
          Flexible(
            child: OutlinedButton.icon(
              onPressed: _toggleFlip,
              icon: Icon(
                PhosphorIconsRegular.arrowsClockwise,
                size: 18,
              ),
              label: Text(
                _isFlipped ? 'Show Question' : 'Show Answer',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed:
                _currentIndex < _flashcards.length - 1 ? _nextCard : null,
            icon: Icon(
              PhosphorIconsRegular.caretRight,
              size: 28,
              color: _currentIndex < _flashcards.length - 1
                  ? AppColors.primary
                  : Colors.grey[400],
            ),
            tooltip: 'Next Card',
          ),
        ],
      ),
    );
  }

  // Progress indicator with fixed layout
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _flashcards.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${_currentIndex + 1} of ${_flashcards.length}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Completed: ${_completedCards.length}/${_flashcards.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
