import 'package:flutter/material.dart';

class ResponsivePage extends StatelessWidget {
  final Widget child;

  const ResponsivePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final double padding;

        if (width < 700) {
          padding = 12;
        } else if (width < 1000) {
          padding = 18;
        } else {
          padding = 28;
        }

        return Padding(padding: EdgeInsets.all(padding), child: child);
      },
    );
  }
}
