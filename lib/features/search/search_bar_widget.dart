import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/search/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Search bar widget that can be added to various screens
class GlobalSearchBar extends ConsumerStatefulWidget {
  /// Constructor
  const GlobalSearchBar({Key? key}) : super(key: key);

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasFocus = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    // Navigate to search page with pre-filled query
    if (_controller.text.trim().isNotEmpty) {
      ref
          .read(searchControllerProvider.notifier)
          .setQuery(_controller.text.trim());
      context.push(AppRoutes.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search notes, quizzes, flashcards...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _controller.clear();
                  });
                },
              )
            : _hasFocus
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _handleSearch,
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        filled: true,
        fillColor: _hasFocus
            ? AppColors.primary.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
      ),
      onChanged: (value) {
        setState(() {});
      },
      onTap: () {
        setState(() {
          _hasFocus = true;
        });
      },
      onSubmitted: (_) => _handleSearch(),
      textInputAction: TextInputAction.search,
    );
  }
}

/// Interactive search bar widget for the search page with live search
class SearchBarInput extends ConsumerStatefulWidget {
  /// Search callback
  final VoidCallback? onSearch;

  /// Autofocus flag
  final bool autofocus;

  /// Constructor
  const SearchBarInput({
    Key? key,
    this.onSearch,
    this.autofocus = true,
  }) : super(key: key);

  @override
  ConsumerState<SearchBarInput> createState() => _SearchBarInputState();
}

class _SearchBarInputState extends ConsumerState<SearchBarInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _debounceActive = false;

  @override
  void initState() {
    super.initState();
    // Initialize the controller safely
    _controller = TextEditingController();

    // Use post-frame callback to safely access provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final searchState = ref.read(searchControllerProvider);
        // Set text after widget is built
        _controller.text = searchState.query;

        // Set initial query in controller if present
        if (searchState.query.isNotEmpty) {
          _performSearch();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (!mounted) return;
    if (_controller.text.trim().isEmpty) return;

    // Update query in controller
    ref
        .read(searchControllerProvider.notifier)
        .setQuery(_controller.text.trim());

    // Perform search
    ref.read(searchControllerProvider.notifier).search();

    // Additional callback if provided
    if (widget.onSearch != null) {
      widget.onSearch!();
    }
  }

  // Debounced search to avoid excessive API calls while typing
  void _debouncedSearch() {
    if (_debounceActive) return;

    _debounceActive = true;

    // Wait a short time before executing search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _performSearch();
        _debounceActive = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        hintText: 'Search notes, quizzes, flashcards...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _controller.clear();
                    ref.read(searchControllerProvider.notifier).setQuery('');
                    // Clear results when clearing the search input
                    ref.read(searchControllerProvider.notifier).clearSearch();
                  });
                  _focusNode.requestFocus();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        filled: true,
        fillColor: AppColors.primary.withOpacity(0.05),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        if (value.trim().isNotEmpty) {
          _debouncedSearch();
        } else if (value.isEmpty) {
          // Clear results when text is completely empty
          ref.read(searchControllerProvider.notifier).clearSearch();
        }
        setState(() {});
      },
      onSubmitted: (_) => _performSearch(),
    );
  }
}
