import 'package:material_ui/material_ui.dart';

extension MountedContext on State {

  BuildContext? get mountedContext {
    if (!mounted) {
      return null;
    }
    return context;
  }
}

extension MountedContextInContext on BuildContext {

  BuildContext? get mountedContext {
    if (!mounted) {
      return null;
    }
    return this;
  }
}