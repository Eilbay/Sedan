import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:optombai/l10n/tr.dart';

class MultiTourOverlay {
  MultiTourOverlay._();

  static OverlayEntry? _entry;
  static final ValueNotifier<List<RRect>> _holes =
      ValueNotifier<List<RRect>>(<RRect>[]);

  static Timer? _recalcDebounce;
  static bool _firstPaintScheduled = false;

  static void show({
    required BuildContext context,
    required List<GlobalKey> targetKeys,
    required String text,
    required VoidCallback onNext,
    double holePadding = 8,
    double holeRadius = 16,
    Color dimColor = const Color(0xB3000000),
    Duration waitKeysTimeout = const Duration(seconds: 2),
  }) {
    hide();

    final overlayState = Overlay.of(context, rootOverlay: true);
    // ignore: unnecessary_null_comparison
    if (overlayState == null) return;

    bool removed = false;

    void safeHide() {
      if (removed) return;
      removed = true;
      hide();
    }

    List<RRect> calcHoles() {
      final holes = <RRect>[];

      for (final key in targetKeys) {
        final ctx = key.currentContext;
        if (ctx == null) continue;

        final ro = ctx.findRenderObject();
        if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;

        final topLeft = ro.localToGlobal(Offset.zero);
        final rect = Rect.fromLTWH(
          topLeft.dx - holePadding,
          topLeft.dy - holePadding,
          ro.size.width + holePadding * 2,
          ro.size.height + holePadding * 2,
        );

        holes.add(RRect.fromRectAndRadius(rect, Radius.circular(holeRadius)));
      }

      return holes;
    }

    void scheduleRecalc() {
      _recalcDebounce?.cancel();
      _recalcDebounce = Timer(const Duration(milliseconds: 16), () {
        if (removed) return;
        _holes.value = calcHoles();
      });
    }

    Future<void> waitKeysReady() async {
      final deadline = DateTime.now().add(waitKeysTimeout);
      while (DateTime.now().isBefore(deadline)) {
        if (removed) return;

        final ready = targetKeys.every((k) {
          final ctx = k.currentContext;
          if (ctx == null) return false;
          final ro = ctx.findRenderObject();
          return ro is RenderBox && ro.hasSize && ro.attached;
        });

        if (ready) return;
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }

    _firstPaintScheduled = false;

    _entry = OverlayEntry(
      builder: (ctx) {
        if (!_firstPaintScheduled) {
          _firstPaintScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (removed) return;
            scheduleRecalc();
          });
        }

        return _OverlayMetricsListener(
          onMetricsChanged: scheduleRecalc,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    onPanDown: (_) {},
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: ValueListenableBuilder<List<RRect>>(
                    valueListenable: _holes,
                    builder: (_, holes, __) {
                      return IgnorePointer(
                        ignoring: true,
                        child: CustomPaint(
                          painter: _MultiHolePainter(
                            holes: holes,
                            dimColor: dimColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    top: false,
                    child: _TourCard(
                      text: text,
                      nextText: tr(context, 'tour_next'),
                      onNext: () {
                        safeHide();
                        onNext();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlayState.insert(_entry!);

    unawaited(() async {
      await waitKeysReady();
      if (removed) return;
      scheduleRecalc();
    }());
  }

  static void hide() {
    _recalcDebounce?.cancel();
    _recalcDebounce = null;

    _entry?.remove();
    _entry = null;

    _holes.value = <RRect>[];
    _firstPaintScheduled = false;
  }
}

class _OverlayMetricsListener extends StatefulWidget {
  final Widget child;
  final VoidCallback onMetricsChanged;

  const _OverlayMetricsListener({
    required this.child,
    required this.onMetricsChanged,
  });

  @override
  State<_OverlayMetricsListener> createState() =>
      _OverlayMetricsListenerState();
}

class _OverlayMetricsListenerState extends State<_OverlayMetricsListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    widget.onMetricsChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MultiHolePainter extends CustomPainter {
  final List<RRect> holes;
  final Color dimColor;

  _MultiHolePainter({required this.holes, required this.dimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()..addRect(overlayRect);
    for (final hole in holes) {
      path.addRRect(hole);
    }
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = dimColor);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x66FFFFFF);

    for (final hole in holes) {
      canvas.drawRRect(hole, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiHolePainter oldDelegate) {
    return oldDelegate.holes != holes || oldDelegate.dimColor != dimColor;
  }
}

class _TourCard extends StatelessWidget {
  final String text;
  final String nextText;
  final VoidCallback onNext;

  const _TourCard({
    required this.text,
    required this.nextText,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 30,
            color: Color(0x33000000),
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AA0B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.white,
              ),
              child: Text(nextText),
            ),
          )
        ],
      ),
    );
  }
}
