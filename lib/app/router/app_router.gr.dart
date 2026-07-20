// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AboutUs]
class AboutUsRoute extends PageRouteInfo<void> {
  const AboutUsRoute({List<PageRouteInfo>? children})
      : super(AboutUsRoute.name, initialChildren: children);

  static const String name = 'AboutUsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AboutUs();
    },
  );
}

/// generated route for
/// [AboutUsEdit]
class AboutUsEditRoute extends PageRouteInfo<AboutUsEditRouteArgs> {
  AboutUsEditRoute({
    Key? key,
    required User user,
    List<PageRouteInfo>? children,
  }) : super(
          AboutUsEditRoute.name,
          args: AboutUsEditRouteArgs(key: key, user: user),
          initialChildren: children,
        );

  static const String name = 'AboutUsEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AboutUsEditRouteArgs>();
      return AboutUsEdit(key: args.key, user: args.user);
    },
  );
}

class AboutUsEditRouteArgs {
  const AboutUsEditRouteArgs({this.key, required this.user});

  final Key? key;

  final User user;

  @override
  String toString() {
    return 'AboutUsEditRouteArgs{key: $key, user: $user}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AboutUsEditRouteArgs) return false;
    return key == other.key && user == other.user;
  }

  @override
  int get hashCode => key.hashCode ^ user.hashCode;
}

/// generated route for
/// [AddProductScreen]
class AddProductRoute extends PageRouteInfo<AddProductRouteArgs> {
  AddProductRoute({
    Key? key,
    Product? products,
    PostImage? postImage,
    List<PageRouteInfo>? children,
  }) : super(
          AddProductRoute.name,
          args: AddProductRouteArgs(
            key: key,
            products: products,
            postImage: postImage,
          ),
          initialChildren: children,
        );

  static const String name = 'AddProductRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddProductRouteArgs>(
        orElse: () => const AddProductRouteArgs(),
      );
      return AddProductScreen(
        key: args.key,
        products: args.products,
        postImage: args.postImage,
      );
    },
  );
}

class AddProductRouteArgs {
  const AddProductRouteArgs({this.key, this.products, this.postImage});

  final Key? key;

  final Product? products;

  final PostImage? postImage;

  @override
  String toString() {
    return 'AddProductRouteArgs{key: $key, products: $products, postImage: $postImage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddProductRouteArgs) return false;
    return key == other.key &&
        products == other.products &&
        postImage == other.postImage;
  }

  @override
  int get hashCode => key.hashCode ^ products.hashCode ^ postImage.hashCode;
}

/// generated route for
/// [AdvertisingInfoScreen]
class AdvertisingInfoRoute extends PageRouteInfo<void> {
  const AdvertisingInfoRoute({List<PageRouteInfo>? children})
      : super(AdvertisingInfoRoute.name, initialChildren: children);

  static const String name = 'AdvertisingInfoRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdvertisingInfoScreen();
    },
  );
}

/// generated route for
/// [AdvertisingKabinetScreen]
class AdvertisingKabinetRoute extends PageRouteInfo<void> {
  const AdvertisingKabinetRoute({List<PageRouteInfo>? children})
      : super(AdvertisingKabinetRoute.name, initialChildren: children);

  static const String name = 'AdvertisingKabinetRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdvertisingKabinetScreen();
    },
  );
}

/// generated route for
/// [BlockedUsersScreen]
class BlockedUsersRoute extends PageRouteInfo<void> {
  const BlockedUsersRoute({List<PageRouteInfo>? children})
      : super(BlockedUsersRoute.name, initialChildren: children);

  static const String name = 'BlockedUsersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BlockedUsersScreen();
    },
  );
}

/// generated route for
/// [BottomNav]
class BottomNavRoute extends PageRouteInfo<BottomNavRouteArgs> {
  BottomNavRoute({
    Key? key,
    int? currentIndexOverride,
    bool passive = false,
    bool forceDarkTheme = false,
    bool startTour = false,
    int initialIndex = 0,
    List<PageRouteInfo>? children,
  }) : super(
          BottomNavRoute.name,
          args: BottomNavRouteArgs(
            key: key,
            currentIndexOverride: currentIndexOverride,
            passive: passive,
            forceDarkTheme: forceDarkTheme,
            startTour: startTour,
            initialIndex: initialIndex,
          ),
          initialChildren: children,
        );

  static const String name = 'BottomNavRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<BottomNavRouteArgs>(
        orElse: () => const BottomNavRouteArgs(),
      );
      return BottomNav(
        key: args.key,
        currentIndexOverride: args.currentIndexOverride,
        passive: args.passive,
        forceDarkTheme: args.forceDarkTheme,
        startTour: args.startTour,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class BottomNavRouteArgs {
  const BottomNavRouteArgs({
    this.key,
    this.currentIndexOverride,
    this.passive = false,
    this.forceDarkTheme = false,
    this.startTour = false,
    this.initialIndex = 0,
  });

  final Key? key;

  final int? currentIndexOverride;

  final bool passive;

  final bool forceDarkTheme;

  final bool startTour;

  final int initialIndex;

  @override
  String toString() {
    return 'BottomNavRouteArgs{key: $key, currentIndexOverride: $currentIndexOverride, passive: $passive, forceDarkTheme: $forceDarkTheme, startTour: $startTour, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BottomNavRouteArgs) return false;
    return key == other.key &&
        currentIndexOverride == other.currentIndexOverride &&
        passive == other.passive &&
        forceDarkTheme == other.forceDarkTheme &&
        startTour == other.startTour &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      currentIndexOverride.hashCode ^
      passive.hashCode ^
      forceDarkTheme.hashCode ^
      startTour.hashCode ^
      initialIndex.hashCode;
}

/// generated route for
/// [CartPaymentScreen]
class CartPaymentRoute extends PageRouteInfo<CartPaymentRouteArgs> {
  CartPaymentRoute({
    Key? key,
    required Order order,
    List<PageRouteInfo>? children,
  }) : super(
          CartPaymentRoute.name,
          args: CartPaymentRouteArgs(key: key, order: order),
          initialChildren: children,
        );

  static const String name = 'CartPaymentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CartPaymentRouteArgs>();
      return CartPaymentScreen(key: args.key, order: args.order);
    },
  );
}

class CartPaymentRouteArgs {
  const CartPaymentRouteArgs({this.key, required this.order});

  final Key? key;

  final Order order;

  @override
  String toString() {
    return 'CartPaymentRouteArgs{key: $key, order: $order}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CartPaymentRouteArgs) return false;
    return key == other.key && order == other.order;
  }

  @override
  int get hashCode => key.hashCode ^ order.hashCode;
}

/// generated route for
/// [CartTab]
class CartTabRoute extends PageRouteInfo<void> {
  const CartTabRoute({List<PageRouteInfo>? children})
      : super(CartTabRoute.name, initialChildren: children);

  static const String name = 'CartTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CartTab();
    },
  );
}

/// generated route for
/// [CategoryScreen]
class CategoryRoute extends PageRouteInfo<CategoryRouteArgs> {
  CategoryRoute({
    Key? key,
    bool showBottomNav = true,
    int? choseOwner,
    List<PageRouteInfo>? children,
  }) : super(
          CategoryRoute.name,
          args: CategoryRouteArgs(
            key: key,
            showBottomNav: showBottomNav,
            choseOwner: choseOwner,
          ),
          initialChildren: children,
        );

  static const String name = 'CategoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CategoryRouteArgs>(
        orElse: () => const CategoryRouteArgs(),
      );
      return CategoryScreen(
        key: args.key,
        showBottomNav: args.showBottomNav,
        choseOwner: args.choseOwner,
      );
    },
  );
}

class CategoryRouteArgs {
  const CategoryRouteArgs({
    this.key,
    this.showBottomNav = true,
    this.choseOwner,
  });

  final Key? key;

  final bool showBottomNav;

  final int? choseOwner;

  @override
  String toString() {
    return 'CategoryRouteArgs{key: $key, showBottomNav: $showBottomNav, choseOwner: $choseOwner}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CategoryRouteArgs) return false;
    return key == other.key &&
        showBottomNav == other.showBottomNav &&
        choseOwner == other.choseOwner;
  }

