import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:talker_flutter/talker_flutter.dart';

@RoutePage(name: 'TalkerLogRoute')
class TalkerLogScreen extends StatelessWidget {
  const TalkerLogScreen({super.key});

  static const _dioKeys = {
    TalkerKey.httpRequest,
    TalkerKey.httpResponse,
    TalkerKey.httpError,
  };

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(
      talker: talker,
      appBarTitle: 'API Logs',
      itemsBuilder: (cardContext, data) => TalkerDataCard(
        data: data,
        color: data.getFlutterColor(const TalkerScreenTheme()),
        expanded: false,
        onCopyTap: () => _copy(cardContext, data.generateTextMessage()),
        onTap: _dioKeys.contains(data.key)
            ? () => context.router.push(TalkerLogDetailRoute(data: data))
            : null,
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied')),
    );
  }
}
