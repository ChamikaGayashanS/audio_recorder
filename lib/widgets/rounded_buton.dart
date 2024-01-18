import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton(
      {super.key,
      required this.icon,
      required this.backgroundColor,
      required this.borderColors,
      required this.onTap,
      this.label,
      required this.radius});
  final Widget icon;
  final Color backgroundColor;
  final Color borderColors;
  final Function onTap;
  final String? label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: radius,
            height: radius,
            decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: borderColors, width: 2)),
            child: icon,
          ),
          const Gap(2),
          SizedBox(
              height: 12,
              child: label != null
                  ? Text(
                      label!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w400),
                    )
                  : const SizedBox())
        ],
      ),
    );
  }
}
