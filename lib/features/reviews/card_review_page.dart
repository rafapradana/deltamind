import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/services/spaced_repetition_service.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Page for reviewing flashcards
class CardReviewPage extends StatefulWidget {
  /// List of cards to review
  final List<dynamic> cards;
  
  /// Callback when review is complete
  final VoidCallback onReviewComplete;

  /// Constructor
  const CardReviewPage({
    required this.cards,
    required this.onReviewComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<CardReviewPage> createState() => _CardReviewPageState();
}

class _CardReviewPageState extends State<CardReviewPage> {
  int _currentCardIndex = 0;
  bool _isFlipped = false;
  bool _isAnswering = false;
  bool _isSubmitting = false;
  
  /// Get current card
  Map<String, dynamic> get _currentCard => widget.cards[_currentCardIndex];
  
  /// Get card progress
  double get _progress => ((_currentCardIndex + 1) / widget.cards.length);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Review'),
        actions: [
          TextButton(
            onPressed: () => _showExitConfirmation(),
            child: const Text('Finish'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          
          // Card counter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Card ${_currentCardIndex + 1} of ${widget.cards.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          
          // Flashcard
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _isAnswering ? null : _flipCard,
                child: _buildFlashcard(),
              ),
            ),
          ),
          
          // Rating or Next buttons
          _isFlipped && !_isAnswering
            ? _buildFlipPrompt()
            : _isAnswering 
              ? _buildRatingButtons()
              : const SizedBox.shrink(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /// Build the flashcard
  Widget _buildFlashcard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: 3.14, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isBack = ValueKey(_isFlipped) != child?.key;
              final value = isBack ? 3.14 - rotateAnim.value : rotateAnim.value;
              return Transform(
                transform: Matrix4.rotationY(value),
                alignment: Alignment.center,
                child: value < 1.57 ? child : Container(),
              );
            },
          );
        },
        child: _isFlipped
            ? _buildBackCard() // Answer side
            : _buildFrontCard(), // Question side
      ),
    );
  }
  
  /// Build the front of the card (question)
  Widget _buildFrontCard() {
    return Container(
      key: const ValueKey(false),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'From ${_currentCard['quizTitle'] ?? ''}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentCard['question'] ?? 'No question text',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Tap to see answer',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const Icon(Icons.touch_app, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  /// Build the back of the card (answer)
  Widget _buildBackCard() {
    final options = _currentCard['options'] as List<dynamic>;
    final correctAnswer = _currentCard['correctAnswer'] as String;
    final explanation = _currentCard['explanation'] as String?;
    
    return Container(
      key: const ValueKey(true),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green[700],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Question:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentCard['question'] ?? 'No question text',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Correct Answer:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      correctAnswer,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All Options:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...options.map((option) {
              final isCorrect = option == correctAnswer;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? Colors.green.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    isCorrect
                        ? Icon(Icons.check_circle, color: Colors.green[700], size: 16)
                        : Icon(Icons.circle_outlined, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.toString(),
                        style: TextStyle(
                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (explanation != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Explanation:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Text(explanation),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build the prompt to show after flipping the card
  Widget _buildFlipPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            'How well did you remember this?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setAnsweringMode(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Need to Review'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setAnsweringMode(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Knew It'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build the rating buttons
  Widget _buildRatingButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            'Rate how well you knew this:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRatingButton(1, 'Forgot'),
                    _buildRatingButton(3, 'Hard'),
                    _buildRatingButton(4, 'Good'),
                    _buildRatingButton(5, 'Easy'),
                  ],
                ),
        ],
      ),
    );
  }
  
  /// Build a single rating button
  Widget _buildRatingButton(int quality, String label) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green,
    ];
    
    final color = quality <= colors.length ? colors[quality - 1] : Colors.blue;
    
    return ElevatedButton(
      onPressed: () => _submitRating(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Text(label),
    );
  }
  
  /// Flip the card
  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }
  
  /// Set whether we're in answering mode
  void _setAnsweringMode(bool value) {
    setState(() {
      _isAnswering = value;
    });
  }
  
  /// Submit rating for the current card
  Future<void> _submitRating(int quality) async {
    try {
      setState(() {
        _isSubmitting = true;
      });
      
      // Update spaced repetition for this card
      await SpacedRepetitionService.updateAfterReview(
        _currentCard['questionId'],
        quality,
      );
      
      // Move to next card or finish
      setState(() {
        _isSubmitting = false;
        _isFlipped = false;
        _isAnswering = false;
        
        if (_currentCardIndex < widget.cards.length - 1) {
          _currentCardIndex++;
        } else {
          _finishReview();
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating review: $e')),
      );
    }
  }
  
  /// Show exit confirmation dialog
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Review'),
        content: const Text(
          'Are you sure you want to finish this review session? '
          'Your progress will be saved.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishReview();
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
  
  /// Finish the review
  void _finishReview() {
    widget.onReviewComplete();
    Navigator.pop(context);
    
    // Show congratulations dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: Colors.amber[700],
            ),
            const SizedBox(height: 16),
            const Text(
              'Congratulations on completing your review session! '
              'Keep up the good work to improve your learning.'
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 