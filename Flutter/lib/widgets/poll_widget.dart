import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../services/community_post_service.dart';

class PollWidget extends StatefulWidget {
  final int postId;
  const PollWidget({super.key, required this.postId});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  Poll? _poll;
  bool _loading = true;
  bool _submitting = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await CommunityPostService.getPollByPost(widget.postId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) _poll = res.data;
    });
  }

  Future<void> _vote(int optionIndex) async {
    if (_poll == null || _poll!.isExpired || _submitting) return;
    setState(() => _submitting = true);
    final payload = _poll!.isMultipleChoice ? _selected.toList() : optionIndex;
    final res = await CommunityPostService.voteOnPoll(_poll!.pollId, payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to vote')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(),
      );
    }
    if (_poll == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _poll!.question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if (_poll!.imageUrl != null && _poll!.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _poll!.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...List.generate(_poll!.options.length, (i) {
            final opt = _poll!.options[i];
            final userSelections = _poll!.userVoteOptionIndexes ?? [];
            final isSelected = _poll!.isMultipleChoice
                ? _selected.contains(i)
                : (userSelections.contains(i));
            return InkWell(
              onTap: _submitting
                  ? null
                  : () {
                      if (_poll!.isMultipleChoice) {
                        setState(() {
                          if (_selected.contains(i)) {
                            _selected.remove(i);
                          } else {
                            _selected.add(i);
                          }
                        });
                      } else {
                        _vote(i);
                      }
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    if (_poll!.isMultipleChoice) ...[
                      Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: Text(opt.text)),
                    if ((_poll!.showResultsBeforeVote) || _poll!.hasVoted) ...[
                      Text('${opt.percentage.toStringAsFixed(0)}%'),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '${_poll!.totalVotes} votes',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (_poll!.isMultipleChoice)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitting || _selected.isEmpty ? null : () => _vote(-1),
                child: const Text('Submit'),
              ),
            ),
        ],
      ),
    );
  }
}

