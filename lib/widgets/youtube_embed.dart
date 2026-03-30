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
class YoutubeEmbed extends StatelessWidget {
  const YoutubeEmbed({
    required this.url,
    super.key,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    final videoId = extractYoutubeVideoId(url);
    if (videoId == null) {
      return const SizedBox.shrink();
    }

    final viewType = 'youtube-player-$videoId';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = 'https://www.youtube.com/embed/$videoId';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow =
            'accelerometer; autoplay; clipboard-write; '
            'encrypted-media; gyroscope; picture-in-picture';
        iframe.allowFullscreen = true;
        return iframe;
      },
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}