  @override
  int get hashCode =>
      key.hashCode ^ showBottomNav.hashCode ^ choseOwner.hashCode;
}

/// generated route for
/// [ChatConversationScreen]
class ChatConversationRoute extends PageRouteInfo<ChatConversationRouteArgs> {
  ChatConversationRoute({
    Key? key,
    required Chat chat,
    SupportSession? supportSession,
    LinkedPost? linkedPost,
    List<PageRouteInfo>? children,
  }) : super(
          ChatConversationRoute.name,
          args: ChatConversationRouteArgs(
            key: key,
            chat: chat,
            supportSession: supportSession,
            linkedPost: linkedPost,
          ),
          initialChildren: children,
        );

  static const String name = 'ChatConversationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChatConversationRouteArgs>();
      return ChatConversationScreen(
        key: args.key,
        chat: args.chat,
        supportSession: args.supportSession,
        linkedPost: args.linkedPost,
      );
    },
  );
}

class ChatConversationRouteArgs {
  const ChatConversationRouteArgs({
    this.key,
    required this.chat,
    this.supportSession,
    this.linkedPost,
  });

  final Key? key;

  final Chat chat;

  final SupportSession? supportSession;

  final LinkedPost? linkedPost;

  @override
  String toString() {
    return 'ChatConversationRouteArgs{key: $key, chat: $chat, supportSession: $supportSession, linkedPost: $linkedPost}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatConversationRouteArgs) return false;
    return key == other.key &&
        chat == other.chat &&
        supportSession == other.supportSession &&
        linkedPost == other.linkedPost;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      chat.hashCode ^
      supportSession.hashCode ^
      linkedPost.hashCode;
}

/// generated route for
/// [ChatListScreen]
class ChatListRoute extends PageRouteInfo<void> {
  const ChatListRoute({List<PageRouteInfo>? children})
      : super(ChatListRoute.name, initialChildren: children);

  static const String name = 'ChatListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChatListScreen();
    },
  );
}

/// generated route for
/// [CheckoutScreen]
class CheckoutRoute extends PageRouteInfo<void> {
  const CheckoutRoute({List<PageRouteInfo>? children})
      : super(CheckoutRoute.name, initialChildren: children);

  static const String name = 'CheckoutRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CheckoutScreen();
    },
  );
}

/// generated route for
/// [ComplaintScreen]
class ComplaintRoute extends PageRouteInfo<ComplaintRouteArgs> {
  ComplaintRoute({
    Key? key,
    required QuestionModel question,
    List<PageRouteInfo>? children,
  }) : super(
          ComplaintRoute.name,
          args: ComplaintRouteArgs(key: key, question: question),
          initialChildren: children,
        );

  static const String name = 'ComplaintRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComplaintRouteArgs>();
      return ComplaintScreen(key: args.key, question: args.question);
    },
  );
}

class ComplaintRouteArgs {
  const ComplaintRouteArgs({this.key, required this.question});

  final Key? key;

  final QuestionModel question;

  @override
  String toString() {
    return 'ComplaintRouteArgs{key: $key, question: $question}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComplaintRouteArgs) return false;
    return key == other.key && question == other.question;
  }

  @override
  int get hashCode => key.hashCode ^ question.hashCode;
}

/// generated route for
/// [ConfirmPhoneScreen]
class ConfirmPhoneRoute extends PageRouteInfo<ConfirmPhoneRouteArgs> {
  ConfirmPhoneRoute({
    Key? key,
    required String username,
    required String password,
    required String phone,
    int? regionId,
    String? email,
    List<PageRouteInfo>? children,
  }) : super(
          ConfirmPhoneRoute.name,
          args: ConfirmPhoneRouteArgs(
            key: key,
            username: username,
            password: password,
            phone: phone,
            regionId: regionId,
            email: email,
          ),
          initialChildren: children,
        );

  static const String name = 'ConfirmPhoneRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ConfirmPhoneRouteArgs>();
      return ConfirmPhoneScreen(
        key: args.key,
        username: args.username,
        password: args.password,
        phone: args.phone,
        regionId: args.regionId,
        email: args.email,
      );
    },
  );
}

class ConfirmPhoneRouteArgs {
  const ConfirmPhoneRouteArgs({
    this.key,
    required this.username,
    required this.password,
    required this.phone,
    this.regionId,
    this.email,
  });

  final Key? key;

  final String username;

  final String password;

  final String phone;

  final int? regionId;

  final String? email;

  @override
  String toString() {
    return 'ConfirmPhoneRouteArgs{key: $key, username: $username, password: $password, phone: $phone, regionId: $regionId, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConfirmPhoneRouteArgs) return false;
    return key == other.key &&
        username == other.username &&
        password == other.password &&
        phone == other.phone &&
        regionId == other.regionId &&
        email == other.email;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      username.hashCode ^
      password.hashCode ^
      phone.hashCode ^
      regionId.hashCode ^
      email.hashCode;
}

/// generated route for
/// [CreateSocials]
class CreateSocialsRoute extends PageRouteInfo<void> {
  const CreateSocialsRoute({List<PageRouteInfo>? children})
      : super(CreateSocialsRoute.name, initialChildren: children);

  static const String name = 'CreateSocialsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateSocials();
    },
  );
}

/// generated route for
/// [CreateStreamPage]
class CreateStreamRoute extends PageRouteInfo<CreateStreamRouteArgs> {
  CreateStreamRoute({
    Key? key,
    required bool isHost,
    required String streamId,
    required String streamKey,
    required String publishApiUrl,
    required String streamUrl,
    required String? authToken,
    required Future<void> Function(String) onEndStream,
    List<PageRouteInfo>? children,
  }) : super(
          CreateStreamRoute.name,
          args: CreateStreamRouteArgs(
            key: key,
            isHost: isHost,
            streamId: streamId,
            streamKey: streamKey,
            publishApiUrl: publishApiUrl,
            streamUrl: streamUrl,
            authToken: authToken,
            onEndStream: onEndStream,
          ),
          initialChildren: children,
        );

  static const String name = 'CreateStreamRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CreateStreamRouteArgs>();
      return CreateStreamPage(
        key: args.key,
        isHost: args.isHost,
        streamId: args.streamId,
        streamKey: args.streamKey,
        publishApiUrl: args.publishApiUrl,
        streamUrl: args.streamUrl,
        authToken: args.authToken,
        onEndStream: args.onEndStream,
      );
    },
  );
}

class CreateStreamRouteArgs {
  const CreateStreamRouteArgs({
    this.key,
    required this.isHost,
    required this.streamId,
    required this.streamKey,
    required this.publishApiUrl,
    required this.streamUrl,
    required this.authToken,
    required this.onEndStream,
  });

  final Key? key;

  final bool isHost;

  final String streamId;

  final String streamKey;

  final String publishApiUrl;

  final String streamUrl;

  final String? authToken;

  final Future<void> Function(String) onEndStream;

  @override
  String toString() {
    return 'CreateStreamRouteArgs{key: $key, isHost: $isHost, streamId: $streamId, streamKey: $streamKey, publishApiUrl: $publishApiUrl, streamUrl: $streamUrl, authToken: $authToken, onEndStream: $onEndStream}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CreateStreamRouteArgs) return false;
    return key == other.key &&
        isHost == other.isHost &&
        streamId == other.streamId &&
        streamKey == other.streamKey &&
        publishApiUrl == other.publishApiUrl &&
        streamUrl == other.streamUrl &&
        authToken == other.authToken;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      isHost.hashCode ^
      streamId.hashCode ^
      streamKey.hashCode ^
      publishApiUrl.hashCode ^
      streamUrl.hashCode ^
      authToken.hashCode;
}

/// generated route for
/// [CreateSupportRequestScreen]
class CreateSupportRequestRoute extends PageRouteInfo<void> {
  const CreateSupportRequestRoute({List<PageRouteInfo>? children})
      : super(CreateSupportRequestRoute.name, initialChildren: children);

  static const String name = 'CreateSupportRequestRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateSupportRequestScreen();
    },
  );
}

/// generated route for
/// [DescEditScreen]
class DescEditRoute extends PageRouteInfo<void> {
  const DescEditRoute({List<PageRouteInfo>? children})
      : super(DescEditRoute.name, initialChildren: children);

