import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/models.dart';

/// Displays a YouTube video either from a [LearningResource] (URL) or a direct [videoId].
class YoutubePlayerScreen extends StatefulWidget {
  final LearningResource? resource;
  final String? videoId;
  final String? title;

  /// Open from a LearningResource (URL will be converted to videoId).
  const YoutubePlayerScreen({
    Key? key,
    required LearningResource this.resource,
  })  : videoId = null,
        title = null,
        super(key: key);

  /// Open directly with a videoId and title string.
  const YoutubePlayerScreen.fromId({
    Key? key,
    required String this.videoId,
    required String this.title,
  })  : resource = null,
        super(key: key);

  @override
  _YoutubePlayerScreenState createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;

  String get _effectiveVideoId {
    if (widget.videoId != null && widget.videoId!.isNotEmpty) {
      return widget.videoId!;
    }
    if (widget.resource != null) {
      return YoutubePlayerController.convertUrlToId(widget.resource!.url) ?? '';
    }
    return '';
  }

  String get _effectiveTitle {
    return widget.title ?? widget.resource?.title ?? '';
  }

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _effectiveVideoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        showVideoAnnotations: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _effectiveTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}
