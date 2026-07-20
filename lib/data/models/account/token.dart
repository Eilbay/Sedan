import 'package:equatable/equatable.dart';

class Token extends Equatable {
  final String access;
  final String refresh;

  const Token({this.access = "", this.refresh = ""});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'access': access,
      'refresh': refresh,
    };
  }

  factory Token.fromMap(Map<String, dynamic> map) {
    // Defensive parsing: if the backend ever returns an unexpected
    // shape (e.g. SSO/social-auth flow with a different envelope), a
    // direct `map['access']` cast would throw TypeError into the cubit,
    // bypass the `on AppException` catch, and leave the login button
    // spinning forever. Coerce to string with a safe fallback.
    return Token(
      access: (map['access'] ?? '').toString(),
      refresh: (map['refresh'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [access, refresh];
}
