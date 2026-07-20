import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/block/block_model.dart';
import 'package:optombai/data/repositories/i_block_repository.dart';

class BlockRepository implements IBlockRepository {
  final Dio _dio = ApiClient.I.dio;

  static String get _baseUrl => '${ApiEndpoints.baseApi}/blocks/';

  @override
  Future<BlockModel> blockUser({
    required String userId,
    String? reason,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: {
          'user_id': userId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
        options: optionsNoCache(token),
      );
      return BlockModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> unblockUser({
    required String userId,
    required String token,
  }) async {
    try {
      await _dio.delete('$_baseUrl$userId/', options: optionsNoCache(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<BlockListModel> fetchBlocks({
    required String token,
    int? page,
    int? pageSize,
    String? nextUrl,
  }) async {
    try {
      final response = await _dio.get(
        nextUrl ?? _baseUrl,
        queryParameters: nextUrl != null
            ? null
            : {
                if (page != null) 'page': page,
                if (pageSize != null) 'page_size': pageSize,
              },
        options: options(token),
      );
      return BlockListModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
