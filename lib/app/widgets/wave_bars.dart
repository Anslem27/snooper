import 'dart:math';

import 'package:flutter/material.dart';

class WaveBars extends StatefulWidget {
  final Color color;

  const WaveBars({
    super.key,
    required this.color,
  });

  @override
  State<WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<WaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  double _getWaveHeight(int index) {
    final phase = index * 0.25;
    final t = (_waveController.value + phase) % 1.0;
    return 0.5 * (1 + sin(2 * pi * t));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3,
                height: 10 + 20 * _getWaveHeight(i),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      },
    );
  }
}
