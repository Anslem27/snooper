import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'wave_bars.dart';

class MusicActivityCard extends StatelessWidget {
  final String platform;
  final String title;
  final String artist;
  final String username;
  final String? imageUrl;

  const MusicActivityCard({
    super.key,
    required this.platform,
    required this.title,
    required this.artist,
    required this.username,
    this.imageUrl,
  });

  Color _getPlatformColor() {
    switch (platform) {
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'apple':
        return const Color(0xFFFA243C);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPlatformColor();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Album art or fallback
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: WaveBars(color: color),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: WaveBars(color: color),
                        ),
                      ),
                    )
                  : Center(
                      child: WaveBars(color: color),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        platform == 'spotify'
                            ? Icons.music_note
                            : platform == 'apple'
                                ? Icons.apple
                                : Icons.play_circle_fill,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
