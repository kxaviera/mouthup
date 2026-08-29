import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../utils/youtube.dart';

/// Inline network video for feed and post detail.
class PostVideoPlayer extends StatefulWidget {
  const PostVideoPlayer({super.key, required this.url, this.height = 220});

  final String url;
  final double height;

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final ytId = youtubeVideoId(widget.url);
    if (ytId != null) {
      _failed = false;
      _ready = true;
      return;
    }
    _initDirect();
  }

  Future<void> _initDirect() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openYoutube(String videoId) async {
    final uri = Uri.parse(youtubeWatchUrl(videoId));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_ready) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ytId = youtubeVideoId(widget.url);
    if (ytId != null) {
      return _shell(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              youtubeThumbnail(ytId),
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => const ColoredBox(
                color: AppColors.bgElevated,
                child: Icon(Icons.videocam_outlined, color: AppColors.textDim, size: 40),
              ),
            ),
            Container(color: Colors.black38),
            Center(
              child: Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: IconButton(
                  iconSize: 52,
                  color: Colors.white,
                  onPressed: () => _openYoutube(ytId),
                  icon: const Icon(Icons.play_arrow),
                ),
              ),
            ),
            const Positioned(
              left: 10,
              bottom: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('YouTube', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_failed) {
      return _shell(
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, color: AppColors.textDim),
            SizedBox(height: 4),
            Text('Video unavailable', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    if (!_ready || _controller == null) {
      return _shell(
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    final c = _controller!;
    return _shell(
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
          if (!c.value.isPlaying)
            Material(
              color: Colors.black38,
              shape: const CircleBorder(),
              child: IconButton(
                iconSize: 44,
                color: Colors.white,
                onPressed: _togglePlay,
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          if (c.value.isPlaying)
            Positioned.fill(
              child: GestureDetector(onTap: _togglePlay, behavior: HitTestBehavior.translucent),
            ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
