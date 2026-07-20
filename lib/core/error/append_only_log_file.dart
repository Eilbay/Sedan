import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persistent, size-capped, rotating append-only log file.
///
/// Shared building block behind `CrashLogFile` and `ReelLogFile` — each
/// just points this at a different file name so unrelated log streams
/// don't dilute each other.
class AppendOnlyLogFile {
  AppendOnlyLogFile({
    required String fileName,
    int maxBytes = 1024 * 1024,
  })  : _fileName = fileName,
        _prevFileName = fileName.replaceFirst('.txt', '.prev.txt'),
        _maxBytes = maxBytes;

  final String _fileName;
  final String _prevFileName;
  final int _maxBytes;

  File? _cachedFile;
  final _writeLock = _Mutex();

  Future<File> _getFile() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    _cachedFile = File('${dir.path}/$_fileName');
    return _cachedFile!;
  }

  /// Append a record. Safe to call from any zone — errors are caught and
  /// printed via debugPrint so logging never crashes the app.
  Future<void> append(String message) async {
    try {
      await _writeLock.synchronized(() async {
        final file = await _getFile();
        if (await file.exists() && await file.length() > _maxBytes) {
          await _rotate(file);
        }
        await file.writeAsString(
          message,
          mode: FileMode.append,
          // flush=true: hit disk immediately so a native kill can't eat
          // the last few events.
          flush: true,
        );
      });
    } catch (e) {
      debugPrint('[$_fileName] write failed: $e');
    }
  }

  Future<void> _rotate(File current) async {
    final prev = File('${current.parent.path}/$_prevFileName');
    if (await prev.exists()) {
      await prev.delete();
    }
    await current.rename(prev.path);
    _cachedFile = null; // force re-resolve on next append
  }

  /// The current and previous log files, if they exist. Used to attach
  /// both generations to a share sheet.
  Future<List<File>> existingFiles() async {
    final file = await _getFile();
    final prev = File('${file.parent.path}/$_prevFileName');
    return [
      if (await file.exists()) file,
      if (await prev.exists()) prev,
    ];
  }

  Future<String> currentPath() async {
    final file = await _getFile();
    return file.path;
  }

  Future<void> clear() async {
    try {
      await _writeLock.synchronized(() async {
        final file = await _getFile();
        final prev = File('${file.parent.path}/$_prevFileName');
        if (await file.exists()) await file.delete();
        if (await prev.exists()) await prev.delete();
        _cachedFile = null;
      });
    } catch (e) {
      debugPrint('[$_fileName] clear failed: $e');
    }
  }
}

/// Tiny async mutex so concurrent appends don't interleave.
class _Mutex {
  Future<void> _last = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _last;
    _last = completer.future;
    previous.whenComplete(() async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}
