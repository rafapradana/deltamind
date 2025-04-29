import 'package:flutter/material.dart';
import 'package:deltamind/widgets/loading_indicator.dart';

/// A widget that displays a LoadingIndicator with customizable text and styling.
/// This demonstrates how to properly import and use the LoadingIndicator widget.
class StreakLoadingWidget extends StatelessWidget {
  /// The text to display below the loading indicator
  final String? loadingText;

  /// Whether to show the loading text
  final bool showText;

  /// The size of the loading indicator
  final double size;

  /// The color of the loading indicator (null uses theme primary color)
  final Color? color;

  const StreakLoadingWidget({
    Key? key,
    this.loadingText,
    this.showText = true,
    this.size = 40.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The LoadingIndicator widget is imported from widgets/loading_indicator.dart
          LoadingIndicator(size: size, color: color, strokeWidth: 3.0),

          if (showText && (loadingText != null)) ...[
            const SizedBox(height: 16),
            Text(
              loadingText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
