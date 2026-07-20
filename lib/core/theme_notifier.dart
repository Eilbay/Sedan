import 'package:flutter/material.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/appColors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

const _noTransitionTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoTransitionBuilder(),
    TargetPlatform.iOS: _NoTransitionBuilder(),
  },
);

class ThemeNotifier extends ChangeNotifier {
  static const _kIsDarkKey = 'isDarkMode';

  static const bool _kDefaultIsDark = true;

  bool _isDarkMode = _kDefaultIsDark;
  bool _isRegister = false;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;
  bool get isRegister => _isRegister;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeNotifier() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('[AUTH] ThemeNotifier._init prefsReady=true');
    _getValueRegister();
    await _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    if (!_prefs.containsKey(_kIsDarkKey)) {
      await _prefs.setBool(_kIsDarkKey, _kDefaultIsDark);
      _isDarkMode = _kDefaultIsDark;
    } else {
      _isDarkMode = _prefs.getBool(_kIsDarkKey) ?? _kDefaultIsDark;
    }
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool(_kIsDarkKey, isDark);
    notifyListeners();
  }

  Future<void> toggleTheme() => setTheme(!_isDarkMode);

  ThemeData getTheme() => _isDarkMode ? darkTheme : lightTheme;

  void _getValueRegister() {
    final tokenPresent = (_prefs.getString(TOKEN_KEY) ?? '').isNotEmpty;
    _isRegister = tokenPresent || (_prefs.getBool(REGISTER_KEY) ?? false);
    debugPrint(
      '[AUTH] ThemeNotifier._getValueRegister tokenPresent=$tokenPresent '
      'storedRegister=${_prefs.getBool(REGISTER_KEY) ?? false} '
      'effectiveRegister=$_isRegister',
    );
  }

  Future<void> setRegistrationStatus(bool isRegistered) async {
    final before = _isRegister;
    _isRegister = isRegistered;
    notifyListeners();
    await _prefs.setBool(REGISTER_KEY, isRegistered);
    debugPrint(
      '[AUTH] ThemeNotifier.setRegistrationStatus($isRegistered) '
      'before=$before after=$_isRegister',
    );
  }

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    pageTransitionsTheme: _noTransitionTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightAppBar,
      iconTheme: IconThemeData(color: AppColors.lightBottomIcons),
    ),
    iconTheme: const IconThemeData(color: AppColors.lightBottomIcons),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.lightTitle,
          fontSize: 24,
          fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: AppColors.lightSubtitle, fontSize: 12),
      labelLarge: TextStyle(color: AppColors.lightCurrency, fontSize: 18),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    pageTransitionsTheme: _noTransitionTheme,
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: AppColors.darkSubtitle, fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontSize: 18),
    ),
  );
}
