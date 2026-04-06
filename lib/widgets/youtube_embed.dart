import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Extracts a YouTube video ID from various URL formats.
///
/// Supports:
/// - https://www.youtube.com/watch?v=VIDEO_ID
/// - https://youtu.be/VIDEO_ID
/// - https://www.youtube.com/embed/VIDEO_ID
/// - https://youtube.com/shorts/VIDEO_ID
///
/// Returns null if the URL is not a recognised YouTube format.
String? extractYoutubeVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }

  if (uri.host.contains('youtube.com')) {
    if (uri.pathSegments.contains('watch')) {
      return uri.queryParameters['v'];
    }
    if (uri.pathSegments.contains('embed') ||
        uri.pathSegments.contains('shorts')) {
      return uri.pathSegments.last;
    }
  }

  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }

  return null;
}

/// Displays an embedded YouTube player for the given URL.
///
/// Shows a thumbnail with a play button initially. The iframe is only loaded
/// when the user taps play, avoiding scroll-capture issues caused by iframes.
class YoutubeEmbed extends StatefulWidget {
  const YoutubeEmbed({
    required this.url,
    super.key,
  });

  final String url;

  @override
  State<YoutubeEmbed> createState() => _YoutubeEmbedState();
}

class _YoutubeEmbedState extends State<YoutubeEmbed> {
  bool _activated = false;

  @override
  Widget build(BuildContext context) {
    final videoId = extractYoutubeVideoId(widget.url);
    if (videoId == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _activated
            ? _YoutubeIframe(videoId: videoId)
            : _YoutubeThumbnail(
                videoId: videoId,
                onPlay: () => setState(() => _activated = true),
              ),
      ),
    );
  }
}

class _YoutubeThumbnail extends StatelessWidget {
  const _YoutubeThumbnail({
    required this.videoId,
    required this.onPlay,
  });

  final String videoId;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.play_circle_outline, color: Colors.white),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPlay,
            child: const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _YoutubeIframe extends StatelessWidget {
  const _YoutubeIframe({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    final viewType = 'youtube-player-$videoId';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = 'https://www.youtube.com/embed/$videoId?autoplay=1';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow =
            'accelerometer; autoplay; clipboard-write; '
            'encrypted-media; gyroscope; picture-in-picture';
        iframe.allowFullscreen = true;
        // Allow loading under cross-origin isolation (WASM builds).
        iframe.setAttribute('credentialless', '');
        return iframe;
      },
    );

    return HtmlElementView(viewType: viewType);
  }
}