  static const String name = 'DescEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DescEditScreen();
    },
  );
}

/// generated route for
/// [EditUserProduct]
class EditUserProductRoute extends PageRouteInfo<EditUserProductRouteArgs> {
  EditUserProductRoute({
    Key? key,
    PostImage? postImage,
    required Product products,
    List<PageRouteInfo>? children,
  }) : super(
          EditUserProductRoute.name,
          args: EditUserProductRouteArgs(
            key: key,
            postImage: postImage,
            products: products,
          ),
          initialChildren: children,
        );

  static const String name = 'EditUserProductRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditUserProductRouteArgs>();
      return EditUserProduct(
        key: args.key,
        postImage: args.postImage,
        products: args.products,
      );
    },
  );
}

class EditUserProductRouteArgs {
  const EditUserProductRouteArgs({
    this.key,
    this.postImage,
    required this.products,
  });

  final Key? key;

  final PostImage? postImage;

  final Product products;

  @override
  String toString() {
    return 'EditUserProductRouteArgs{key: $key, postImage: $postImage, products: $products}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditUserProductRouteArgs) return false;
    return key == other.key &&
        postImage == other.postImage &&
        products == other.products;
  }

  @override
  int get hashCode => key.hashCode ^ postImage.hashCode ^ products.hashCode;
}

/// generated route for
/// [FavoriteScreen]
class FavoriteRoute extends PageRouteInfo<void> {
  const FavoriteRoute({List<PageRouteInfo>? children})
      : super(FavoriteRoute.name, initialChildren: children);

  static const String name = 'FavoriteRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FavoriteScreen();
    },
  );
}

/// generated route for
/// [FinikPaymentScreen]
class FinikPaymentRoute extends PageRouteInfo<FinikPaymentRouteArgs> {
  FinikPaymentRoute({
    Key? key,
    required String orderId,
    required double amount,
    required String description,
    String? phone,
    String? userName,
    String? email,
    String? callbackUrl,
    VoidCallback? onCancel,
    Future<bool> Function()? checkPaymentStatus,
    Future<void> Function()? onPaymentConfirmed,
    List<PageRouteInfo>? children,
  }) : super(
          FinikPaymentRoute.name,
          args: FinikPaymentRouteArgs(
            key: key,
            orderId: orderId,
            amount: amount,
            description: description,
            phone: phone,
            userName: userName,
            email: email,
            callbackUrl: callbackUrl,
            onCancel: onCancel,
            checkPaymentStatus: checkPaymentStatus,
            onPaymentConfirmed: onPaymentConfirmed,
          ),
          initialChildren: children,
        );

  static const String name = 'FinikPaymentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FinikPaymentRouteArgs>();
      return FinikPaymentScreen(
        key: args.key,
        orderId: args.orderId,
        amount: args.amount,
        description: args.description,
        phone: args.phone,
        userName: args.userName,
        email: args.email,
        callbackUrl: args.callbackUrl,
        onCancel: args.onCancel,
        checkPaymentStatus: args.checkPaymentStatus,
        onPaymentConfirmed: args.onPaymentConfirmed,
      );
    },
  );
}

class FinikPaymentRouteArgs {
  const FinikPaymentRouteArgs({
    this.key,
    required this.orderId,
    required this.amount,
    required this.description,
    this.phone,
    this.userName,
    this.email,
    this.callbackUrl,
    this.onCancel,
    this.checkPaymentStatus,
    this.onPaymentConfirmed,
  });

  final Key? key;

  final String orderId;

  final double amount;

  final String description;

  final String? phone;

  final String? userName;

  final String? email;

  final String? callbackUrl;

  final VoidCallback? onCancel;

  final Future<bool> Function()? checkPaymentStatus;

  final Future<void> Function()? onPaymentConfirmed;

  @override
  String toString() {
    return 'FinikPaymentRouteArgs{key: $key, orderId: $orderId, amount: $amount, description: $description, phone: $phone, userName: $userName, email: $email, callbackUrl: $callbackUrl, onCancel: $onCancel, checkPaymentStatus: $checkPaymentStatus, onPaymentConfirmed: $onPaymentConfirmed}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinikPaymentRouteArgs) return false;
    return key == other.key &&
        orderId == other.orderId &&
        amount == other.amount &&
        description == other.description &&
        phone == other.phone &&
        userName == other.userName &&
        email == other.email &&
        callbackUrl == other.callbackUrl &&
        onCancel == other.onCancel;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      orderId.hashCode ^
      amount.hashCode ^
      description.hashCode ^
      phone.hashCode ^
      userName.hashCode ^
      email.hashCode ^
      callbackUrl.hashCode ^
      onCancel.hashCode;
}

/// generated route for
/// [ForgotPassword]
class ForgotPasswordRoute extends PageRouteInfo<void> {
  const ForgotPasswordRoute({List<PageRouteInfo>? children})
      : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ForgotPassword();
    },
  );
}

/// generated route for
/// [FulfilmentScreen]
class FulfilmentRoute extends PageRouteInfo<void> {
  const FulfilmentRoute({List<PageRouteInfo>? children})
      : super(FulfilmentRoute.name, initialChildren: children);

  static const String name = 'FulfilmentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FulfilmentScreen();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [InfoScreen]
class InfoRoute extends PageRouteInfo<InfoRouteArgs> {
  InfoRoute({
    Key? key,
    required String title,
    required String text,
    List<PageRouteInfo>? children,
  }) : super(
          InfoRoute.name,
          args: InfoRouteArgs(key: key, title: title, text: text),
          initialChildren: children,
        );

  static const String name = 'InfoRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InfoRouteArgs>();
      return InfoScreen(key: args.key, title: args.title, text: args.text);
    },
  );
}

class InfoRouteArgs {
  const InfoRouteArgs({this.key, required this.title, required this.text});

  final Key? key;

  final String title;

  final String text;

  @override
  String toString() {
    return 'InfoRouteArgs{key: $key, title: $title, text: $text}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InfoRouteArgs) return false;
    return key == other.key && title == other.title && text == other.text;
  }

  @override
  int get hashCode => key.hashCode ^ title.hashCode ^ text.hashCode;
}

/// generated route for
/// [LawData]
class LawDataRoute extends PageRouteInfo<void> {
  const LawDataRoute({List<PageRouteInfo>? children})
      : super(LawDataRoute.name, initialChildren: children);

  static const String name = 'LawDataRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LawData();
    },
  );
}

/// generated route for
/// [LiveRoomPage]
class LiveRoomRoute extends PageRouteInfo<LiveRoomRouteArgs> {
  LiveRoomRoute({
    Key? key,
    required StreamModel stream,
    required StreamPlayerCubit playerCubit,
    List<PageRouteInfo>? children,
  }) : super(
          LiveRoomRoute.name,
          args: LiveRoomRouteArgs(
            key: key,
            stream: stream,
            playerCubit: playerCubit,
          ),
          initialChildren: children,
        );

  static const String name = 'LiveRoomRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LiveRoomRouteArgs>();
      return LiveRoomPage(
        key: args.key,
        stream: args.stream,
        playerCubit: args.playerCubit,
      );
    },
  );
}

class LiveRoomRouteArgs {
  const LiveRoomRouteArgs({
    this.key,
    required this.stream,
    required this.playerCubit,
  });

  final Key? key;

  final StreamModel stream;

  final StreamPlayerCubit playerCubit;

  @override
  String toString() {
    return 'LiveRoomRouteArgs{key: $key, stream: $stream, playerCubit: $playerCubit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LiveRoomRouteArgs) return false;
    return key == other.key &&
        stream == other.stream &&
        playerCubit == other.playerCubit;
  }

  @override
  int get hashCode => key.hashCode ^ stream.hashCode ^ playerCubit.hashCode;
}

/// generated route for
/// [ManagerContactScreen]
class ManagerContactRoute extends PageRouteInfo<ManagerContactRouteArgs> {
  ManagerContactRoute({
    Key? key,
    required double amount,
    List<PageRouteInfo>? children,
  }) : super(
          ManagerContactRoute.name,
          args: ManagerContactRouteArgs(key: key, amount: amount),
          initialChildren: children,
        );

