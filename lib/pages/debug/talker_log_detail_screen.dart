import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optombai/core/debug/dio_curl_builder.dart';
import 'package:talker_dio_logger/dio_logs.dart';
import 'package:talker_flutter/talker_flutter.dart';

@RoutePage(name: 'TalkerLogDetailRoute')
class TalkerLogDetailScreen extends StatelessWidget {
  const TalkerLogDetailScreen({super.key, required this.data});

  final TalkerData data;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final options = _requestOptions();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242424),
        foregroundColor: Colors.white,
        title: Text(data.title ?? 'Log detail'),
        actions: [
          if (options != null)
            IconButton(
              tooltip: 'Copy as cURL',
              icon: const Icon(Icons.terminal),
              onPressed: () => _copyCurl(context, options),
            ),
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copyAll(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _DetailSection(section: sections[i]),
      ),
    );
  }

  RequestOptions? _requestOptions() {
    final log = data;
    if (log is DioRequestLog) return log.requestOptions;
    if (log is DioResponseLog) return log.response.requestOptions;
    if (log is DioErrorLog) return log.dioException.requestOptions;
    return null;
  }

  List<_Section> _buildSections() {
    final log = data;
    final sections = <_Section>[];

    sections.add(_Section(
      title: 'Overview',
      body: [
        'Type: ${log.runtimeType}',
        if (log.title != null) 'Title: ${log.title}',
        'Time: ${log.displayTime()}',
        if (log.key != null) 'Key: ${log.key}',
      ].join('\n'),
    ));

    if (log is DioRequestLog) {
      _appendRequest(sections, log.requestOptions);
    } else if (log is DioResponseLog) {
      _appendRequest(sections, log.response.requestOptions);
      _appendResponse(sections, log.response, log.responseTime);
    } else if (log is DioErrorLog) {
      _appendRequest(sections, log.dioException.requestOptions);
      final response = log.dioException.response;
      if (response != null) {
        _appendResponse(sections, response, log.responseTime);
      }
      sections.add(_Section(
        title: 'Error',
        body: [
          'Type: ${log.dioException.type}',
          if (log.dioException.message != null)
            'Message: ${log.dioException.message}',
          if (log.dioException.error != null)
            'Underlying: ${log.dioException.error}',
        ].join('\n'),
      ));
    } else {
      sections.add(_Section(
        title: 'Message',
        body: log.generateTextMessage(),
      ));
    }

    if (log.stackTrace != null) {
      sections.add(_Section(
        title: 'Stack trace',
        body: log.stackTrace.toString(),
      ));
    }

    return sections;
  }

  void _appendRequest(List<_Section> sections, RequestOptions options) {
    sections.add(_Section(
      title: 'Request',
      body: [
        'Method: ${options.method}',
        'URL: ${options.uri}',
        if (options.queryParameters.isNotEmpty)
          'Query: ${_formatJson(options.queryParameters)}',
      ].join('\n'),
    ));

    if (options.headers.isNotEmpty) {
      sections.add(_Section(
        title: 'Request headers',
        body: _formatJson(options.headers),
      ));
    }

    final body = options.data;
    if (body != null) {
      sections.add(_Section(
        title: 'Request body',
        body: _formatBody(body),
      ));
    }
  }

  void _appendResponse(
    List<_Section> sections,
    Response<dynamic> response,
    int? responseTime,
  ) {
    sections.add(_Section(
      title: 'Response',
      body: [
        'Status: ${response.statusCode}'
            '${response.statusMessage != null ? ' ${response.statusMessage}' : ''}',
        if (responseTime != null) 'Time: $responseTime ms',
      ].join('\n'),
    ));

    if (response.headers.map.isNotEmpty) {
      sections.add(_Section(
        title: 'Response headers',
        body: _formatJson(response.headers.map),
      ));
    }

    if (response.data != null) {
      sections.add(_Section(
        title: 'Response body',
        body: _formatBody(response.data),
      ));
    }
  }

  String _formatJson(Object value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatBody(Object body) {
    if (body is FormData) {
      final fields = <String, Object?>{
        for (final f in body.fields) f.key: f.value,
        for (final f in body.files)
          f.key: {
            'filename': f.value.filename,
            'contentType': f.value.contentType?.toString(),
            'bytes': f.value.length,
          },
      };
      return _formatJson(fields);
    }
    if (body is Map || body is List) return _formatJson(body);
    return body.toString();
  }

  Future<void> _copyCurl(BuildContext context, RequestOptions options) async {
    await Clipboard.setData(ClipboardData(text: options.toCurl()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('cURL copied')),
    );
  }

  Future<void> _copyAll(BuildContext context) async {
    final text = data.generateTextMessage();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied')),
    );
  }
}

class _Section {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy ${section.title.toLowerCase()}',
                icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                onPressed: () => _copy(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            section.body,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: section.body));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${section.title} copied')),
    );
  }
}
