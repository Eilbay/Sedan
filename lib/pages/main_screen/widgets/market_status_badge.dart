import 'package:optombai/core/import_links.dart';

class MarketStatusWrap extends StatelessWidget {
  final User user;

  const MarketStatusWrap({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.userType != '4') return const SizedBox.shrink();
    if (user.supplierMarkets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: user.supplierMarkets.map((m) {
          final bool active = m.isActive;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? Colors.green : Colors.grey.shade400,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.pause_circle_filled,
                  size: 12,
                  color: active ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  m.marketName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color:
                        active ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MarketStatusOneLine extends StatelessWidget {
  final User user;

  const MarketStatusOneLine({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.userType != '4') return const SizedBox.shrink();
    if (user.supplierMarkets.isEmpty) return const SizedBox.shrink();

    final m = user.supplierMarkets.first;
    final active = m.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? Colors.green : Colors.grey.shade400,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.pause_circle_filled,
            size: 12,
            color: active ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              m.marketName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? Colors.green.shade800 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildMarketStatus(User user) {
  return MarketStatusWrap(user: user);
}

Widget buildMarketStatusOneLine(User user) {
  return MarketStatusOneLine(user: user);
}
