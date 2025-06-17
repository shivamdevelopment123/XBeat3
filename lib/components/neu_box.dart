import 'package:flutter/material.dart';

class NeuBox extends StatelessWidget{
  final Widget? child;
  const NeuBox({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(4, 4),
          ),

          BoxShadow(
            color: Colors.white,
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(-4, -4),)
        ],
      ),
      padding: EdgeInsets.all(12),
    );
  }

}