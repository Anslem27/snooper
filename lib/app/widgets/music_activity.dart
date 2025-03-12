import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'wave_bars.dart';

class MusicActivityCard extends StatelessWidget {
  final String platform;
  final String title;
  final String artist;
  final String username;
  final String? imageUrl;
  final String? album;
  final String? duration;

  const MusicActivityCard({
    super.key,
    required this.platform,
    required this.title,
    required this.artist,
    required this.username,
    this.imageUrl,
    this.album,
    this.duration,
  });

  Color _getPlatformColor() {
    switch (platform.toLowerCase()) {
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

  IconData _getPlatformIcon() {
    switch (platform.toLowerCase()) {
      case 'spotify':
        return Icons.music_note;
      case 'apple':
        return Icons.apple;
      case 'youtube':
        return Icons.play_circle_fill;
      default:
        return Icons.headphones;
    }
  }

  String _getPlatformName() {
    switch (platform.toLowerCase()) {
      case 'spotify':
        return 'Spotify';
      case 'apple':
        return 'Apple Music';
      case 'youtube':
        return 'YouTube Music';
      default:
        return platform;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPlatformColor();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card.outlined(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Album art with platform indicator
              Stack(
                children: [
                  // Album image
                  Hero(
                    tag: 'music-image-$title-$artist',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(5),
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
                  ),

                  // Platform indicator badge
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getPlatformIcon(),
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username with playing indicator
                    Row(
                      children: [
                        Text(
                          '@$username',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPlatformIcon(),
                                size: 10,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getPlatformName()
                                        .toLowerCase()
                                        .contains("youtube")
                                    ? _getPlatformName()
                                    : 'Playing on ${_getPlatformName()}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Hero(
                      tag: 'music-title-$title',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Artist
                    Hero(
                      tag: 'music-artist-$artist',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          artist,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Playback control
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    final color = _getPlatformColor();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showGeneralDialog(
      context: context,
      barrierLabel: "Music Details",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header image section
                    Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        // Album cover or placeholder
                        Hero(
                          tag: 'music-image-$title-$artist',
                          child: SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: WaveBars(
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: WaveBars(
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: WaveBars(
                                        color: color,
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        // Gradient overlay
                        Container(
                          height: 100,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),

                        // Back button
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black26,
                            ),
                          ),
                        ),

                        // Platform badge
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPlatformIcon(),
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getPlatformName(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Title info positioned at bottom
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User info
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '@$username is listening to',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Song title
                              Hero(
                                tag: 'music-title-$title',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              // Artist name
                              Hero(
                                tag: 'music-artist-$artist',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    artist,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Details section
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Track Details',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Details grid

                          _buildDetailRow(context, 'Platform',
                              _getPlatformName(), _getPlatformIcon()),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
