import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  return YoutubePlayer.convertUrlToId(url);
}

/// Displays an embedded YouTube player for the given URL.
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
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(YoutubeEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _initController();
    }
  }

  void _initController() {
    final videoId = extractYoutubeVideoId(widget.url);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
      );
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
      ),
    );
  }
}