  static const String name = 'ManagerContactRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ManagerContactRouteArgs>();
      return ManagerContactScreen(key: args.key, amount: args.amount);
    },
  );
}

class ManagerContactRouteArgs {
  const ManagerContactRouteArgs({this.key, required this.amount});

  final Key? key;

  final double amount;

  @override
  String toString() {
    return 'ManagerContactRouteArgs{key: $key, amount: $amount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ManagerContactRouteArgs) return false;
    return key == other.key && amount == other.amount;
  }

  @override
  int get hashCode => key.hashCode ^ amount.hashCode;
}

/// generated route for
/// [NotificationPreferencesScreen]
class NotificationPreferencesRoute extends PageRouteInfo<void> {
  const NotificationPreferencesRoute({List<PageRouteInfo>? children})
      : super(NotificationPreferencesRoute.name, initialChildren: children);

  static const String name = 'NotificationPreferencesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotificationPreferencesScreen();
    },
  );
}

/// generated route for
/// [NotificationsScreen]
class NotificationsRoute extends PageRouteInfo<void> {
  const NotificationsRoute({List<PageRouteInfo>? children})
      : super(NotificationsRoute.name, initialChildren: children);

  static const String name = 'NotificationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotificationsScreen();
    },
  );
}

/// generated route for
/// [OfertaScreen]
class OfertaRoute extends PageRouteInfo<void> {
  const OfertaRoute({List<PageRouteInfo>? children})
      : super(OfertaRoute.name, initialChildren: children);

  static const String name = 'OfertaRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OfertaScreen();
    },
  );
}

/// generated route for
/// [OnboardingLanguageScreen]
class OnboardingLanguageRoute extends PageRouteInfo<void> {
  const OnboardingLanguageRoute({List<PageRouteInfo>? children})
      : super(OnboardingLanguageRoute.name, initialChildren: children);

  static const String name = 'OnboardingLanguageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OnboardingLanguageScreen();
    },
  );
}

/// generated route for
/// [OrderDetailsScreen]
class OrderDetailsRoute extends PageRouteInfo<OrderDetailsRouteArgs> {
  OrderDetailsRoute({
    Key? key,
    required String orderId,
    List<PageRouteInfo>? children,
  }) : super(
          OrderDetailsRoute.name,
          args: OrderDetailsRouteArgs(key: key, orderId: orderId),
          initialChildren: children,
        );

  static const String name = 'OrderDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OrderDetailsRouteArgs>();
      return OrderDetailsScreen(key: args.key, orderId: args.orderId);
    },
  );
}

class OrderDetailsRouteArgs {
  const OrderDetailsRouteArgs({this.key, required this.orderId});

  final Key? key;

  final String orderId;

  @override
  String toString() {
    return 'OrderDetailsRouteArgs{key: $key, orderId: $orderId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OrderDetailsRouteArgs) return false;
    return key == other.key && orderId == other.orderId;
  }

  @override
  int get hashCode => key.hashCode ^ orderId.hashCode;
}

/// generated route for
/// [OrderStatusScreen]
class OrderStatusRoute extends PageRouteInfo<OrderStatusRouteArgs> {
  OrderStatusRoute({
    Key? key,
    required String categoryId,
    List<PageRouteInfo>? children,
  }) : super(
          OrderStatusRoute.name,
          args: OrderStatusRouteArgs(key: key, categoryId: categoryId),
          initialChildren: children,
        );

  static const String name = 'OrderStatusRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OrderStatusRouteArgs>();
      return OrderStatusScreen(key: args.key, categoryId: args.categoryId);
    },
  );
}

class OrderStatusRouteArgs {
  const OrderStatusRouteArgs({this.key, required this.categoryId});

  final Key? key;

  final String categoryId;

  @override
  String toString() {
    return 'OrderStatusRouteArgs{key: $key, categoryId: $categoryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OrderStatusRouteArgs) return false;
    return key == other.key && categoryId == other.categoryId;
  }

  @override
  int get hashCode => key.hashCode ^ categoryId.hashCode;
}

/// generated route for
/// [OrdersScreen]
class OrdersRoute extends PageRouteInfo<OrdersRouteArgs> {
  OrdersRoute({
    Key? key,
    int? choseMain = 0,
    int? choseOwner,
    int? countryId,
    List<PageRouteInfo>? children,
  }) : super(
          OrdersRoute.name,
          args: OrdersRouteArgs(
            key: key,
            choseMain: choseMain,
            choseOwner: choseOwner,
            countryId: countryId,
          ),
          initialChildren: children,
        );

  static const String name = 'OrdersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OrdersRouteArgs>(
        orElse: () => const OrdersRouteArgs(),
      );
      return OrdersScreen(
        key: args.key,
        choseMain: args.choseMain,
        choseOwner: args.choseOwner,
        countryId: args.countryId,
      );
    },
  );
}

class OrdersRouteArgs {
  const OrdersRouteArgs({
    this.key,
    this.choseMain = 0,
    this.choseOwner,
    this.countryId,
  });

  final Key? key;

  final int? choseMain;

  final int? choseOwner;

  final int? countryId;

  @override
  String toString() {
    return 'OrdersRouteArgs{key: $key, choseMain: $choseMain, choseOwner: $choseOwner, countryId: $countryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OrdersRouteArgs) return false;
    return key == other.key &&
        choseMain == other.choseMain &&
        choseOwner == other.choseOwner &&
        countryId == other.countryId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      choseMain.hashCode ^
      choseOwner.hashCode ^
      countryId.hashCode;
}

/// generated route for
/// [OrdersTab]
class OrdersTabRoute extends PageRouteInfo<void> {
  const OrdersTabRoute({List<PageRouteInfo>? children})
      : super(OrdersTabRoute.name, initialChildren: children);

  static const String name = 'OrdersTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OrdersTab();
    },
  );
}

/// generated route for
/// [OtherUserProfile]
class OtherUserProfileRoute extends PageRouteInfo<OtherUserProfileRouteArgs> {
  OtherUserProfileRoute({
    Key? key,
    required String user,
    int? productType,
    bool? isRegistered,
    String? flagName,
    required String username,
    List<PageRouteInfo>? children,
  }) : super(
          OtherUserProfileRoute.name,
          args: OtherUserProfileRouteArgs(
            key: key,
            user: user,
            productType: productType,
            isRegistered: isRegistered,
            flagName: flagName,
            username: username,
          ),
          initialChildren: children,
        );

  static const String name = 'OtherUserProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OtherUserProfileRouteArgs>();
      return OtherUserProfile(
        key: args.key,
        user: args.user,
        productType: args.productType,
        isRegistered: args.isRegistered,
        flagName: args.flagName,
        username: args.username,
      );
    },
  );
}

class OtherUserProfileRouteArgs {
  const OtherUserProfileRouteArgs({
    this.key,
    required this.user,
    this.productType,
    this.isRegistered,
    this.flagName,
    required this.username,
  });

  final Key? key;

  final String user;

  final int? productType;

  final bool? isRegistered;

  final String? flagName;

  final String username;

  @override
  String toString() {
    return 'OtherUserProfileRouteArgs{key: $key, user: $user, productType: $productType, isRegistered: $isRegistered, flagName: $flagName, username: $username}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtherUserProfileRouteArgs) return false;
    return key == other.key &&
        user == other.user &&
        productType == other.productType &&
        isRegistered == other.isRegistered &&
        flagName == other.flagName &&
        username == other.username;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      user.hashCode ^
      productType.hashCode ^
      isRegistered.hashCode ^
      flagName.hashCode ^
      username.hashCode;
}

/// generated route for
/// [PickupPointsScreen]
class PickupPointsRoute extends PageRouteInfo<void> {
  const PickupPointsRoute({List<PageRouteInfo>? children})
      : super(PickupPointsRoute.name, initialChildren: children);

  static const String name = 'PickupPointsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PickupPointsScreen();
    },
  );
}

/// generated route for
/// [PitScreen]
class PitRoute extends PageRouteInfo<void> {
  const PitRoute({List<PageRouteInfo>? children})
      : super(PitRoute.name, initialChildren: children);

  static const String name = 'PitRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PitScreen();
    },
  );
}

