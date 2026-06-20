import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/life_event.dart';
import '../../../widgets/common/emotion_score_badge.dart';

class LifeEventCard extends StatelessWidget {
  final LifeEvent event;
  final VoidCallback? onTap;

  const LifeEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (event.isTurningPoint)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.bolt, color: Colors.amber, size: 18),
                    ),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    event.occurredYearMonth,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(event.category, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  EmotionScoreBadge(
                    emotionTag: event.emotionTag,
                    emotionScore: event.emotionScore,
                  ),
                  const Spacer(),
                  const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 2),
                  Text('${event.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 10),
                  const Icon(Icons.mode_comment_outlined, size: 14),
                  const SizedBox(width: 2),
                  Text('${event.commentCount}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatDateTime(DateTime dt) => DateFormat('yyyy/MM/dd HH:mm').format(dt);
