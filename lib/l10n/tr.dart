import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';
import 'package:optombai/core/import_links.dart';

const _dict = <String, Map<String, String>>{
  'nav_home': {
    'ru': 'Главная',
    'en': 'Home',
    'de': 'Start',
    'tr': 'Ana',
    'ky': 'Башкы',
    'zh-cn': '首页'
  },
  'nav_categories': {
    'ru': 'Категории',
    'en': 'Categories',
    'de': 'Kategorien',
    'tr': 'Kategoriler',
    'ky': 'Категориялар',
    'zh-cn': '分类'
  },
  'nav_streams': {
    'ru': 'Лента',
    'en': 'Feed',
    'de': 'Feed',
    'tr': 'Akış',
    'ky': 'Лента',
    'zh-cn': '动态'
  },
  'nav_add': {
    'ru': 'Добавить',
    'en': 'Add',
    'de': 'Hinzufügen',
    'tr': 'Ekle',
    'ky': 'Кошуу',
    'zh-cn': '添加'
  },
  'nav_cart': {
    'ru': 'Корзина',
    'en': 'Cart',
    'de': 'Warenkorb',
    'tr': 'Sepet',
    'ky': 'Себет',
    'zh-cn': '购物车'
  },
  'nav_profile': {
    'ru': 'Профиль',
    'en': 'Profile',
    'de': 'Profil',
    'tr': 'Profil',
    'ky': 'Профиль',
    'zh-cn': '我的'
  },
  'nav_messages': {
    'ru': 'Чаты',
    'en': 'Chats',
    'de': 'Chats',
    'tr': 'Sohbetler',
    'ky': 'Чаттар',
    'zh-cn': '聊天',
  },
  'nav_active': {
    'ru': 'Сообщения',
    'en': 'Messages',
    'de': 'Nachrichten',
    'tr': 'Mesajlar',
    'ky': 'Билдирүүлөр',
    'zh-cn': '消息',
  },
  'search_hint': {
    'ru': 'Поиск авто на Sedan.Kg',
    'en': 'Search cars on Sedan.Kg',
    'de': 'Autos auf Sedan.Kg suchen',
    'tr': 'Sedan.Kg’de araç ara',
    'ky': 'Sedan.Kg’ден авто издөө',
    'zh-cn': '在 Sedan.Kg 搜索汽车',
  },
  'search_loading': {
    'ru': 'Поиск...',
    'en': 'Searching...',
    'de': 'Suche...',
    'tr': 'Aranıyor...',
    'ky': 'Издөө...',
    'zh-cn': '搜索中…',
  },
  'search_empty': {
    'ru': 'Ничего не найдено',
    'en': 'Nothing found',
    'de': 'Nichts gefunden',
    'tr': 'Sonuç bulunamadı',
    'ky': 'Эч нерсе табылган жок',
    'zh-cn': '未找到结果',
  },
  'tour_search': {
    'ru': 'Поиск по товарам и поставщикам.',
    'en': 'Search products and suppliers.',
    'de': 'Suche nach Produkten und Anbietern.',
    'tr': 'Ürün ve tedarikçi arayın.',
    'ky': 'Товарларды жана сатуучуларды издеңиз.',
    'zh-cn': '搜索商品和供应商。',
  },
  'tour_sections': {
    'ru': 'Разделы: товары, производители, поставщики.',
    'en': 'Sections: products, manufacturers, suppliers.',
    'de': 'Bereiche: Produkte, Hersteller, Anbieter.',
    'tr': 'Bölümler: ürünler, üreticiler, tedarikçiler.',
    'ky': 'Бөлүмдөр: товарлар, өндүрүүчүлөр, жеткирүүчүлөр.',
    'zh-cn': '板块：商品、制造商、供应商。',
  },
  'tour_filters': {
    'ru': 'Фильтры по стране, категории, цене и сортировке.',
    'en': 'Filters by country, category, price and sorting.',
    'de': 'Filter nach Land, Kategorie, Preis und Sortierung.',
    'tr': 'Ülke, kategori, fiyat ve sıralama filtreleri.',
    'ky': 'Өлкө, категория, баа жана сорттоо боюнча фильтрлер.',
    'zh-cn': '按国家、分类、价格和排序筛选。',
  },
  'tour_open_product': {
    'ru': 'Откройте карточку, чтобы посмотреть товар и связаться с продавцом.',
    'en': 'Open a card to view details and contact the seller.',
    'de':
        'Öffnen Sie eine Karte, um Details zu sehen und den Verkäufer zu kontaktieren.',
    'tr': 'Detayları görmek ve satıcıyla iletişime geçmek için kartı açın.',
    'ky': 'Маалыматты көрүп, сатуучу менен байланышуу үчүн карточканы ачыңыз.',
    'zh-cn': '打开卡片查看详情并联系卖家。',
  },
  'tour_next': {
    'ru': 'Далее',
    'en': 'Next',
    'de': 'Weiter',
    'tr': 'İleri',
    'ky': 'Кийинки',
    'zh-cn': '下一步',
  },
  'tour_skip': {
    'ru': 'Пропустить',
    'en': 'Skip',
    'de': 'Überspringen',
    'tr': 'Atla',
    'ky': 'Өткөрүп жиберүү',
    'zh-cn': '跳过',
  },
  'tour_start_work': {
    'ru': 'Начать работу',
    'en': 'Get started',
    'de': 'Loslegen',
    'tr': 'Başla',
    'ky': 'Баштоо',
    'zh-cn': '开始使用',
  },
  'tour_screen2': {
    'ru':
        '📦 Товары — каталог оптовых предложений\n🏭 Производители — прямые фабрики и цеха\n🤝 Поставщики — проверенные продавцы\n\nПросматривайте товары и связывайтесь с партнёрами бесплатно после авторизации.',
    'en':
        '📦 Products — wholesale catalog\n🏭 Manufacturers — factories and workshops\n🤝 Suppliers — verified sellers\n\nBrowse and contact partners for free after login.',
    'de':
        '📦 Produkte — Großhandelskatalog\n🏭 Hersteller — Fabriken und Werkstätten\n🤝 Anbieter — geprüfte Verkäufer\n\nNach Login kostenlos ansehen und kontaktieren.',
    'tr':
        '📦 Ürünler — toptan katalog\n🏭 Üreticiler — fabrikalar ve atölyeler\n🤝 Tedarikçiler — doğrulanmış satıcılar\n\nGirişten sonra ücretsiz inceleyin ve iletişime geçin.',
    'ky':
        '📦 Товарлар — оптом каталог\n🏭 Өндүрүүчүлөр — фабрика/цехтер\n🤝 Жеткирүүчүлөр — текшерилген сатуучулар\n\nКиргенден кийин акысыз көрүп, байланышсаңыз болот.',
    'zh-cn': '📦 商品—批发目录\n🏭 制造商—工厂与作坊\n🤝 供应商—已验证卖家\n\n登录后可免费浏览并联系。',
  },
  'tour_screen3': {
    'ru':
        '📑 Оптом заказы — заявки от оптовых клиентов\n🛍 Покупатели — база активных закупщиков\n\nДоступ к этим разделам открывается при подключении Business-подписки.',
    'en':
        '📑 Wholesale orders — requests from buyers\n🛍 Buyers — active wholesale clients\n\nAccess is available with a Business subscription.',
    'de':
        '📑 Großhandelsbestellungen — Anfragen\n🛍 Käufer — aktive закупщики\n\nZugriff mit Business-Abo verfügbar.',
    'tr':
        '📑 Toptan siparişler — alıcı talepleri\n🛍 Alıcılar — aktif müşteriler\n\nErişim Business aboneliği ile açılır.',
    'ky':
        '📑 Оптом заказдар — суроо-талаптар\n🛍 Сатып алуучулар — активдүү базa\n\nБул бөлүмдөр Business жазылуусу менен ачылат.',
    'zh-cn': '📑 批发订单—买家需求\n🛍 买家—活跃批发客户\n\n需开通 Business 订阅后访问。',
  },
  'tour_screen4': {
    'ru':
        'Войдите или зарегистрируйтесь, чтобы получить доступ к личному кабинету и функциям платформы.',
    'en': 'Log in or sign up to access your account and platform features.',
    'de':
        'Melden Sie sich an oder registrieren Sie sich, um Zugriff zu erhalten.',
    'tr': 'Hesabınıza ve özelliklere erişmek için giriş yapın veya kayıt olun.',
    'ky': 'Жеке кабинет жана функциялар үчүн кириңиз же катталыңыз.',
    'zh-cn': '登录或注册以使用个人账户与平台功能。',
  },
  'tour_screen5': {
    'ru': 'Общайтесь напрямую с пользователями и технической поддержкой.',
    'en': 'Chat directly with users and support.',
    'de': 'Chatten Sie direkt mit Nutzern und Support.',
    'tr': 'Kullanıcılar ve destek ile doğrudan sohbet edin.',
    'ky': 'Колдонуучулар жана колдоо менен түз чатташыңыз.',
    'zh-cn': '与用户和客服直接聊天。',
  },
  'tour_screen6': {
    'ru':
        'Смотрите видео-обзоры и подключайтесь к прямым эфирам пользователей.',
    'en': 'Watch videos and join user live streams.',
    'de': 'Videos ansehen und Live-Streams beitreten.',
    'tr': 'Videoları izleyin ve canlı yayınlara katılın.',
    'ky': 'Видеолорду көрүп, түз эфирлерге кошулуңуз.',
    'zh-cn': '观看视频并加入直播。',
  },
  'tour_screen7': {
    'ru':
        'Размещайте свои товары и публикуйте объявления для оптовых покупателей.',
    'en': 'Add products and publish offers for wholesale buyers.',
    'de': 'Produkte hinzufügen und Angebote veröffentlichen.',
    'tr': 'Ürün ekleyin ve toptan alıcılar için ilan verin.',
    'ky': 'Товар кошуп, оптом сатып алуучулар үчүн жарыялаңыз.',
    'zh-cn': '发布商品并面向批发买家发布信息。',
  },
  'tour_screen8': {
    'ru': 'Ознакомьтесь с условиями, подписками и возможностями платформы.',
    'en': 'Learn about terms, subscriptions and platform features.',
    'de': 'Infos zu Bedingungen, Abos und Funktionen.',
    'tr': 'Koşullar, abonelikler ve özellikler hakkında bilgi alın.',
    'ky': 'Шарттар, жазылуулар жана мүмкүнчүлүктөр менен таанышыңыз.',
    'zh-cn': '了解条款、订阅和平台功能。',
  },
  'tour_goods': {
    'ru': '📦 Товары — каталог оптовых предложений',
    'en': '📦 Goods — wholesale catalog',
    'de': '📦 Waren — Großhandelskatalog',
    'tr': '📦 Ürünler — toptan katalog',
    'ky': '📦 Товарлар — оптом каталог',
    'zh-cn': '📦 商品—批发目录',
  },
  'tour_manufacturers': {
    'ru': '🏭 Производители — прямые фабрики и цеха',
    'en': '🏭 Manufacturers — factories and workshops',
    'de': '🏭 Hersteller — Fabriken und Werkstätten',
    'tr': '🏭 Üreticiler — fabrikalar ve atölyeler',
    'ky': '🏭 Өндүрүүчүлөр — фабрика/цехтер',
    'zh-cn': '🏭 制造商—工厂与作坊',
  },
  'tour_suppliers': {
    'ru': '🤝 Поставщики — проверенные продавцы',
    'en': '🤝 Suppliers — verified sellers',
    'de': '🤝 Anbieter — geprüfte Verkäufer',
    'tr': '🤝 Tedarikçiler — doğrulanmış satıcılar',
    'ky': '🤝 Жеткирүүчүлөр — текшерилген сатуучулар',
    'zh-cn': '🤝 供应商—已验证卖家',
  },
  'tour_orders': {
    'ru': '📑 Оптом заказы — заявки от оптовых клиентов',
    'en': '📑 Wholesale orders — buyer requests',
    'de': '📑 Großhandelsbestellungen — Anfragen',
    'tr': '📑 Toptan siparişler — alıcı talepleri',
    'ky': '📑 Оптом заказдар — суроо-талаптар',
    'zh-cn': '📑 批发订单—买家需求',
  },
  'tour_buyers': {
    'ru': '🛍 Покупатели — база активных закупщиков',
    'en': '🛍 Buyers — active wholesale clients',
    'de': '🛍 Käufer — aktive закупщики',
    'tr': '🛍 Alıcılar — aktif müşteriler',
    'ky': '🛍 Сатып алуучулар — активдүү базa',
    'zh-cn': '🛍 买家—活跃批发客户',
  },
  'tour_step0_intro': {
    'ru': '🟢 Товары, Производители, Поставщики\n\n'
        '📦 Товары — каталог оптовых предложений\n'
        '🏭 Производители — прямые фабрики и цеха\n'
        '🤝 Поставщики — проверенные продавцы\n\n'
        'Просматривайте товары и связывайтесь с партнёрами бесплатно после авторизации.',
    'en': '🟢 Goods, Manufacturers, Suppliers\n\n'
        '📦 Goods — wholesale offers catalog\n'
        '🏭 Manufacturers — factories and workshops\n'
        '🤝 Suppliers — verified sellers\n\n'
        'Browse goods and contact partners for free after login.',
    'de': '🟢 Waren, Hersteller, Anbieter\n\n'
        '📦 Waren — Großhandelsangebote\n'
        '🏭 Hersteller — Fabriken und Werkstätten\n'
        '🤝 Anbieter — geprüfte Verkäufer\n\n'
        'Nach Login kostenlos ansehen und Partner kontaktieren.',
    'tr': '🟢 Ürünler, Üreticiler, Tedarikçiler\n\n'
        '📦 Ürünler — toptan teklifler kataloğu\n'
        '🏭 Üreticiler — fabrikalar ve atölyeler\n'
        '🤝 Tedarikçiler — doğrulanmış satıcılar\n\n'
        'Girişten sonra ücretsiz inceleyin ve iletişime geçin.',
    'ky': '🟢 Товарлар, Өндүрүүчүлөр, Жеткирүүчүлөр\n\n'
        '📦 Товарлар — оптом сунуштар каталогу\n'
        '🏭 Өндүрүүчүлөр — фабрика/цехтер\n'
        '🤝 Жеткирүүчүлөр — текшерилген сатуучулар\n\n'
        'Киргенден кийин акысыз көрүп, байланыша аласыз.',
    'zh-cn': '🟢 商品、制造商、供应商\n\n'
        '📦 商品—批发目录\n'
        '🏭 制造商—工厂与作坊\n'
        '🤝 供应商—已验证卖家\n\n'
        '登录后可免费浏览并联系。',
  },
  'tour_step1_intro': {
    'ru': '🟢 Заказы и Покупатели\n\n'
        '📑 Оптом заказы — заявки от оптовых клиентов\n'
        '🛍 Покупатели — база активных закупщиков\n',
    'en': '🟢 Orders and Buyers\n\n'
        '📑 Wholesale orders — buyer requests\n'
        '🛍 Buyers — active wholesale clients\n',
    'de': '🟢 Bestellungen und Käufer\n\n'
        '📑 Großhandelsbestellungen — Anfragen\n'
        '🛍 Käufer — aktive Großabnehmer\n',
    'tr': '🟢 Siparişler ve Alıcılar\n\n'
        '📑 Toptan siparişler — alıcı talepleri\n'
        '🛍 Alıcılar — aktif toptan müşteriler\n',
    'ky': '🟢 Заказдар жана Сатып алуучулар\n\n'
        '📑 Оптом заказдар — суроо-талаптар\n'
        '🛍 Сатып алуучулар — активдүү закупщиктер базасы\n',
    'zh-cn': '🟢 订单与买家\n\n'
        '📑 批发订单—买家需求\n'
        '🛍 买家—活跃批发客户\n\n',
  },
};

String tr(BuildContext context, String key) {
  final bloc = context.read<LanguageBloc>();
  final state = bloc.state;
  final lang = state is LanguageChangedState ? state.language : 'ru';

  return _dict[key]?[lang] ?? _dict[key]?['ru'] ?? key;
}
