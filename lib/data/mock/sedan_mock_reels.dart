import 'package:optombai/data/models/reel/reel_model.dart';

const _videoPath = 'assets/sedan/videos';

final _owner = ReelOwner(
  id: 'mock-aibek-auto',
  username: 'Aibek.Auto',
  image: 'assets/mock/mock_aibek.png',
  accountVerified: true,
  isVerified: true,
  userStatus: const ReelUserStatus(isPremium: false),
  country: const ReelCountry(
    id: 1,
    title: 'Кыргызстан',
    iso2: 'KG',
  ),
  suppliers: [
    ReelSupplier(
      id: 1,
      market: const ReelMarket(id: 1, name: 'Sedan.Kg'),
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ],
);

final sedanMockReels = <ReelModel>[
  ReelModel(
    id: 'sedan_mock_hyundai_palisade_2019',
    slug: 'hyundai-palisade-2019',
    createdAt: DateTime(2026, 7, 26),
    description: '''
Марка: HYUNDAI PALISADE
Год: 2019
Об: 2.2 дизель
Пробег: 156км
Цена: 20.800 \$ торг''',
    views: 0,
    videoUrl: '$_videoPath/IMG_2850.MP4',
    owner: _owner,
    likes: 0,
    isLiked: false,
    cardType: 'promo',
  ),
  ReelModel(
    id: 'sedan_mock_kia_morning_2020',
    slug: 'kia-morning-2020',
    createdAt: DateTime(2026, 7, 26),
    description: '''
Марка: KIA MORNING
Год: 2020
Об: 1.0 бенз
Пробег: 167км
Цена: 7800 \$ мини торг''',
    views: 0,
    videoUrl: '$_videoPath/IMG_2853.MP4',
    owner: _owner,
    likes: 0,
    isLiked: false,
  ),
  ReelModel(
    id: 'sedan_mock_hyundai_sonata_2019',
    slug: 'hyundai-sonata-2019',
    createdAt: DateTime(2026, 7, 26),
    description: '''
Хендай Соната
Год: 2019
Объем: 2.0 газ
Цена: 10200 \$
Тел: 0771 00 04 04''',
    views: 0,
    videoUrl: '$_videoPath/IMG_2855.MP4',
    owner: _owner,
    likes: 0,
    isLiked: false,
  ),
  ReelModel(
    id: 'sedan_mock_hyundai_porter_2001',
    slug: 'hyundai-porter-2001',
    createdAt: DateTime(2026, 7, 26),
    description: '''
Хендай Портер
Год: 2001
Объем: 2.5 дизель
Цена: 700.000 сом''',
    views: 0,
    videoUrl: '$_videoPath/IMG_2858.MP4',
    owner: _owner,
    likes: 0,
    isLiked: false,
  ),
  ReelModel(
    id: 'sedan_mock_kia_rio_2016',
    slug: 'kia-rio-2016',
    createdAt: DateTime(2026, 7, 26),
    description: '''
Киа Рио
Год: 2016
Объем: 1.6 бензин
Цена: 520 000 сом''',
    views: 0,
    videoUrl: '$_videoPath/IMG_2860.MP4',
    owner: _owner,
    likes: 0,
    isLiked: false,
  ),
  ReelModel(
    id: 'sedan_mock_hyundai_grandeur_2020',
    slug: 'hyundai-grandeur-2020',
    createdAt: DateTime(2026, 7, 26),
    description: '''
Марка: Hyundai Grandeur
Год: 2020
Объем: 2.5 бензин
Цена: 13 300\$''',
    views: 0,
    videoUrl: '$_videoPath/IMG_2863.MP4',
    owner: _owner,
    likes: 0,
    isLiked: false,
  ),
];

ReelListModel sedanMockReelList() {
  return ReelListModel(
    count: sedanMockReels.length,
    results: sedanMockReels,
  );
}

bool isSedanMockReelId(String reelId) => reelId.startsWith('sedan_mock_');
