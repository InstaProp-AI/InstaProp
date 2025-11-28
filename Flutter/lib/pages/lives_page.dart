import 'package:flutter/material.dart';
import '../models/live_stream.dart';
import '../services/live_stream_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/feed_live_stream_card.dart';
import 'live_stream_player_page.dart';

/// Page displaying all live streams
class LivesPage extends StatefulWidget {
  const LivesPage({super.key});

  @override
  State<LivesPage> createState() => _LivesPageState();
}

class _LivesPageState extends State<LivesPage> {
  List<LiveStream> _streams = [];
  bool _isLoading = true;
  String? _error;
  int _liveCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load count and all streams in parallel
      final results = await Future.wait([
        LiveStreamService.getLiveStreamCount(),
        LiveStreamService.getAllStreams(),
      ]);

      final countResponse = results[0] as ApiResponse<int>;
      final streamsResponse = results[1] as ApiResponse<List<LiveStream>>;

      if (mounted) {
        setState(() {
          if (countResponse.success) {
            _liveCount = countResponse.data ?? 0;
          }
          if (streamsResponse.success && streamsResponse.data != null) {
            _streams = streamsResponse.data!;
          } else {
            _error = streamsResponse.error ?? 'Failed to load live streams';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading live streams: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videocam,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Live Streams',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadStreams,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _streams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No live streams available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check back later for live property tours and Q&A sessions',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStreams,
                      child: CustomScrollView(
                        slivers: [
                          // Header with live count
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade600,
                                    Colors.red.shade400,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '🔴 LIVE NOW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$_liveCount ${_liveCount == 1 ? 'stream' : 'streams'} currently live',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Streams list
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final stream = _streams[index];
                                return FeedLiveStreamCard(
                                  stream: stream,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LiveStreamPlayerPage(stream: stream),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: _streams.length,
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 20),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

