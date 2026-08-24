import 'package:flutter/material.dart';

class ResponsiveFormGrid extends StatelessWidget {
  final List<Widget> children;

  final double spacing;
  final double runSpacing;

  final int largeColumns;
  final int mediumColumns;
  final int smallColumns;

  final double mediumBreakpoint;
  final double smallBreakpoint;

  const ResponsiveFormGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.largeColumns = 4,
    this.mediumColumns = 2,
    this.smallColumns = 1,
    this.mediumBreakpoint = 1000,
    this.smallBreakpoint = 650,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final int columns;

        if (width < smallBreakpoint) {
          columns = smallColumns;
        } else if (width < mediumBreakpoint) {
          columns = mediumColumns;
        } else {
          columns = largeColumns;
        }

        final availableWidth = width - (spacing * (columns - 1));

        final itemWidth = availableWidth / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}
