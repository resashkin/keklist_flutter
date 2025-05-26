import 'package:flutter/material.dart';

final class BoolWidget extends StatelessWidget {
  final bool condition;
  final Widget trueChild;
  final Widget falseChild;

  const BoolWidget({
    super.key,
    required this.condition,
    required this.trueChild,
    required this.falseChild,
  });

  @override
  Widget build(BuildContext context) => condition ? trueChild : falseChild;
}
