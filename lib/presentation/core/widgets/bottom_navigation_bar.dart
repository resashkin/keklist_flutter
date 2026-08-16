import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/core/widgets/liquid_glass_navigation_bar.dart';

final class AdaptiveBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final List<TabType>? tabTypes;
  final bool useLiquidGlass;

  const AdaptiveBottomNavigationBar({
    super.key,
    required this.onTap,
    required this.selectedIndex,
    required this.items,
    this.tabTypes,
    this.useLiquidGlass = false,
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
      if (useLiquidGlass && tabTypes != null) {
        return LiquidGlassNavigationBar(
          tabTypes: tabTypes!,
          selectedIndex: selectedIndex,
          onTap: onTap,
        );
      }
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
