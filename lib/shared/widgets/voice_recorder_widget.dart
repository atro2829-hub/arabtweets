import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/colors.dart';

/// Voice recorder widget placeholder - uses system audio recording
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, int durationSeconds)? onRecorded;
  final double buttonSize;
  final Color? accentColor;

  const VoiceRecorderWidget({
    super.key,
    this.onRecorded,
    this.buttonSize = 40,
    this.accentColor,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  String? _recordedPath;

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _seconds = 0;
      _recordedPath = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordedPath = '/tmp/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    });
    if (widget.onRecorded != null && _recordedPath != null) {
      widget.onRecorded!(_recordedPath!, _seconds);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_recordedPath != null && !_isRecording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle, color: accent, size: 20),
                const SizedBox(width: 8),
                Text('${_seconds}ث', style: TextStyle(color: accent, fontSize: 13)),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
        if (_isRecording)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_seconds}ث',
                  style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              ...List.generate(5, (i) {
                final h = (_seconds % 2 == 0) ? 8.0 : 16.0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                    begin: 0.5,
                    end: 1.0,
                    duration: 300.ms,
                );
              }),
            ],
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _toggleRecording,
          child: Container(
            width: widget.buttonSize,
            height: widget.buttonSize,
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.error : accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: widget.buttonSize * 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
