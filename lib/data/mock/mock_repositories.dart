import 'dart:io';

import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/account/token.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/data/models/account/user/user_status.dart';
import 'package:optombai/data/models/account/user/users_activiti.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/data/models/posts/post_media_v2.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/posts/posts_stats_by_owner.dart';
import 'package:optombai/data/repositories/i_auth_repository.dart';
import 'package:optombai/data/repositories/i_category_repository.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';

const _mockToken =
    Token(access: 'mock-access-token', refresh: 'mock-refresh-token');

UserStatus _mockUserStatus() => const UserStatus(
      id: 1,
      user: 'mock-user',
      isAgree: true,
      isPremium: false,
      isActive: true,
      passwordLastUpdate: '',
      createdAt: '',
    );

User _mockUser([String username = 'Sedan User']) => User(
      id: 'mock-user',
      email: 'mock@sedan.kg',
      username: username,
      description: 'Мок пользователь Sedan.Kg',
      phone_number: '+996000000000',
      userType: 'user',
      is_active: true,
      is_verified: true,
      userStatus: _mockUserStatus(),
      postsCount: 6,
    );

List<Category> mockSedanCategories() => const [
      Category(id: 'passenger_cars', name: 'Легковые'),
      Category(id: 'suv', name: 'Внедорожники'),
      Category(id: 'commercial', name: 'Коммерческие'),
      Category(id: 'motorcycle', name: 'Мототехника'),
      Category(id: 'parts', name: 'Запчасти'),
      Category(id: 'service', name: 'Услуги'),
    ];

class MockAuthRepository implements IAuthRepository {
  @override
  Future<Token> login(String username, String password) async => _mockToken;

  @override
  Future<Token> googleAuth(String token) async => _mockToken;

  @override
  Future<String> refreshToken(String refreshToken) async => _mockToken.access;

  @override
  Future<Map<String, dynamic>> registerUser({
    String? email,
    required String password,
    required String username,
    required String phoneNumber,
    int? regionId,
    bool isEmailConfirmation = false,
    String? referralCode,
  }) async {
    return {'token': _mockToken.access, 'username': username};
  }

  @override
  Future<String> activateAccount(String token) async => _mockToken.access;

  @override
  Future<String> confirmResetCodeByPhone({
    required String phoneNumber,
    required String code,
  }) async =>
      'mock-reset-user';

  @override
  Future<String> confirmResetCodeByEmail({
    required String email,
    required String code,
  }) async =>
      'mock-reset-user';

  @override
  Future<int> getUserCountByType(String userType, {String? categories}) async =>
      0;

  @override
  Future<int> getClientCountByType(String userType,
          {String? categories}) async =>
      0;

  @override
  Future<void> sendResetPasswordRequest(
      String value, String endpoint, String key) async {}

  @override
  Future<void> checkEmailExists(String email) async {}

  @override
  Future<String> getUserToken(String token) async => _mockToken.access;

  @override
  Future<void> updatePassword(String password, String userId) async {}

  @override
  Future<void> checkOldPassword(
      String oldPassword, String password, String userId) async {}

  @override
  Future<UserStatus> updatePremiumStatus(
          String pmtId, String premiumId, String token) async =>
      _mockUserStatus();
}

class MockCategoryRepository implements ICategoryRepository {
  @override
  Future<List<Category>> fetchData({List<int>? categoryTypes}) async =>
      mockSedanCategories();

  @override
  Future<Category> fetchCategory(String id) async {
    return mockSedanCategories().firstWhere(
      (category) => category.id == id,
      orElse: () => Category(id: id, name: 'Категория'),
    );
  }
}

class MockUserRepository implements IUserRepository {
  @override
  Future<User> getUserOwner(String token, {bool forceRefresh = false}) async =>
      _mockUser();

  @override
  Future<User> getUser(String token, String id) async => _mockUser();

  @override
  Future<User> getUserWithoutToken(String id) async => _mockUser();

  @override
  Future<Map<String, dynamic>> getUsersByTypeAndCountry({
    required String userType,
    String? country,
    String? categories,
    String? nextUrl,
    int? page,
    int limit = 20,
    int? market,
    bool isVerified = false,
    String? ordering,
  }) async =>
      {'users': <User>[], 'count': 0, 'next': null};

