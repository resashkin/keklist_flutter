import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/core/helpers/extensions/state_extensions.dart';

final class BlocUtils {
  static StreamSubscription<dynamic> subscribeTo<B extends Bloc>({
    required BuildContext context,
    Function(dynamic)? onState,
  }) => context.read<B>().stream.listen(onState);

  static void sendEventTo<B extends Bloc>({
    required BuildContext? context,
    required Object event,
  }) => context?.read<B>().add(event);
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
