import 'package:flutter/material.dart';

/// A button that shows a loading indicator when loading
class LoadingButton extends StatelessWidget {
  /// The callback that is called when the button is pressed
  final VoidCallback? onPressed;

  /// Whether the button is in loading state
  final bool isLoading;

  /// The child widget to display when not loading
  final Widget child;

  /// Button style
  final ButtonStyle? style;

  /// Creates a loading button
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : child,
    );
  }
} 