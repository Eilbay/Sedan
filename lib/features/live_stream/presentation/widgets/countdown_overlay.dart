import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onCountdownFinished;

  const CountdownOverlay({super.key, required this.onCountdownFinished});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _countdown = 3;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else if (_countdown == 1) {
        setState(() {
          _countdown = 0;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _finished = true;
        });
        widget.onCountdownFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, opacity, child) {
          if (opacity < 0.05) return const SizedBox.shrink();

          return Opacity(
            opacity: opacity,
            child: Center(
              child: Text(
                'ВЫ В ЭФИРЕ!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  shadows: [
                    Shadow(blurRadius: 10.0, color: Colors.black.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (_countdown == 0) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_finished) {
          setState(() => _finished = true);
        }
      });
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Text(
          '$_countdown',
          key: ValueKey<int>(_countdown),
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 10.0, color: Colors.black.withValues(alpha: 0.8), offset: const Offset(0, 0)),
            ],
          ),
        ),
      ),
    );
  }
}
