import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton(
      {super.key,
      required this.icon,
      required this.backgroundColor,
      required this.borderColors,
      required this.onTap,
      required this.radius});
  final Widget icon;
  final Color backgroundColor;
  final Color borderColors;
  final Function onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: borderColors, width: 2)),
        child: icon,
      ),
    );
  }
}
