import 'dart:convert';

import 'package:dio/dio.dart';

/// Converts a Dio [RequestOptions] into a shell-ready `curl` command so
/// developers can replay requests from the Talker debug screen.
extension RequestOptionsCurlExtension on RequestOptions {
  String toCurl() {
    final parts = <String>["curl -X ${method.toUpperCase()}"];

    final urlWithQuery = _urlWithQuery();
    parts.add("'${_shellEscape(urlWithQuery)}'");

    headers.forEach((key, value) {
      parts.add("-H '${_shellEscape('$key: $value')}'");
    });

    final body = data;
    if (body != null) {
      if (body is FormData) {
        for (final field in body.fields) {
          parts.add("-F '${_shellEscape('${field.key}=${field.value}')}'");
        }
        for (final file in body.files) {
          final filename = file.value.filename ?? 'file';
          parts.add("-F '${_shellEscape('${file.key}=@$filename')}'");
        }
      } else if (body is Map || body is List) {
        final json = jsonEncode(body);
        parts.add("-d '${_shellEscape(json)}'");
      } else {
        parts.add("-d '${_shellEscape(body.toString())}'");
      }
    }

    return parts.join(' \\\n  ');
  }

  String _urlWithQuery() {
    final base = uri.toString();
    if (queryParameters.isEmpty) return base;
    final qp = queryParameters.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value?.toString() ?? '')}')
        .join('&');
    return base.contains('?') ? '$base&$qp' : '$base?$qp';
  }

  String _shellEscape(String input) => input.replaceAll("'", r"'\''");
}
