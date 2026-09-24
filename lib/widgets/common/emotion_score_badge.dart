import 'package:flutter/material.dart';

import '../../core/utils/constants.dart';

class EmotionScoreBadge extends StatelessWidget {
  final String emotionTag;
  final int emotionScore;

  const EmotionScoreBadge({
    super.key,
    required this.emotionTag,
    required this.emotionScore,
  });

  Color get _color {
    if (emotionScore > 1) return Colors.orange;
    if (emotionScore < -1) return Colors.blueGrey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color),
      ),
      child: Text(
        '${EmotionTag.emojiFor(emotionTag)} $emotionTag',
        style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
