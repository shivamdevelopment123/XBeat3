import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeText extends StatelessWidget {

  final String text;
  final TextStyle? style;
  final Duration pauseAfterRound;
  final double velocity;
  final double blankSpace;
  final double startPadding;
  final Duration accelDuration;
  final Duration decelDuration;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.pauseAfterRound = const Duration(seconds: 60),
    this.velocity = 40.0,
    this.blankSpace = 50.0,
    this.startPadding = 10.0,
    this.accelDuration = const Duration(seconds: 1),
    this.decelDuration = const Duration(seconds: 1),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 16) * 1.2,
      child: Marquee(
        text: text,
        style: style ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        blankSpace: blankSpace,
        velocity: velocity,
        pauseAfterRound: pauseAfterRound,
        startPadding: startPadding,
        accelerationDuration: accelDuration,
        decelerationDuration: decelDuration,
      ),
    );
  }
}
