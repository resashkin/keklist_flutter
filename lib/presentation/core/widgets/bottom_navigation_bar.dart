import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class AdaptiveBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const AdaptiveBottomNavigationBar({
    super.key,
    required this.onTap,
    required this.selectedIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || Platform.isAndroid) {
      final ColorScheme colors = Theme.of(context).colorScheme;
      return BottomNavigationBar(
        items: items,
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurface.withValues(alpha: 0.4),
        onTap: onTap,
      );
    } else if (Platform.isIOS) {
      return CupertinoTabBar(
        items: items,
        currentIndex: selectedIndex,
        onTap: onTap,
      );
    } else {
      return BottomNavigationBar(
        items: items,
        currentIndex: selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 132, 127, 127),
        type: BottomNavigationBarType.fixed,
        onTap: onTap,
      );
    }
  }
}
