import 'package:dio/dio.dart';
import 'package:optombai/data/models/pmt/pmt_model.dart';

abstract interface class IPmtRepository {
  Future<List<PmtModel>> getPmtHistory(String token);

  Future<PmtModel> createPmt(PmtModel pmt, String token);

  Future<PmtModel> patchPmtStatus(String pmtId, String token);

  Future<Response?> getPmtStatus(String token);

  Future<PmtModel> updatePmtStatus(String pmtId, String status, String amount,
      String pmtMethod, String token);

  Future<void> updateUserStatus(
      String pmtId, String premiumId, String token);

  Future<PmtModel> getPmtById(String pmtId, String token);

  String getPmtRedirectUrl(String pmtId);
}
