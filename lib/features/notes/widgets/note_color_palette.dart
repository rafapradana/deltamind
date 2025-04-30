import 'package:flutter/material.dart';

/// Note color palette widget for selecting note color
class NoteColorPalette extends StatelessWidget {
  /// Currently selected color
  final String? selectedColor;

  /// Callback when a color is selected
  final Function(String?) onColorSelected;

  /// Creates a new note color palette
  const NoteColorPalette({
    Key? key,
    this.selectedColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Google Keep palette colors
    final colors = [
      {'name': 'Default', 'color': null},
      {'name': 'Red', 'color': '#f28b82'},
      {'name': 'Orange', 'color': '#fbbc04'},
      {'name': 'Yellow', 'color': '#fff475'},
      {'name': 'Green', 'color': '#ccff90'},
      {'name': 'Teal', 'color': '#a7ffeb'},
      {'name': 'Blue', 'color': '#cbf0f8'},
      {'name': 'Dark Blue', 'color': '#aecbfa'},
      {'name': 'Purple', 'color': '#d7aefb'},
      {'name': 'Pink', 'color': '#fdcfe8'},
      {'name': 'Brown', 'color': '#e6c9a8'},
      {'name': 'Gray', 'color': '#e8eaed'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Note color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((colorMap) {
              final colorHex = colorMap['color'] as String?;
              final isSelected = selectedColor == colorHex;

              return _ColorCircle(
                color: colorHex != null
                    ? Color(int.parse('FF${colorHex.substring(1)}', radix: 16))
                    : Colors.white,
                isSelected: isSelected,
                onTap: () => onColorSelected(colorHex),
                isDefault: colorHex == null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Single color circle in the palette
class _ColorCircle extends StatelessWidget {
  /// Color to display
  final Color color;

  /// Whether this color is currently selected
  final bool isSelected;

  /// Whether this is the default (no color) option
  final bool isDefault;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Creates a color circle widget
  const _ColorCircle({
    Key? key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isDefault = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isDefault ? Colors.grey.shade300 : Colors.transparent,
            width: 1,
          ),
          shape: BoxShape.circle,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color:
                    _shouldUseWhiteText(color) ? Colors.white : Colors.black54,
                size: 20,
              )
            : null,
      ),
    );
  }

  // Determine if we should use white or black text on this color
  bool _shouldUseWhiteText(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }
}
