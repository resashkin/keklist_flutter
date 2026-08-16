import 'package:material_ui/material_ui.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

final class LiquidGlassNavigationBar extends StatelessWidget {
  final List<TabType> tabTypes;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const LiquidGlassNavigationBar({
    super.key,
    required this.tabTypes,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<LiquidGlassTabItem> items = tabTypes
        .map(
          (tabType) => LiquidGlassTabItem(
            label: tabType.localizedLabel(context),
            icon: NativeLiquidGlassIcon.sfSymbol(tabType.sfSymbolName),
          ),
        )
        .toList(growable: false);

    return LiquidGlassTabBar(
      key: ValueKey(_itemsSignature),
      items: items,
      currentIndex: selectedIndex,
      onTabSelected: onTap,
      selectedItemColor: colors.primary,
    );
  }

  String get _itemsSignature => tabTypes.map((t) => t.name).join('|');
}
