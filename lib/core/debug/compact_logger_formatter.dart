import 'package:talker_flutter/talker_flutter.dart';

/// Line-based coloured formatter without the trailing `─────` separator.
///
/// Talker's stock [ColoredLoggerFormatter] appends an underline after every
/// message — that breaks copy/paste because each log block is wrapped in
/// divider lines that have to be manually trimmed out of the selection.
/// This formatter emits one continuous coloured block per message so the
/// terminal output can be selected and pasted as-is.
class CompactLoggerFormatter implements LoggerFormatter {
  const CompactLoggerFormatter();

  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    final msg = details.message?.toString() ?? '';
    if (!settings.enableColors) return msg;
    return msg.split('\n').map(details.pen.write).join('\n');
  }
}
