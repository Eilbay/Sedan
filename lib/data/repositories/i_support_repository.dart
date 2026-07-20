import 'package:optombai/data/models/support/support_session_model.dart';

abstract interface class ISupportRepository {
  Future<SupportSession?> getActiveSession(String token);

  Future<SupportSession> startSupportSession({
    required String text,
    required String token,
  });

  Future<SupportSession> closeSession({
    required String sessionId,
    required String comment,
    required String token,
  });
}
