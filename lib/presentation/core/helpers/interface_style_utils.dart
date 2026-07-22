import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/settings/keklist_interface_style.dart';
import 'package:keklist/presentation/core/helpers/platform_utils.dart';

bool isLiquidGlassAvailableOnThisPlatform() => DeviceUtils.safeGetPlatform() == SupportedPlatform.iOS;

bool resolveUseLiquidGlass(KeklistInterfaceStyle style) =>
    style == KeklistInterfaceStyle.liquidGlass && isLiquidGlassAvailableOnThisPlatform();
