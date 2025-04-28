import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/reviews/card_review_page.dart';
import 'package:deltamind/services/spaced_repetition_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reviews page
class ReviewsPage extends ConsumerStatefulWidget {
  const ReviewsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<dynamic> _dueCards = [];

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  /// Load review data
  Future<void> _loadReviewData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get spaced repetition statistics
      _stats = await SpacedRepetitionService.getStatistics();
      
      // Get due cards
      _dueCards = await SpacedRepetitionService.getDueCards();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading review data: $e';
      });
      debugPrint('Error loading review data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReviewData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildContent(),
    );
  }

  /// Build content
  Widget _buildContent() {
    final dueToday = _stats['dueToday'] ?? 0;
    
    return RefreshIndicator(
      onRefresh: _loadReviewData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spaced Repetition Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total Cards',
                          (_stats['totalCards'] ?? 0).toString(),
                          Icons.layers,
                          AppColors.primary,
                        ),
                        _buildStatItem(
                          'Due Today',
                          dueToday.toString(),
                          Icons.calendar_today,
                          AppColors.secondary,
                        ),
                        _buildStatItem(
                          'Mastered',
                          (_stats['mastered'] ?? 0).toString(),
                          Icons.check_circle,
                          AppColors.gray,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Due cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cards Due Today',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_dueCards.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _startReview,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Review'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_dueCards.isEmpty)
              _buildEmptyState()
            else
              _buildDueCardsList(),
          ],
        ),
      ),
    );
  }

  /// Build statistic item
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No cards due for review today.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build due cards list
  Widget _buildDueCardsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dueCards.length,
      itemBuilder: (context, index) {
        final card = _dueCards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.quiz, color: AppColors.primary),
            ),
            title: Text(
              card['question'] ?? 'Unknown Question',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('From: ${card['quizTitle'] ?? 'Unknown Quiz'}'),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => _reviewSingleCard(card),
          ),
        );
      },
    );
  }

  /// Start review session with all due cards
  void _startReview() {
    if (_dueCards.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardReviewPage(
          cards: _dueCards,
          onReviewComplete: _loadReviewData,
        ),
      ),
    );
  }
  
  /// Review a single card
  void _reviewSingleCard(Map<String, dynamic> card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardReviewPage(
          cards: [card],
          onReviewComplete: _loadReviewData,
        ),
      ),
    );
  }
} 