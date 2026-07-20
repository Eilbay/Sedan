import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_paybox_2/src/api/constants.dart';
import 'random.dart';

extension SignedParams on Map<String, dynamic> {
  Map<String, dynamic> signedParams(String url, {String? secretKey = ''}) {
    var sorted = <String, dynamic>{};
    var paths = url.split('/');
    var sig = paths.last;
    this[SALT] = Random().randomString();
    var keysList = keys.toList();
    keysList.sort();
    for (var key in keysList) {
      if (containsKey(key) && this[key] != null) {
        sig += ';';
        sig += "${this[key]}";
        sorted[key] = this[key];
      }
    }
    sig += ";$secretKey";
    sorted[SIG] = md5.convert(utf8.encode(sig)).toString();
    return sorted;
  }
}