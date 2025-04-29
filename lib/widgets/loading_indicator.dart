import 'package:flutter/material.dart';

/// A loading indicator widget that displays a centered circular progress indicator.
/// Used throughout the app to indicate loading states.
class LoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator with optional size and color parameters.
  const LoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  /// The size of the loading indicator.
  final double size;

  /// The color of the loading indicator. If null, uses the theme's primary color.
  final Color? color;

  /// The stroke width of the circular progress indicator.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
