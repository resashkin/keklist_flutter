import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:keklist/presentation/core/helpers/extensions/state_extensions.dart';

final class BlocUtils {
  static StreamSubscription<dynamic> subscribeTo<B extends Bloc>({
    required BuildContext context,
    Function(dynamic)? onState,
  }) => context.read<B>().stream.listen(onState);

  static void sendEventTo<B extends Bloc>({
    required BuildContext? context,
    required Object event,
  }) {
    // 1. Widget tree — works when the State is still mounted.
    if (context != null) {
      context.read<B>().add(event);
      return;
    }

    // 2. DI fallback — works when B is registered as a singleton in MainContainer.
    try {
      Injector().get<B>().add(event);
      return;
    } catch (_) {
      // B not registered in DI — fall through to assert.
    }

    // 3. Both failed — shout in debug, silent no-op in release.
    assert(() {
      debugPrint(
        'sendEventTo<$B>: context unmounted AND $B not registered in Injector — event dropped: $event',
      );
      return true;
    }());
  }
}

extension StatebleBlocs on State {
  void sendEventToBloc<B extends Bloc>(Object event) => BlocUtils.sendEventTo<B>(
      context: mountedContext,
      event: event,
    );

  StreamSubscription<dynamic>? subscribeToBloc<B extends Bloc>({
    required Function(dynamic) onNewState,
  }) {
    if (mountedContext == null) {
      return null;
    }
    return BlocUtils.subscribeTo<B>(
      context: mountedContext!,
      onState: onNewState,
    );
  }
}
