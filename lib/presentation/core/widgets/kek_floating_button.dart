import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/core/helpers/interface_style_utils.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

/// Floating action button that follows the debug-menu UI theme: the native
/// Liquid Glass capsule on iOS 26+ when the theme is Liquid Glass, and the
/// Material [FloatingActionButton.extended] everywhere else.
///
/// The Material fallback is mandatory on unsupported platforms —
/// [LiquidGlassButton] renders an empty box there, not a Flutter fallback.
final class KekFloatingButton extends StatelessWidget {
  /// Matches the height of Material's [FloatingActionButton.extended] so the
  /// glass capsule and the Material fallback read as the same size.
  static const double _fabHeight = 56.0;

  final VoidCallback? onPressed;
  final String label;

  /// Icon for the Material fallback button.
  final IconData fallbackIcon;

  /// SF Symbol name for the native glass button (e.g. 'plus', 'arrow.up').
  final String sfSymbol;

  const KekFloatingButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.fallbackIcon,
    required this.sfSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      // Only data states carry the interface style; ignore transient states.
      buildWhen: (_, state) => state is SettingsDataState,
      builder: (context, state) {
        if (_readUseLiquidGlass(state) && NativeLiquidGlassUtils.supportsLiquidGlass) {
          return LiquidGlassButton(
            label: label,
            onPressed: onPressed,
            icon: NativeLiquidGlassIcon.sfSymbol(sfSymbol),
            style: LiquidGlassButtonStyle.glass,
            height: _fabHeight,
            iconSize: 24.0,
            // Must match the package's hardcoded wrap-content estimate (32px total
            // horizontal insets); a wider padding here clips the native label.
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            labelTextStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          );
        }
        return SizedBox(
          height: _fabHeight,
          child: FloatingActionButton.extended(
            onPressed: onPressed,
            icon: Icon(fallbackIcon),
            label: Text(label, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
            enableFeedback: true,
          ),
        );
      },
    );
  }

  bool _readUseLiquidGlass(SettingsState state) {
    if (state is! SettingsDataState) return isLiquidGlassAvailableOnThisPlatform();
    return resolveUseLiquidGlass(state.settings.interfaceStyle);
  }
}
