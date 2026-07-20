import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthStateSuccess extends AuthState {
  @override
  List<Object?> get props => [];
}

class LoginStateSuccess extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthStateCodeSuccess extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthStateInvalidCode extends AuthState {
  const AuthStateInvalidCode();

  @override
  List<Object?> get props => [];
}

class AuthStateError extends AuthState {
  final List<String> list;
  final bool isExit;
  const AuthStateError(this.list, {this.isExit = false});

  @override
  List<Object?> get props => [list];
}

class AuthAuthenticated extends AuthState {
  @override
  List<Object?> get props => [];
}

// auth_state.dart
class RegistrationPendingCode extends AuthState {
  final String username;
  final String password;
  final String phone;
  final String? email;
  const RegistrationPendingCode({
    required this.username,
    required this.password,
    required this.phone,
    this.email,
  });

  @override
  List<Object?> get props => [username, password, phone, email];
}
