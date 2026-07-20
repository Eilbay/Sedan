# Онбординг разработчика

Цель: за один проход поднять окружение, получить секреты и собрать проект под iOS и Android.

## 1. Требования

| Инструмент | Версия | Примечание |
|---|---|---|
| Flutter | **3.35.7** | строго; зафиксирована в `.fvmrc` |
| fvm | актуальная | менеджер версий Flutter, обязателен |
| Dart SDK | `>=3.0.0 <4.0.0` | идёт с Flutter |
| Xcode | под iOS target **18.5** | + CocoaPods |
| Android Studio / SDK | `compileSdk 36`, NDK `28.2.13676358` | desugaring (см. ниже) |
| just (опц.) | — | запуск рецептов из `justfile` |

```bash
fvm install              # подтянет Flutter 3.35.7
fvm flutter --version    # проверка
```

## 2. Секреты и конфиги (НЕ в git)

Эти файлы отсутствуют в репозитории — получите их у команды и положите по путям:

| Файл | Назначение | Без него |
|---|---|---|
| `/.env` | ключи платежей (Finik, Paybox) | приложение стартует, но оплата не работает |
| `android/keystore.properties` | подпись релиза Android | release-сборка Android упадёт |
| `android/key.jks` | keystore | то же |
| `ios/Runner/GoogleService-Info.plist` | Firebase для iOS | Firebase на iOS не инициализируется |

`google-services.json` (Android) и `lib/firebase_options.dart` уже в репозитории.

### Содержимое `.env`
```env
FINIK_API_KEY=...
FINIK_ACCOUNT_ID=...
FINIK_IS_BETA=true            # true/false
MERCHANT_ID=...               # FreedomPay/Paybox, int
SECRET_KEY=...                # Paybox
MERCHANT_CURRENCY=KGS
PAYBOX_TEST_MODE=false
```
> `.env.example` отсутствует — создайте `.env` вручную по этому шаблону.

### `keystore.properties`
```properties
storeFile=key.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Полная таблица «где менять ключи» — в [корневом README](../README.md#где-менять-ключи-и-конфигурацию-).

## 3. Первый запуск

```bash
fvm flutter pub get
# Кодогенерация маршрутов auto_route (обязательно: app_router.gr.dart — part-файл)
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

## 4. Setup-гочи (важно — без них сборки падают)

### iOS: explicit modules отключены в Podfile
`ios/Podfile` (`post_install`) принудительно ставит на **каждый** pod-таргет:
```ruby
config.build_settings['CLANG_ENABLE_EXPLICIT_MODULES'] = 'NO'
config.build_settings['SWIFT_ENABLE_EXPLICIT_MODULES'] = 'NO'
config.build_settings['SWIFT_PRECOMPILE_BRIDGING_HEADER'] = 'NO'
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
```
**Зачем:** на Xcode 16 explicit (precompiled) модули оставляют устаревший `.pcm`, и сборка падает
с `File ... has been modified since the module file ... was built` (например, после изменения
заголовка `in_app_purchase_storekit`). Флаги на Runner-таргете **не наследуются** подами — поэтому
выставляются в `post_install`. **Не удалять.**

При странных ошибках модулей:
```bash
cd ios && pod deintegrate && pod install && cd ..
fvm flutter clean && fvm flutter pub get
```

### Android: core library desugaring
`android/app/build.gradle` требует desugaring (нужно для `flutter_local_notifications` 17.x):
```gradle
compileOptions { coreLibraryDesugaringEnabled = true }
dependencies { coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.4" }
```
Java 8 совместимость (`sourceCompatibility`/`targetCompatibility`/`jvmTarget = VERSION_1_8`).

### Предпочитать корневые фиксы, а не повторный `flutter clean`
Если что-то «лечится» только через `flutter clean` — ищите корневую причину (конфиг Podfile/Gradle),
а не делайте clean привычкой.

## 5. Полезные команды

### justfile
```bash
just deps      # flutter pub get
just analyze   # flutter analyze
just run       # запуск
just apk       # release APK
just aab       # release App Bundle
just release   # clean → deps → apk → aab
```

## 6. Definition of Done (правила проекта)

- После любых правок Dart: `fvm flutter analyze` → **0 errors** (baseline info ≈ 258–272).
- Комментарии в коде — на английском.
- Навигация — только `auto_route`. Новые эндпоинты — только в `ApiEndpoints`.
- Без helper-методов: extension-методы / сервисы / use-case классы.
- Backend-контракты проверять курлами; имя поля брать из ответа бэка, не из swagger.