/// generated route for
/// [PmtInfoScreen]
class PmtInfoRoute extends PageRouteInfo<PmtInfoRouteArgs> {
  PmtInfoRoute({
    Key? key,
    PmtInfoInitialSection initialSection = PmtInfoInitialSection.none,
    required String premiumId,
    PremiumTariff initialTariff = PremiumTariff.weekly,
    List<PageRouteInfo>? children,
  }) : super(
          PmtInfoRoute.name,
          args: PmtInfoRouteArgs(
            key: key,
            initialSection: initialSection,
            premiumId: premiumId,
            initialTariff: initialTariff,
          ),
          initialChildren: children,
        );

  static const String name = 'PmtInfoRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PmtInfoRouteArgs>();
      return PmtInfoScreen(
        key: args.key,
        initialSection: args.initialSection,
        premiumId: args.premiumId,
        initialTariff: args.initialTariff,
      );
    },
  );
}

class PmtInfoRouteArgs {
  const PmtInfoRouteArgs({
    this.key,
    this.initialSection = PmtInfoInitialSection.none,
    required this.premiumId,
    this.initialTariff = PremiumTariff.weekly,
  });

  final Key? key;

  final PmtInfoInitialSection initialSection;

  final String premiumId;

  final PremiumTariff initialTariff;

  @override
  String toString() {
    return 'PmtInfoRouteArgs{key: $key, initialSection: $initialSection, premiumId: $premiumId, initialTariff: $initialTariff}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PmtInfoRouteArgs) return false;
    return key == other.key &&
        initialSection == other.initialSection &&
        premiumId == other.premiumId &&
        initialTariff == other.initialTariff;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      initialSection.hashCode ^
      premiumId.hashCode ^
      initialTariff.hashCode;
}

/// generated route for
/// [PmtScreen]
class PmtRoute extends PageRouteInfo<PmtRouteArgs> {
  PmtRoute({
    Key? key,
    required String orderId,
    required String userId,
    required String userEmail,
    required String userPhone,
    required BusinessTariff tariff,
    required double amount,
    required String currencyCode,
    required String description,
    required String premiumId,
    bool autoStart = false,
    PaymentMethod? initialMethod,
    bool skipChooser = false,
    List<PageRouteInfo>? children,
  }) : super(
          PmtRoute.name,
          args: PmtRouteArgs(
            key: key,
            orderId: orderId,
            userId: userId,
            userEmail: userEmail,
            userPhone: userPhone,
            tariff: tariff,
            amount: amount,
            currencyCode: currencyCode,
            description: description,
            premiumId: premiumId,
            autoStart: autoStart,
            initialMethod: initialMethod,
            skipChooser: skipChooser,
          ),
          initialChildren: children,
        );

  static const String name = 'PmtRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PmtRouteArgs>();
      return PmtScreen(
        key: args.key,
        orderId: args.orderId,
        userId: args.userId,
        userEmail: args.userEmail,
        userPhone: args.userPhone,
        tariff: args.tariff,
        amount: args.amount,
        currencyCode: args.currencyCode,
        description: args.description,
        premiumId: args.premiumId,
        autoStart: args.autoStart,
        initialMethod: args.initialMethod,
        skipChooser: args.skipChooser,
      );
    },
  );
}

class PmtRouteArgs {
  const PmtRouteArgs({
    this.key,
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.userPhone,
    required this.tariff,
    required this.amount,
    required this.currencyCode,
    required this.description,
    required this.premiumId,
    this.autoStart = false,
    this.initialMethod,
    this.skipChooser = false,
  });

  final Key? key;

  final String orderId;

  final String userId;

  final String userEmail;

  final String userPhone;

  final BusinessTariff tariff;

  final double amount;

  final String currencyCode;

  final String description;

  final String premiumId;

  final bool autoStart;

  final PaymentMethod? initialMethod;

  final bool skipChooser;

  @override
  String toString() {
    return 'PmtRouteArgs{key: $key, orderId: $orderId, userId: $userId, userEmail: $userEmail, userPhone: $userPhone, tariff: $tariff, amount: $amount, currencyCode: $currencyCode, description: $description, premiumId: $premiumId, autoStart: $autoStart, initialMethod: $initialMethod, skipChooser: $skipChooser}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PmtRouteArgs) return false;
    return key == other.key &&
        orderId == other.orderId &&
        userId == other.userId &&
        userEmail == other.userEmail &&
        userPhone == other.userPhone &&
        tariff == other.tariff &&
        amount == other.amount &&
        currencyCode == other.currencyCode &&
        description == other.description &&
        premiumId == other.premiumId &&
        autoStart == other.autoStart &&
        initialMethod == other.initialMethod &&
        skipChooser == other.skipChooser;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      orderId.hashCode ^
      userId.hashCode ^
      userEmail.hashCode ^
      userPhone.hashCode ^
      tariff.hashCode ^
      amount.hashCode ^
      currencyCode.hashCode ^
      description.hashCode ^
      premiumId.hashCode ^
      autoStart.hashCode ^
      initialMethod.hashCode ^
      skipChooser.hashCode;
}

/// generated route for
/// [PoliticsScreen]
class PoliticsRoute extends PageRouteInfo<void> {
  const PoliticsRoute({List<PageRouteInfo>? children})
      : super(PoliticsRoute.name, initialChildren: children);

  static const String name = 'PoliticsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PoliticsScreen();
    },
  );
}

/// generated route for
/// [PrimaryScreen]
class PrimaryRoute extends PageRouteInfo<void> {
  const PrimaryRoute({List<PageRouteInfo>? children})
      : super(PrimaryRoute.name, initialChildren: children);

  static const String name = 'PrimaryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PrimaryScreen();
    },
  );
}

/// generated route for
/// [ProAccountsScreen]
class ProAccountsRoute extends PageRouteInfo<void> {
  const ProAccountsRoute({List<PageRouteInfo>? children})
      : super(ProAccountsRoute.name, initialChildren: children);

  static const String name = 'ProAccountsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProAccountsScreen();
    },
  );
}

/// generated route for
/// [ProductDetails]
class ProductDetailsRoute extends PageRouteInfo<ProductDetailsRouteArgs> {
  ProductDetailsRoute({
    Key? key,
    required Product results,
    String? postId,
    int? chooseMainType,
    bool? isRegistered,
    String? commentId,
    List<PageRouteInfo>? children,
  }) : super(
          ProductDetailsRoute.name,
          args: ProductDetailsRouteArgs(
            key: key,
            results: results,
            postId: postId,
            chooseMainType: chooseMainType,
            isRegistered: isRegistered,
            commentId: commentId,
          ),
          initialChildren: children,
        );

  static const String name = 'ProductDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailsRouteArgs>();
      return ProductDetails(
        key: args.key,
        results: args.results,
        postId: args.postId,
        chooseMainType: args.chooseMainType,
        isRegistered: args.isRegistered,
        commentId: args.commentId,
      );
    },
  );
}

class ProductDetailsRouteArgs {
  const ProductDetailsRouteArgs({
    this.key,
    required this.results,
    this.postId,
    this.chooseMainType,
    this.isRegistered,
    this.commentId,
  });

  final Key? key;

  final Product results;

  final String? postId;

  final int? chooseMainType;

  final bool? isRegistered;

  final String? commentId;

  @override
  String toString() {
    return 'ProductDetailsRouteArgs{key: $key, results: $results, postId: $postId, chooseMainType: $chooseMainType, isRegistered: $isRegistered, commentId: $commentId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductDetailsRouteArgs) return false;
    return key == other.key &&
        results == other.results &&
        postId == other.postId &&
        chooseMainType == other.chooseMainType &&
        isRegistered == other.isRegistered &&
        commentId == other.commentId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      results.hashCode ^
      postId.hashCode ^
      chooseMainType.hashCode ^
      isRegistered.hashCode ^
      commentId.hashCode;
}

/// generated route for
/// [ProductsScreen]
class ProductsRoute extends PageRouteInfo<ProductsRouteArgs> {
  ProductsRoute({
    Key? key,
    required String childId,
    required String title,
    List<PageRouteInfo>? children,
  }) : super(
          ProductsRoute.name,
          args: ProductsRouteArgs(key: key, childId: childId, title: title),
          initialChildren: children,
        );

