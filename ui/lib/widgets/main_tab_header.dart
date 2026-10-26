import 'package:flutter/material.dart';

import 'responsive_page.dart';

class MainTabHeader extends StatelessWidget {
  const MainTabHeader({
    required this.section,
    required this.onNotifications,
    required this.onSettings,
    super.key,
  });

  static const double height = 56;
  final String section;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final primary = dark ? scheme.primary : const Color(0xFF0057BD);
    final secondary = dark ? scheme.secondary : const Color(0xFF3A53B7);
    final foreground = dark ? scheme.onSurfaceVariant : const Color(0xFF595C5E);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: dark ? scheme.surface : const Color(0xFFF5F7F9),
        border: Border(
          bottom: BorderSide(
            color: dark ? scheme.outlineVariant : const Color(0x99E5E9EB),
          ),
        ),
      ),
      child: ResponsivePage(
        child: LayoutBuilder(builder: (context, constraints) {
          final showSection = constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(11) <= 15;
          return SizedBox(
            height: height,
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: '스펙모아'),
                          TextSpan(
                            text: '.zip',
                            style: TextStyle(
                              fontFamily: 'SpecInter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondary,
                            ),
                          ),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SpecJakarta',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: 0,
                          color: primary,
                        ),
                      ),
                    ),
                    if (showSection) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: primary.withValues(alpha: .2)),
                        ),
                        child: Text(section,
                            style: TextStyle(
                              fontFamily: 'SpecInter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: 0,
                              color: primary,
                            )),
                      ),
                    ],
                  ]),
                ),
                _HeaderButton(
                  tooltip: '알림',
                  icon: Icons.notifications_outlined,
                  color: foreground,
                  onPressed: onNotifications,
                ),
                const SizedBox(width: 2),
                _HeaderButton(
                  tooltip: '설정',
                  icon: Icons.settings_outlined,
                  color: foreground,
                  onPressed: onSettings,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(36, 36),
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 20, color: color),
      );
}
