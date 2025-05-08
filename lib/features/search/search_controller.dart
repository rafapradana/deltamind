import 'package:deltamind/services/search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search controller provider
final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController();
});

/// Search state class
class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;
  final Set<SearchResultType> activeFilters;
  final bool hasSearched;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.activeFilters = const {
      SearchResultType.note,
      SearchResultType.quiz,
      SearchResultType.flashcardDeck,
      SearchResultType.flashcard,
    },
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
    Set<SearchResultType>? activeFilters,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeFilters: activeFilters ?? this.activeFilters,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }

  /// Get filtered results based on active filters
  List<SearchResult> get filteredResults {
    if (results.isEmpty) return [];

    return results
        .where((result) => activeFilters.contains(result.type))
        .toList();
  }
}

/// Controller for managing search operations
class SearchController extends StateNotifier<SearchState> {
  SearchController() : super(const SearchState());

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setQuery(String query) {
    if (_disposed) return;
    state = state.copyWith(query: query);
  }

  void toggleFilter(SearchResultType filter) {
    if (_disposed) return;
    final currentFilters = Set<SearchResultType>.from(state.activeFilters);

    if (currentFilters.contains(filter)) {
      currentFilters.remove(filter);
    } else {
      currentFilters.add(filter);
    }

    state = state.copyWith(activeFilters: currentFilters);
  }

  void resetFilters() {
    if (_disposed) return;
    state = state.copyWith(
      activeFilters: {
        SearchResultType.note,
        SearchResultType.quiz,
        SearchResultType.flashcardDeck,
        SearchResultType.flashcard,
      },
    );
  }

  void clearSearch() {
    if (_disposed) return;
    state = const SearchState();
  }

  Future<void> search({String? query}) async {
    if (_disposed) return;

    final searchQuery = query ?? state.query;
    if (searchQuery.trim().isEmpty) return;

    // Set loading state
    state = state.copyWith(
      isLoading: true,
      error: null,
      query: searchQuery,
    );

    try {
      final results = await SearchService.searchAll(
        searchQuery,
        includeNotes: state.activeFilters.contains(SearchResultType.note),
        includeQuizzes: state.activeFilters.contains(SearchResultType.quiz),
        includeFlashcards:
            state.activeFilters.contains(SearchResultType.flashcardDeck) ||
                state.activeFilters.contains(SearchResultType.flashcard),
      );

      if (_disposed) return;

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
        error: null,
      );
    } catch (e) {
      debugPrint('Error performing search: $e');

      if (_disposed) return;

      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred while searching: ${e.toString()}',
        hasSearched: true,
      );
    }
  }
}
