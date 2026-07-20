import 'package:optombai/core/import_links.dart';

class PmtOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> icons;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leadingIcon;

  const PmtOptionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icons,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    final Color borderColor = selected ? primary : Colors.grey.shade300;
    final Color bgColor = selected ? primary.withValues(alpha: 0.06) : Colors.white;

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF201D2A),
    );

    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: const Color(0xFF77788A),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: subtitleStyle),
                  ],
                  if (icons.isNotEmpty || leadingIcon != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (leadingIcon != null) leadingIcon!,
                        ...icons.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              width: 44,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                p,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
