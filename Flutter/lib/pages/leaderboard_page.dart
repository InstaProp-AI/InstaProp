import 'package:app1/models/leaderboard_models.dart';
import 'package:app1/services/leaderboard_service.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _periods = const [
    LeaderboardPeriod.thisWeek,
    LeaderboardPeriod.lastWeek,
    LeaderboardPeriod.allTime,
  ];

  final Map<LeaderboardPeriod, LeaderboardResponse?> _responses = {};
  final Map<LeaderboardPeriod, bool> _loading = {};
  final Map<LeaderboardPeriod, String?> _errors = {};

  LeaderboardHighlightsResponse? _highlights;
  bool _highlightsLoading = true;
  String? _highlightsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadPeriod(_periods[_tabController.index]);
      }
    });

    for (final period in _periods) {
      _loading[period] = false;
      _errors[period] = null;
    }

    _loadHighlights();
    _loadPeriod(_periods.first);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    setState(() {
      _highlightsLoading = true;
      _highlightsError = null;
    });

    try {
      final data = await LeaderboardService.fetchHighlights();
      setState(() {
        _highlights = data;
        _highlightsLoading = false;
      });
    } catch (e) {
      setState(() {
        _highlightsLoading = false;
        _highlightsError = e.toString();
      });
    }
  }

  Future<void> _loadPeriod(
    LeaderboardPeriod period, {
    bool forceRefresh = false,
  }) async {
    if (_loading[period] == true) return;
    if (!forceRefresh && _responses[period] != null) return;

    setState(() {
      _loading[period] = true;
      _errors[period] = null;
    });

    try {
      final response = await LeaderboardService.fetchLeaderboard(period);
      setState(() {
        _responses[period] = response;
        _loading[period] = false;
      });
    } catch (e) {
      setState(() {
        _errors[period] = e.toString();
        _loading[period] = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final period = _periods[_tabController.index];
    await _loadPeriod(period, forceRefresh: true);
    if (period == LeaderboardPeriod.thisWeek) {
      await _loadHighlights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'This Week'),
            Tab(text: 'Last Week'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _periods.map(_buildTabContent).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleRefresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Standings'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTabContent(LeaderboardPeriod period) {
    final isLoading = _loading[period] ?? false;
    final error = _errors[period];
    final response = _responses[period];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && response == null) {
      return _buildErrorState(period, error);
    }

    if (response == null || response.entries.isEmpty) {
      return _buildEmptyState(period);
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (period == LeaderboardPeriod.thisWeek)
            _buildHighlightsHero(),
          if (period == LeaderboardPeriod.thisWeek)
            const SizedBox(height: 16),
          _buildHeadlineCard(response),
          const SizedBox(height: 16),
          _buildPodium(response.entries),
          if (response.personalEntry != null) ...[
            const SizedBox(height: 16),
            _buildPersonalCard(response.personalEntry!, period),
          ],
          if (response.momentumTips.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTipsCard(response.momentumTips),
          ],
          const SizedBox(height: 16),
          _buildEntriesList(response.entries),
        ],
      ),
    );
  }

  Widget _buildHighlightsHero() {
    if (_highlightsLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _heroDecoration(),
        child: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Collecting weekly champions...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_highlightsError != null || _highlights == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _heroDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 32, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _highlightsError ??
                    'Top champions will appear here once the week closes.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final highlight = _highlights!.lastWeek;
    final prompts = _highlights!.actionPrompts;
    final personal = _highlights!.personalThisWeek;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _heroDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highlight?.headline ?? 'Weekly cashbacks ready',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      highlight?.summary ??
                          'Stay active — the next champion could be you.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (personal != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are currently #${personal.rank} with ${personal.points} pts this week. ${personal.pointsToNextRank != null ? 'Only ${personal.pointsToNextRank} pts to climb higher!' : 'Keep pushing for the podium.'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (prompts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prompts
                  .take(3)
                  .map(
                    (prompt) => Chip(
                      label: Text(
                        prompt,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.16),
                    ),
                  )
                  .toList(),
            )
          ],
        ],
      ),
    );
  }

  BoxDecoration _heroDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withOpacity(0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildHeadlineCard(LeaderboardResponse response) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response.headline,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response.subheading,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(response.rangeStart)} → ${_formatDate(response.rangeEnd)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final topThree = entries.take(3).toList();
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Podium',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: topThree
                .asMap()
                .entries
                .map(
                  (entry) => _buildPodiumTile(entry.value, entry.key),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumTile(LeaderboardEntry entry, int index) {
    final colors = [
      Colors.amber[400],
      Colors.blueGrey[200],
      Colors.deepOrange[200],
    ];

    final heights = [160.0, 120.0, 100.0];

    final label = index == 0
        ? 'Champion'
        : index == 1
            ? 'Runner-up'
            : 'Top 3';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colors[index]!.withOpacity(0.2),
          child: Text(
            entry.avatarInitials ?? entry.displayName.substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 90,
          height: heights[index],
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${entry.rank}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${entry.points} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              if (entry.cashbackAwarded > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${entry.cashbackAwarded.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 100,
          child: Text(
            entry.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalCard(
      LeaderboardEntry entry, LeaderboardPeriod period) {
    return Container(
      decoration: _cardDecoration(accent: true),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              entry.avatarInitials ?? entry.displayName.substring(0, 1),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Momentum',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Currently ranked #${entry.rank} with ${entry.points} pts',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                if (entry.pointsToNextRank != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Only ${entry.pointsToNextRank} pts to move up!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (entry.potentialCashback > 0 &&
                    period == LeaderboardPeriod.thisWeek) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Break into the top 3 to unlock ${entry.potentialCashback.toStringAsFixed(0)} EGP cashback.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List<String> tips) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Momentum Tips',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<LeaderboardEntry> entries) {
    final topPoints = entries.first.points.toDouble();
    return Column(
      children: entries
          .map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(
                                  entry.isRequester ? 0.2 : 0.1,
                                ),
                        child: Text(
                          entry.avatarInitials ??
                              entry.displayName.substring(0, 1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            Text(
                              '#${entry.rank} · ${entry.points} pts',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (entry.cashbackAwarded > 0)
                        Chip(
                          backgroundColor: Colors.green.withOpacity(0.12),
                          label: Text(
                            '+${entry.cashbackAwarded.toStringAsFixed(0)} EGP',
                            style: const TextStyle(
                                color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                          avatar: const Icon(Icons.payments_outlined,
                              color: Colors.green, size: 18),
                        )
                      else if (entry.potentialCashback > 0)
                        Chip(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          label: Text(
                            '${entry.potentialCashback.toStringAsFixed(0)} EGP on standby',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          avatar: Icon(
                            Icons.flag,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: topPoints == 0 ? 0 : entry.points / topPoints,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      entry.isRequester
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...entry.activity.take(3).map(
                        (slice) => Chip(
                          label: Text(
                            '${slice.category}: ${slice.points} pts',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                      if (entry.streakWeeks > 0)
                        Chip(
                          label: Text('${entry.streakWeeks} week streak'),
                          avatar: const Icon(Icons.local_fire_department,
                              color: Colors.orange, size: 18),
                          backgroundColor: Colors.orange.withOpacity(0.12),
                        ),
                    ],
                  ),
                  if (entry.rewardSummary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.rewardSummary!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState(LeaderboardPeriod period) {
    final messages = {
      LeaderboardPeriod.thisWeek:
          'This week\'s leaderboard is wide open. Start bidding and referring to claim the top spot.',
      LeaderboardPeriod.lastWeek:
          'No data for last week yet. Engage with the app to appear here next Monday.',
      LeaderboardPeriod.allTime:
          'Earn rewards to establish your legacy on the all-time leaderboard.',
    };

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No entries yet',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  messages[period] ?? '',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Kickstart the leaderboard'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LeaderboardPeriod period, String error) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to load ${period.apiValue} standings',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadPeriod(period, forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({bool accent = false}) {
    return BoxDecoration(
      color: accent ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}


