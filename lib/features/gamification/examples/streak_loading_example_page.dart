import 'package:flutter/material.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/widgets/loading_indicator.dart';
import 'package:deltamind/features/gamification/widgets/streak_loading_widget.dart';
import 'package:deltamind/features/gamification/widgets/streak_data_card_fixed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Example page demonstrating how to use the LoadingIndicator widget
class StreakLoadingExamplePage extends ConsumerStatefulWidget {
  const StreakLoadingExamplePage({Key? key}) : super(key: key);

  @override
  ConsumerState<StreakLoadingExamplePage> createState() =>
      _StreakLoadingExamplePageState();
}

class _StreakLoadingExamplePageState
    extends ConsumerState<StreakLoadingExamplePage> {
  bool _isStreakLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isStreakLoading = false;
        });
      }
    });
  }

  void _toggleLoading() {
    setState(() {
      _isStreakLoading = !_isStreakLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Examples'),
        actions: [
          IconButton(
            icon: Icon(
              _isStreakLoading ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleLoading,
            tooltip: 'Toggle Loading State',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              'Direct LoadingIndicator Usage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Basic usage examples
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Examples',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Default size and color
                        LoadingIndicator(),

                        // Custom size
                        LoadingIndicator(size: 40),

                        // Custom color
                        LoadingIndicator(size: 32, color: AppColors.primary),

                        // Custom stroke width
                        LoadingIndicator(
                          size: 32,
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Section for StreakLoadingWidget
            Text(
              'StreakLoadingWidget Examples',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // StreakLoadingWidget examples
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'With Text Examples',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const StreakLoadingWidget(
                      loadingText: 'Loading streak data...',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 32),
                    const StreakLoadingWidget(
                      loadingText: 'Updating streak freeze...',
                      color: Colors.blue,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Section for StreakDataCard
            Text(
              'Streak Data Card Example',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // StreakDataCard example
            StreakDataCardFixed(
              isLoading: _isStreakLoading,
              currentStreak: 7,
              bestStreak: 14,
              onRefresh: _toggleLoading,
            ),

            const SizedBox(height: 32),

            // Import example
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Import',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "import 'package:deltamind/widgets/loading_indicator.dart';",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Then you can use the LoadingIndicator widget directly in your UI.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
