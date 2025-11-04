import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldMicButton extends StatefulWidget {
  const HoldMicButton({
    super.key,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.isActive,
    this.color,
    this.canvasSize = 300,
    this.ringBaseSize = 120,
    this.pulseDuration = const Duration(milliseconds: 1800),
    this.scaleOnPress = 1.06,
  });

  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final bool isActive;
  final Color? color;
  final double canvasSize;
  final double ringBaseSize;
  final Duration pulseDuration;
  final double scaleOnPress;

  @override
  State<HoldMicButton> createState() => _HoldMicButtonState();
}

class _HoldMicButtonState extends State<HoldMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );
  }

  @override
  void didUpdateWidget(covariant HoldMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseDuration != widget.pulseDuration) {
      _pulseCtrl.duration = widget.pulseDuration;
      if (_isPressing && !_pulseCtrl.isAnimating) _pulseCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onDown() {
    if (_isPressing) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressing = true);
    if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat();
    widget.onHoldStart();
  }

  void _onUpOrCancel() {
    if (!_isPressing) return;
    widget.onHoldEnd();
    HapticFeedback.selectionClick();
    setState(() => _isPressing = false);
    _pulseCtrl.stop();
    _pulseCtrl.reset();
  }

  Widget _buildRing(Color color, double t, double phaseShift) {
    final phase = ((t + phaseShift) % 1.0);
    final scale = 0.70 + (phase * 1.50);
    final opacity = (1.0 - phase).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.ringBaseSize,
        height: widget.ringBaseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity * 0.15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.10),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Listener(
      onPointerDown: (_) => _onDown(),
      onPointerUp: (_) => _onUpOrCancel(),
      onPointerCancel: (_) => _onUpOrCancel(),
      child: SizedBox(
        width: widget.canvasSize,
        height: widget.canvasSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isPressing)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  final t = _pulseCtrl.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRing(color, t, 0.00),
                      _buildRing(color, t, 0.45),
                    ],
                  );
                },
              ),
            AnimatedScale(
              scale: _isPressing ? widget.scaleOnPress : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: AbsorbPointer(
                absorbing: true,
                child: FloatingActionButton.large(
                  heroTag: null,
                  onPressed: null,
                  backgroundColor: color,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Icon(widget.isActive ? Icons.mic : Icons.mic_none),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
