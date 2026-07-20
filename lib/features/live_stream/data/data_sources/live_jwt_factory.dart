// live_jwt_factory.dart
import 'dart:developer';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class LiveJwtFactory {
  static const _defaultSecret = '7f5e608f897121a2ba651148d25ce5dabe0118f5';

  final String _secret;

  const LiveJwtFactory({String secret = _defaultSecret}) : _secret = secret;

  int _nowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  String _sign(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(
      SecretKey(_secret),
      algorithm: JWTAlgorithm.HS256,
    );
  }

  String createPublishToken({
    required String userId,
    required String streamId,
  }) {
    log('createPublishToken: userId=$userId, streamId=$streamId');
    final now = _nowSec();
    final payload = <String, dynamic>{
      'sub': userId,
      'stream_id': streamId,
      'scope': 'stream:publish stream:play stream:end stream:chat',
      'iat': now,
      'exp': now + 3600,
    };
    return _sign(payload);
  }

  String createPlayToken({
    required String userId,
    required String streamId,
  }) {
    log('createPlayToken: userId=$userId, streamId=$streamId');
    final now = _nowSec();
    final payload = <String, dynamic>{
      'sub': userId,
      'stream_id': streamId,
      'scope': 'stream:play stream:chat',
      'iat': now,
      'exp': now + 3600,
    };
    return _sign(payload);
  }
}
