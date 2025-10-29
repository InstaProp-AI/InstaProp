import 'package:flutter/material.dart';
import '../models/live_stream.dart';
import '../services/live_stream_service.dart';

class LiveStreamPlayerPage extends StatefulWidget {
  final LiveStream stream;

  const LiveStreamPlayerPage({
    super.key,
    required this.stream,
  });

  @override
  State<LiveStreamPlayerPage> createState() => _LiveStreamPlayerPageState();
}

class _LiveStreamPlayerPageState extends State<LiveStreamPlayerPage> {
  bool _isLoading = true;
  bool _isJoined = false;
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _viewerCount = widget.stream.viewerCount;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
    _joinStream();
  }

  @override
  void dispose() {
    if (_isJoined) {
      LiveStreamService.leaveStream(widget.stream.streamId);
    }
    super.dispose();
  }

  Future<void> _joinStream() async {
    final response = await LiveStreamService.joinStream(widget.stream.streamId);
    if (response.success && mounted) {
      setState(() {
        _isJoined = true;
        _viewerCount++;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_viewerCount watching',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Video placeholder/thumbnail
                if (widget.stream.thumbnailUrl != null)
                  Image.network(
                    widget.stream.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.videocam_off,
                            size: 64, color: Colors.white54),
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.videocam,
                          size: 64, color: Colors.white54),
                    ),
                  ),
                // Controls overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stream.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.stream.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.stream.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  widget.stream.developerProfileImageUrl != null
                                      ? NetworkImage(
                                          widget.stream.developerProfileImageUrl!,
                                        )
                                      : null,
                              child: widget.stream.developerProfileImageUrl == null
                                  ? Text(
                                      widget.stream.developerName.isNotEmpty
                                          ? widget.stream.developerName[0]
                                              .toUpperCase()
                                          : 'D',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.stream.developerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