  static const String name = 'ProductsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductsRouteArgs>();
      return ProductsScreen(
        key: args.key,
        childId: args.childId,
        title: args.title,
      );
    },
  );
}

class ProductsRouteArgs {
  const ProductsRouteArgs({
    this.key,
    required this.childId,
    required this.title,
  });

  final Key? key;

  final String childId;

  final String title;

  @override
  String toString() {
    return 'ProductsRouteArgs{key: $key, childId: $childId, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductsRouteArgs) return false;
    return key == other.key && childId == other.childId && title == other.title;
  }

  @override
  int get hashCode => key.hashCode ^ childId.hashCode ^ title.hashCode;
}

/// generated route for
/// [ProfileEditEmail]
class ProfileEditEmailRoute extends PageRouteInfo<void> {
  const ProfileEditEmailRoute({List<PageRouteInfo>? children})
      : super(ProfileEditEmailRoute.name, initialChildren: children);

  static const String name = 'ProfileEditEmailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileEditEmail();
    },
  );
}

/// generated route for
/// [ProfileEditPassword]
class ProfileEditPasswordRoute extends PageRouteInfo<void> {
  const ProfileEditPasswordRoute({List<PageRouteInfo>? children})
      : super(ProfileEditPasswordRoute.name, initialChildren: children);

  static const String name = 'ProfileEditPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileEditPassword();
    },
  );
}

/// generated route for
/// [ProfileEditScreen]
class ProfileEditRoute extends PageRouteInfo<ProfileEditRouteArgs> {
  ProfileEditRoute({
    Key? key,
    required User user,
    List<PageRouteInfo>? children,
  }) : super(
          ProfileEditRoute.name,
          args: ProfileEditRouteArgs(key: key, user: user),
          initialChildren: children,
        );

  static const String name = 'ProfileEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProfileEditRouteArgs>();
      return ProfileEditScreen(key: args.key, user: args.user);
    },
  );
}

class ProfileEditRouteArgs {
  const ProfileEditRouteArgs({this.key, required this.user});

  final Key? key;

  final User user;

  @override
  String toString() {
    return 'ProfileEditRouteArgs{key: $key, user: $user}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfileEditRouteArgs) return false;
    return key == other.key && user == other.user;
  }

  @override
  int get hashCode => key.hashCode ^ user.hashCode;
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<ProfileRouteArgs> {
  ProfileRoute({
    Key? key,
    required String username,
    required String userId,
    List<PageRouteInfo>? children,
  }) : super(
          ProfileRoute.name,
          args: ProfileRouteArgs(key: key, username: username, userId: userId),
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProfileRouteArgs>();
      return ProfileScreen(
        key: args.key,
        username: args.username,
        userId: args.userId,
      );
    },
  );
}

class ProfileRouteArgs {
  const ProfileRouteArgs({
    this.key,
    required this.username,
    required this.userId,
  });

  final Key? key;

  final String username;

  final String userId;

  @override
  String toString() {
    return 'ProfileRouteArgs{key: $key, username: $username, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfileRouteArgs) return false;
    return key == other.key &&
        username == other.username &&
        userId == other.userId;
  }

  @override
  int get hashCode => key.hashCode ^ username.hashCode ^ userId.hashCode;
}

/// generated route for
/// [PromotionsCampaignsScreen]
class PromotionsCampaignsRoute extends PageRouteInfo<void> {
  const PromotionsCampaignsRoute({List<PageRouteInfo>? children})
      : super(PromotionsCampaignsRoute.name, initialChildren: children);

  static const String name = 'PromotionsCampaignsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PromotionsCampaignsScreen();
    },
  );
}

/// generated route for
/// [ReelCategoryFilterScreen]
class ReelCategoryFilterRoute
    extends PageRouteInfo<ReelCategoryFilterRouteArgs> {
  ReelCategoryFilterRoute({
    Key? key,
    String? initialCategoryId,
    List<PageRouteInfo>? children,
  }) : super(
          ReelCategoryFilterRoute.name,
          args: ReelCategoryFilterRouteArgs(
            key: key,
            initialCategoryId: initialCategoryId,
          ),
          initialChildren: children,
        );

  static const String name = 'ReelCategoryFilterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ReelCategoryFilterRouteArgs>(
        orElse: () => const ReelCategoryFilterRouteArgs(),
      );
      return ReelCategoryFilterScreen(
        key: args.key,
        initialCategoryId: args.initialCategoryId,
      );
    },
  );
}

class ReelCategoryFilterRouteArgs {
  const ReelCategoryFilterRouteArgs({this.key, this.initialCategoryId});

  final Key? key;

  final String? initialCategoryId;

  @override
  String toString() {
    return 'ReelCategoryFilterRouteArgs{key: $key, initialCategoryId: $initialCategoryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReelCategoryFilterRouteArgs) return false;
    return key == other.key && initialCategoryId == other.initialCategoryId;
  }

  @override
  int get hashCode => key.hashCode ^ initialCategoryId.hashCode;
}

/// generated route for
/// [ReelsAndStreamViewer]
class ReelsAndStreamViewerRoute
    extends PageRouteInfo<ReelsAndStreamViewerRouteArgs> {
  ReelsAndStreamViewerRoute({
    Key? key,
    List<ReelModel>? reels,
    int? reelInitialIndex,
    bool startWithStream = false,
    required StreamCubit streamCubit,
    List<PageRouteInfo>? children,
  }) : super(
          ReelsAndStreamViewerRoute.name,
          args: ReelsAndStreamViewerRouteArgs(
            key: key,
            reels: reels,
            reelInitialIndex: reelInitialIndex,
            startWithStream: startWithStream,
            streamCubit: streamCubit,
          ),
          initialChildren: children,
        );

  static const String name = 'ReelsAndStreamViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ReelsAndStreamViewerRouteArgs>();
      return ReelsAndStreamViewer(
        key: args.key,
        reels: args.reels,
        reelInitialIndex: args.reelInitialIndex,
        startWithStream: args.startWithStream,
        streamCubit: args.streamCubit,
      );
    },
  );
}

class ReelsAndStreamViewerRouteArgs {
  const ReelsAndStreamViewerRouteArgs({
    this.key,
    this.reels,
    this.reelInitialIndex,
    this.startWithStream = false,
    required this.streamCubit,
  });

  final Key? key;

  final List<ReelModel>? reels;

  final int? reelInitialIndex;

  final bool startWithStream;

  final StreamCubit streamCubit;

  @override
  String toString() {
    return 'ReelsAndStreamViewerRouteArgs{key: $key, reels: $reels, reelInitialIndex: $reelInitialIndex, startWithStream: $startWithStream, streamCubit: $streamCubit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReelsAndStreamViewerRouteArgs) return false;
    return key == other.key &&
        const ListEquality<ReelModel>().equals(reels, other.reels) &&
        reelInitialIndex == other.reelInitialIndex &&
        startWithStream == other.startWithStream &&
        streamCubit == other.streamCubit;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const ListEquality<ReelModel>().hash(reels) ^
      reelInitialIndex.hashCode ^
      startWithStream.hashCode ^
      streamCubit.hashCode;
}

/// generated route for
/// [ReelsGridScreen]
class ReelsGridRoute extends PageRouteInfo<void> {
  const ReelsGridRoute({List<PageRouteInfo>? children})
      : super(ReelsGridRoute.name, initialChildren: children);

  static const String name = 'ReelsGridRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ReelsGridScreen();
    },
  );
}

/// generated route for
/// [ReelsViewerScreen]
class ReelsViewerRoute extends PageRouteInfo<ReelsViewerRouteArgs> {
  ReelsViewerRoute({
    Key? key,
    required List<ReelModel> reels,
    int initialIndex = 0,
    bool isProductVideo = false,
    bool isActive = true,
    List<PageRouteInfo>? children,
  }) : super(
          ReelsViewerRoute.name,
          args: ReelsViewerRouteArgs(
            key: key,
            reels: reels,
            initialIndex: initialIndex,
            isProductVideo: isProductVideo,
            isActive: isActive,
          ),
          initialChildren: children,
        );

