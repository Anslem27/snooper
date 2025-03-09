import 'package:flutter/material.dart';

class AnimatedSizeAndFade extends StatelessWidget {
  final Widget child;
  final bool show;

  const AnimatedSizeAndFade({
    super.key,
    required this.child,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: child,
      secondChild: const SizedBox(height: 0, width: double.infinity),
      crossFadeState:
          show ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeInOut,
    );
  }
}