  @override
  Future<Map<String, dynamic>> getCustomers({
    required String token,
    String? countryId,
    String? categoryId,
    String? nextUrl,
    int? page,
    int limit = 20,
  }) async =>
      {'users': <User>[], 'count': 0, 'next': null};

  @override
  Future<List<UserActive>> getVisitProfileCount(
          String token, String id) async =>
      const [];

  @override
  Future<User> infoUserUpdate(
          String token, Map<String, dynamic> map, String id) async =>
      _mockUser(map['username']?.toString() ?? 'Sedan User');

  @override
  Future<User> userImage(String token, File file, String id) async =>
      _mockUser();

  @override
  Future<void> newEmailCode(String email, String token) async {}

  @override
  Future<String> updateEmail(String email, String code, String token) async =>
      email;

  @override
  Future<List<SocialType>> getSocialTypes({String? token}) async => const [];

  @override
  Future<List<SocialOwner>> getSocial(String id, {String? token}) async =>
      const [];

  @override
  Future<User> socialAddOrUpdate(
    String token,
    SocialOwner socialOwner,
    EnumRequestType typeRequest,
  ) async =>
      _mockUser();

  @override
  Future<void> deleteUser(String token, String id, String password) async {}

  @override
  Future<Map<String, dynamic>> searchUsers({
    required String search,
    String? categoryId,
    int? countryId,
    String? ordering,
    String? nextUrl,
    int page = 1,
    int limit = 20,
  }) async =>
      {'users': <User>[], 'count': 0, 'next': null};
}

class MockProductRepository implements IProductRepository {
  @override
  Future<PostModel> fetchProductsByFilter({
    String? category,
    String? owner,
    String? price,
    String? priceGte,
    String? priceLte,
    String? search,
    String? ordering,
    int? typeProduct,
    int? typeOwner,
    int? countryId,
    int? regionId,
    String? currency,
    int? limit,
    int? offset,
    int? page,
    int? pageSize,
    bool forceRefresh = false,
    String token = '',
    bool? isVideo,
  }) async =>
      const PostModel(results: [], count: 0);

  @override
  Future<PostModel> fetchAllProduct(
          {String? nextUrl, String token = ''}) async =>
      const PostModel(results: [], count: 0);

  @override
  Future<List<Product>> fetchDetailsBulk(List<String> ids) async => const [];

  @override
  Future<Product> getProductInfo(String? id) async => Product(id: id ?? '');

  @override
  Future<List<Product>> sameProduct(
          {String? category, int? typeProduct}) async =>
      const [];

  @override
  Future<void> deleteProduct(String productId, String token) async {}

  @override
  Future<void> deleteImage(int id, String token) async {}

  @override
  Future<PostsStatsByOwnerType> fetchPostsStatsByOwnerType() async =>
      const PostsStatsByOwnerType(
        totalPosts: 6,
        providers: 0,
        manufacturers: 0,
        customers: 0,
        demand: 0,
        product: 6,
      );

  @override
  Future<void> createProduct(
    String token,
    Product results,
    List<MediaFile> mediaFiles,
    EnumRequestType requestType,
  ) async {}

  @override
  Future<void> uploadMedia(
      List<MediaFile> mediaFiles, String postId, String token) async {}

  @override
  Future<String> createPost(
    String token,
    Product results,
    EnumRequestType requestType,
  ) async =>
      'mock-post-id';

  @override
  Future<void> uploadMediaWithProgress(
    List<MediaFile> mediaFiles,
    String postId,
    String token, {
    void Function(int fileIndex, int totalFiles, double fileProgress)?
        onProgress,
  }) async {
    onProgress?.call(1, mediaFiles.length, 1);
  }

  @override
  Future<int> registerView(
          {required String postId, required String authHeader}) async =>
      1;

  @override
  Future<PostMediaV2> uploadPostMediaV2(
    MediaFile media,
    String token, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    onSendProgress?.call(1, 1);
    return const PostMediaV2(id: 1, image: '', isVideo: false);
  }

  @override
  Future<String> createPostV2({
    required String token,
    required Product product,
    required List<int> mediaIds,
    required String clientRequestId,
  }) async =>
      'mock-post-id';

  @override
  Future<void> deletePostMediaV2(int mediaId, String token) async {}
}