  static const String name = 'ReelsViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ReelsViewerRouteArgs>();
      return ReelsViewerScreen(
        key: args.key,
        reels: args.reels,
        initialIndex: args.initialIndex,
        isProductVideo: args.isProductVideo,
        isActive: args.isActive,
      );
    },
  );
}

class ReelsViewerRouteArgs {
  const ReelsViewerRouteArgs({
    this.key,
    required this.reels,
    this.initialIndex = 0,
    this.isProductVideo = false,
    this.isActive = true,
  });

  final Key? key;

  final List<ReelModel> reels;

  final int initialIndex;

  final bool isProductVideo;

  final bool isActive;

  @override
  String toString() {
    return 'ReelsViewerRouteArgs{key: $key, reels: $reels, initialIndex: $initialIndex, isProductVideo: $isProductVideo, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReelsViewerRouteArgs) return false;
    return key == other.key &&
        const ListEquality<ReelModel>().equals(reels, other.reels) &&
        initialIndex == other.initialIndex &&
        isProductVideo == other.isProductVideo &&
        isActive == other.isActive;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const ListEquality<ReelModel>().hash(reels) ^
      initialIndex.hashCode ^
      isProductVideo.hashCode ^
      isActive.hashCode;
}

/// generated route for
/// [ReferralPage]
class ReferralRoute extends PageRouteInfo<void> {
  const ReferralRoute({List<PageRouteInfo>? children})
      : super(ReferralRoute.name, initialChildren: children);

  static const String name = 'ReferralRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ReferralPage();
    },
  );
}

/// generated route for
/// [ReferralWithdrawlPage]
class ReferralWithdrawlRoute extends PageRouteInfo<void> {
  const ReferralWithdrawlRoute({List<PageRouteInfo>? children})
      : super(ReferralWithdrawlRoute.name, initialChildren: children);

  static const String name = 'ReferralWithdrawlRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ReferralWithdrawlPage();
    },
  );
}

/// generated route for
/// [ReportIssueScreen]
class ReportIssueRoute extends PageRouteInfo<void> {
  const ReportIssueRoute({List<PageRouteInfo>? children})
      : super(ReportIssueRoute.name, initialChildren: children);

  static const String name = 'ReportIssueRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ReportIssueScreen();
    },
  );
}

/// generated route for
/// [RequisitesEdit]
class RequisitesEditRoute extends PageRouteInfo<RequisitesEditRouteArgs> {
  RequisitesEditRoute({
    Key? key,
    required User user,
    List<PageRouteInfo>? children,
  }) : super(
          RequisitesEditRoute.name,
          args: RequisitesEditRouteArgs(key: key, user: user),
          initialChildren: children,
        );

  static const String name = 'RequisitesEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RequisitesEditRouteArgs>();
      return RequisitesEdit(key: args.key, user: args.user);
    },
  );
}

class RequisitesEditRouteArgs {
  const RequisitesEditRouteArgs({this.key, required this.user});

  final Key? key;

  final User user;

  @override
  String toString() {
    return 'RequisitesEditRouteArgs{key: $key, user: $user}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequisitesEditRouteArgs) return false;
    return key == other.key && user == other.user;
  }

  @override
  int get hashCode => key.hashCode ^ user.hashCode;
}

/// generated route for
/// [ResultsScreen]
class ResultsRoute extends PageRouteInfo<ResultsRouteArgs> {
  ResultsRoute({
    Key? key,
    int? choseOwner,
    int? countryId,
    String? initialSearch,
    List<PageRouteInfo>? children,
  }) : super(
          ResultsRoute.name,
          args: ResultsRouteArgs(
            key: key,
            choseOwner: choseOwner,
            countryId: countryId,
            initialSearch: initialSearch,
          ),
          initialChildren: children,
        );

  static const String name = 'ResultsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResultsRouteArgs>(
        orElse: () => const ResultsRouteArgs(),
      );
      return ResultsScreen(
        key: args.key,
        choseOwner: args.choseOwner,
        countryId: args.countryId,
        initialSearch: args.initialSearch,
      );
    },
  );
}

class ResultsRouteArgs {
  const ResultsRouteArgs({
    this.key,
    this.choseOwner,
    this.countryId,
    this.initialSearch,
  });

  final Key? key;

  final int? choseOwner;

  final int? countryId;

  final String? initialSearch;

  @override
  String toString() {
    return 'ResultsRouteArgs{key: $key, choseOwner: $choseOwner, countryId: $countryId, initialSearch: $initialSearch}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResultsRouteArgs) return false;
    return key == other.key &&
        choseOwner == other.choseOwner &&
        countryId == other.countryId &&
        initialSearch == other.initialSearch;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      choseOwner.hashCode ^
      countryId.hashCode ^
      initialSearch.hashCode;
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsScreen();
    },
  );
}

/// generated route for
/// [SignIn]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
      : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignIn();
    },
  );
}

/// generated route for
/// [SignUp]
class SignUpRoute extends PageRouteInfo<void> {
  const SignUpRoute({List<PageRouteInfo>? children})
      : super(SignUpRoute.name, initialChildren: children);

  static const String name = 'SignUpRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignUp();
    },
  );
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreen();
    },
  );
}

/// generated route for
/// [StateUserProductDetails]
class StateUserProductDetailsRoute
    extends PageRouteInfo<StateUserProductDetailsRouteArgs> {
  StateUserProductDetailsRoute({
    Key? key,
    required String id,
    required Product results,
    List<PageRouteInfo>? children,
  }) : super(
          StateUserProductDetailsRoute.name,
          args: StateUserProductDetailsRouteArgs(
            key: key,
            id: id,
            results: results,
          ),
          initialChildren: children,
        );

  static const String name = 'StateUserProductDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StateUserProductDetailsRouteArgs>();
      return StateUserProductDetails(
        key: args.key,
        id: args.id,
        results: args.results,
      );
    },
  );
}

class StateUserProductDetailsRouteArgs {
  const StateUserProductDetailsRouteArgs({
    this.key,
    required this.id,
    required this.results,
  });

  final Key? key;

  final String id;

  final Product results;

  @override
  String toString() {
    return 'StateUserProductDetailsRouteArgs{key: $key, id: $id, results: $results}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StateUserProductDetailsRouteArgs) return false;
    return key == other.key && id == other.id && results == other.results;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode ^ results.hashCode;
}

/// generated route for
/// [StreamPage]
class StreamRoute extends PageRouteInfo<StreamRouteArgs> {
  StreamRoute({
    Key? key,
    required String userId,
    bool isActive = true,
    bool keepLivePlayerAlive = false,
    List<PageRouteInfo>? children,
  }) : super(
          StreamRoute.name,
          args: StreamRouteArgs(
            key: key,
            userId: userId,
            isActive: isActive,
            keepLivePlayerAlive: keepLivePlayerAlive,
          ),
          initialChildren: children,
        );

  static const String name = 'StreamRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StreamRouteArgs>();
      return StreamPage(
        key: args.key,
        userId: args.userId,
        isActive: args.isActive,
        keepLivePlayerAlive: args.keepLivePlayerAlive,
      );
    },
  );
}

class StreamRouteArgs {
  const StreamRouteArgs({
    this.key,
    required this.userId,
    this.isActive = true,
    this.keepLivePlayerAlive = false,
  });

  final Key? key;

  final String userId;

  final bool isActive;

  final bool keepLivePlayerAlive;

  @override
  String toString() {
    return 'StreamRouteArgs{key: $key, userId: $userId, isActive: $isActive, keepLivePlayerAlive: $keepLivePlayerAlive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StreamRouteArgs) return false;
    return key == other.key &&
        userId == other.userId &&
        isActive == other.isActive &&
        keepLivePlayerAlive == other.keepLivePlayerAlive;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      userId.hashCode ^
      isActive.hashCode ^
      keepLivePlayerAlive.hashCode;
}

/// generated route for
/// [StreamReelPreview]
class StreamReelPreviewRoute extends PageRouteInfo<StreamReelPreviewRouteArgs> {
  StreamReelPreviewRoute({
    Key? key,
    required StreamModel stream,
    required bool isActive,
    List<PageRouteInfo>? children,
  }) : super(
          StreamReelPreviewRoute.name,
          args: StreamReelPreviewRouteArgs(
            key: key,
            stream: stream,
            isActive: isActive,
          ),
          initialChildren: children,
        );

