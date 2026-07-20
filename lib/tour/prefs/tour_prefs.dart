import 'package:shared_preferences/shared_preferences.dart';

class TourPrefs {
  static const _kSignInTourPending = 'tour_signin_pending';
  static const _kStreamIntroPending = 'tour_stream_intro_pending';
  static const _kTourDone = 'tour_done';
  static const _kFirstLaunchDone = 'first_launch_done';

  static Future<bool> isFirstRun() async {
    final sp = await SharedPreferences.getInstance();
    return !(sp.getBool(_kFirstLaunchDone) ?? false);
  }

  static Future<void> markFirstLaunchDone() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kFirstLaunchDone, true);
  }

  static Future<bool> isTourDone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kTourDone) ?? false;
  }

  static Future<void> markTourDone() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kTourDone, true);
  }

  static Future<void> markSignInTourPending() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSignInTourPending, true);
  }

  static Future<bool> consumeSignInTourPending() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getBool(_kSignInTourPending) ?? false;
    if (v) await sp.setBool(_kSignInTourPending, false);
    return v;
  }

  static Future<void> markStreamIntroPending() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kStreamIntroPending, true);
  }

  static Future<bool> consumeStreamIntroPending() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getBool(_kStreamIntroPending) ?? false;
    if (v) await sp.setBool(_kStreamIntroPending, false);
    return v;
  }
}
