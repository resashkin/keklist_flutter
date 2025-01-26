part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthLoginWithEmail extends AuthEvent {
  final String email;

  const AuthLoginWithEmail(this.email);
}

final class AuthLoginWithEmailAndPassword extends AuthEvent {
  final String email;
  final String password;

  AuthLoginWithEmailAndPassword({
    required this.email,
    required this.password,
  });
}

final class AuthVerifyOTP extends AuthEvent {
  final String email;
  final String token;

  AuthVerifyOTP({
    required this.email,
    required this.token,
  });
}

class AuthLoginWithSocialNetwork extends AuthEvent {
  final KeklistSupportedSocialNetwork socialNetwork;

  AuthLoginWithSocialNetwork(this.socialNetwork);

  factory AuthLoginWithSocialNetwork.google() => AuthLoginWithSocialNetwork(KeklistSupportedSocialNetwork.google);
  factory AuthLoginWithSocialNetwork.facebook() => AuthLoginWithSocialNetwork(KeklistSupportedSocialNetwork.facebook);
  factory AuthLoginWithSocialNetwork.apple() => AuthLoginWithSocialNetwork(KeklistSupportedSocialNetwork.apple);
}

class AuthLogout extends AuthEvent {}

class AuthDeleteAccount extends AuthEvent {}

class AuthInternalUserAppearedInSession extends AuthEvent {}

class AuthInternalUserGoneFromSession extends AuthEvent {}

class AuthGetStatus extends AuthEvent {}
