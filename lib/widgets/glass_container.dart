import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;

  const GlassContainer({
    Key? key,
    required this.child,
    this.radius = 20.0,
    this.padding = const EdgeInsets.all(16.0),
    this.opacity = 0.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // For true glassmorphism, BackdropFilter is usually here, but avoiding it on list items for performance.
        // It's manually applied where needed in the design later.
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