  static const String name = 'StreamReelPreviewRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StreamReelPreviewRouteArgs>();
      return StreamReelPreview(
        key: args.key,
        stream: args.stream,
        isActive: args.isActive,
      );
    },
  );
}

class StreamReelPreviewRouteArgs {
  const StreamReelPreviewRouteArgs({
    this.key,
    required this.stream,
    required this.isActive,
  });

  final Key? key;

  final StreamModel stream;

  final bool isActive;

  @override
  String toString() {
    return 'StreamReelPreviewRouteArgs{key: $key, stream: $stream, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StreamReelPreviewRouteArgs) return false;
    return key == other.key &&
        stream == other.stream &&
        isActive == other.isActive;
  }

  @override
  int get hashCode => key.hashCode ^ stream.hashCode ^ isActive.hashCode;
}

/// generated route for
/// [Subcategory]
class SubcategoryPickerRoute extends PageRouteInfo<SubcategoryPickerRouteArgs> {
  SubcategoryPickerRoute({
    Key? key,
    required List<Category> list,
    void Function(Category, String)? onUpdate,
    String fullNameCategories = "",
    List<PageRouteInfo>? children,
  }) : super(
          SubcategoryPickerRoute.name,
          args: SubcategoryPickerRouteArgs(
            key: key,
            list: list,
            onUpdate: onUpdate,
            fullNameCategories: fullNameCategories,
          ),
          initialChildren: children,
        );

  static const String name = 'SubcategoryPickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubcategoryPickerRouteArgs>();
      return Subcategory(
        key: args.key,
        list: args.list,
        onUpdate: args.onUpdate,
        fullNameCategories: args.fullNameCategories,
      );
    },
  );
}

class SubcategoryPickerRouteArgs {
  const SubcategoryPickerRouteArgs({
    this.key,
    required this.list,
    this.onUpdate,
    this.fullNameCategories = "",
  });

  final Key? key;

  final List<Category> list;

  final void Function(Category, String)? onUpdate;

  final String fullNameCategories;

  @override
  String toString() {
    return 'SubcategoryPickerRouteArgs{key: $key, list: $list, onUpdate: $onUpdate, fullNameCategories: $fullNameCategories}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubcategoryPickerRouteArgs) return false;
    return key == other.key &&
        const ListEquality<Category>().equals(list, other.list) &&
        fullNameCategories == other.fullNameCategories;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const ListEquality<Category>().hash(list) ^
      fullNameCategories.hashCode;
}

/// generated route for
/// [SubcategoryScreen]
class SubcategoryRoute extends PageRouteInfo<SubcategoryRouteArgs> {
  SubcategoryRoute({
    Key? key,
    required List<Category> children0,
    required String title,
    List<PageRouteInfo>? children,
  }) : super(
          SubcategoryRoute.name,
          args: SubcategoryRouteArgs(
            key: key,
            children: children0,
            title: title,
          ),
          initialChildren: children,
        );

  static const String name = 'SubcategoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubcategoryRouteArgs>();
      return SubcategoryScreen(
        key: args.key,
        children: args.children,
        title: args.title,
      );
    },
  );
}

class SubcategoryRouteArgs {
  const SubcategoryRouteArgs({
    this.key,
    required this.children,
    required this.title,
  });

  final Key? key;

  final List<Category> children;

  final String title;

  @override
  String toString() {
    return 'SubcategoryRouteArgs{key: $key, children: $children, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubcategoryRouteArgs) return false;
    return key == other.key &&
        const ListEquality<Category>().equals(children, other.children) &&
        title == other.title;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const ListEquality<Category>().hash(children) ^
      title.hashCode;
}

/// generated route for
/// [TalkerLogDetailScreen]
class TalkerLogDetailRoute extends PageRouteInfo<TalkerLogDetailRouteArgs> {
  TalkerLogDetailRoute({
    Key? key,
    required TalkerData data,
    List<PageRouteInfo>? children,
  }) : super(
          TalkerLogDetailRoute.name,
          args: TalkerLogDetailRouteArgs(key: key, data: data),
          initialChildren: children,
        );

  static const String name = 'TalkerLogDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TalkerLogDetailRouteArgs>();
      return TalkerLogDetailScreen(key: args.key, data: args.data);
    },
  );
}

class TalkerLogDetailRouteArgs {
  const TalkerLogDetailRouteArgs({this.key, required this.data});

  final Key? key;

  final TalkerData data;

  @override
  String toString() {
    return 'TalkerLogDetailRouteArgs{key: $key, data: $data}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TalkerLogDetailRouteArgs) return false;
    return key == other.key && data == other.data;
  }

  @override
  int get hashCode => key.hashCode ^ data.hashCode;
}

/// generated route for
/// [TalkerLogScreen]
class TalkerLogRoute extends PageRouteInfo<void> {
  const TalkerLogRoute({List<PageRouteInfo>? children})
      : super(TalkerLogRoute.name, initialChildren: children);

  static const String name = 'TalkerLogRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TalkerLogScreen();
    },
  );
}

/// generated route for
/// [TryOnPage]
class TryOnRoute extends PageRouteInfo<void> {
  const TryOnRoute({List<PageRouteInfo>? children})
      : super(TryOnRoute.name, initialChildren: children);

  static const String name = 'TryOnRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TryOnPage();
    },
  );
}

/// generated route for
/// [TryOnProgressPage]
class TryOnProgressRoute extends PageRouteInfo<void> {
  const TryOnProgressRoute({List<PageRouteInfo>? children})
      : super(TryOnProgressRoute.name, initialChildren: children);

  static const String name = 'TryOnProgressRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TryOnProgressPage();
    },
  );
}

/// generated route for
/// [TryOnResultPage]
class TryOnResultRoute extends PageRouteInfo<TryOnResultRouteArgs> {
  TryOnResultRoute({
    Key? key,
    required String imageUrl,
    List<PageRouteInfo>? children,
  }) : super(
          TryOnResultRoute.name,
          args: TryOnResultRouteArgs(key: key, imageUrl: imageUrl),
          initialChildren: children,
        );

  static const String name = 'TryOnResultRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TryOnResultRouteArgs>();
      return TryOnResultPage(key: args.key, imageUrl: args.imageUrl);
    },
  );
}

class TryOnResultRouteArgs {
  const TryOnResultRouteArgs({this.key, required this.imageUrl});

  final Key? key;

  final String imageUrl;

  @override
  String toString() {
    return 'TryOnResultRouteArgs{key: $key, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TryOnResultRouteArgs) return false;
    return key == other.key && imageUrl == other.imageUrl;
  }

  @override
  int get hashCode => key.hashCode ^ imageUrl.hashCode;
}

/// generated route for
/// [UsersScreen]
class UsersRoute extends PageRouteInfo<void> {
  const UsersRoute({List<PageRouteInfo>? children})
      : super(UsersRoute.name, initialChildren: children);

  static const String name = 'UsersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UsersScreen();
    },
  );
}

/// generated route for
/// [WebViewScreen]
class WebViewRoute extends PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    Key? key,
    required String url,
    VoidCallback? onPmtSuccess,
    List<PageRouteInfo>? children,
  }) : super(
          WebViewRoute.name,
          args:
              WebViewRouteArgs(key: key, url: url, onPmtSuccess: onPmtSuccess),
          initialChildren: children,
        );

  static const String name = 'WebViewRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return WebViewScreen(
        key: args.key,
        url: args.url,
        onPmtSuccess: args.onPmtSuccess,
      );
    },
  );
}

class WebViewRouteArgs {
  const WebViewRouteArgs({this.key, required this.url, this.onPmtSuccess});

  final Key? key;

  final String url;

  final VoidCallback? onPmtSuccess;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, url: $url, onPmtSuccess: $onPmtSuccess}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WebViewRouteArgs) return false;
    return key == other.key &&
        url == other.url &&
        onPmtSuccess == other.onPmtSuccess;
  }

  @override
  int get hashCode => key.hashCode ^ url.hashCode ^ onPmtSuccess.hashCode;
}
