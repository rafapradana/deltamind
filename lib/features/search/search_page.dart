import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/search/search_bar_widget.dart';
import 'package:deltamind/features/search/search_controller.dart';
import 'package:deltamind/services/search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Search results page
class SearchPage extends ConsumerStatefulWidget {
  /// Constructor
  const SearchPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final hasResults = searchState.filteredResults.isNotEmpty;
    final hasSearched = searchState.hasSearched;
    final isLoading = searchState.isLoading;
    final errorMessage = searchState.error;

    // Ensure we have a SafeArea and properly structured layout
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search'),
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SearchBarInput(
                onSearch: () {},
                key: const ValueKey('search_bar_input'),
              ),
            ),

            // Filters
            if (!isLoading) _buildFilters(),

            // Results or empty state
            Expanded(
              child: _buildResultsContent(
                hasResults: hasResults,
                hasSearched: hasSearched,
                isLoading: isLoading,
                errorMessage: errorMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final searchState = ref.watch(searchControllerProvider);
    final activeFilters = searchState.activeFilters;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterChip(
              label: 'Notes',
              type: SearchResultType.note,
              icon: Icons.note_outlined,
              isActive: activeFilters.contains(SearchResultType.note),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Quizzes',
              type: SearchResultType.quiz,
              icon: Icons.quiz_outlined,
              isActive: activeFilters.contains(SearchResultType.quiz),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Flashcards',
              type: SearchResultType.flashcardDeck,
              icon: Icons.layers_outlined,
              isActive: activeFilters.contains(SearchResultType.flashcardDeck),
            ),
            const SizedBox(width: 8),
            // Reset filters button
            if (searchState.activeFilters.length < 3)
              ActionChip(
                avatar: const Icon(
                  Icons.refresh,
                  size: 16,
                ),
                label: const Text('Reset'),
                backgroundColor: Colors.grey.withOpacity(0.1),
                onPressed: () {
                  ref.read(searchControllerProvider.notifier).resetFilters();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required SearchResultType type,
    required IconData icon,
    required bool isActive,
  }) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isActive ? Colors.white : null,
      ),
      label: Text(label),
      selected: isActive,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : null,
        fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
      ),
      onSelected: (selected) {
        ref.read(searchControllerProvider.notifier).toggleFilter(type);
      },
    );
  }

  Widget _buildResultsContent({
    required bool hasResults,
    required bool hasSearched,
    required bool isLoading,
    String? errorMessage,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'An error occurred',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(searchControllerProvider.notifier).search();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!hasSearched) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search for notes, quizzes, or flashcards',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey.withOpacity(0.8),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Type above to find any content',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!hasResults) {
      final searchState = ref.watch(searchControllerProvider);
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.amber.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term or filters',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (searchState.activeFilters.length < 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(searchControllerProvider.notifier)
                            .resetFilters();
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Reset filters'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final searchState = ref.watch(searchControllerProvider);
    final results = searchState.filteredResults;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultItem(result);
      },
    );
  }

  Widget _buildResultItem(SearchResult result) {
    // Select icon based on result type
    IconData iconData;
    Color iconColor;

    switch (result.type) {
      case SearchResultType.note:
        iconData = Icons.note_outlined;
        iconColor = Colors.blue;
        break;
      case SearchResultType.quiz:
        iconData = Icons.quiz_outlined;
        iconColor = Colors.purple;
        break;
      case SearchResultType.flashcardDeck:
      case SearchResultType.flashcard:
        iconData = Icons.layers_outlined;
        iconColor = Colors.orange;
        break;
    }

    // Format date
    final date = result.updatedAt ?? result.createdAt;
    final formattedDate = date != null ? timeago.format(date) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToResult(result),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Result type
                            Text(
                              _getResultTypeLabel(result.type),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: iconColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (formattedDate.isNotEmpty) ...[
                              Text(
                                ' • ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              // Date
                              Text(
                                formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Preview content if available
              if (result.preview != null && result.preview!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    result.preview!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Additional metadata based on type
              if (result.type == SearchResultType.note &&
                  result.metadata != null &&
                  result.metadata!['tags'] != null &&
                  (result.metadata!['tags'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in result.metadata!['tags'] as List)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getResultTypeLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.note:
        return 'Note';
      case SearchResultType.quiz:
        return 'Quiz';
      case SearchResultType.flashcardDeck:
        return 'Flashcard Deck';
      case SearchResultType.flashcard:
        return 'Flashcard';
    }
  }

  void _navigateToResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.note:
        context.push('/notes/${result.id}');
        break;
      case SearchResultType.quiz:
        // Navigate to quiz detail or take quiz page
        context.push('${AppRoutes.quizList}?selected=${result.id}');
        break;
      case SearchResultType.flashcardDeck:
      case SearchResultType.flashcard:
        // Navigate to flashcard deck detail
        context.push('/flashcards/${result.id}');
        break;
    }
  }
}
