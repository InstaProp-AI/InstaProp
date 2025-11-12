import 'package:flutter/material.dart';
import '../models/faq.dart';
import '../services/api_client.dart';
import '../services/help_service.dart';
import '../theme/app_colors.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  bool _loading = true;
  List<Faq> _faqs = [];
  final Set<int> _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() => _loading = true);
    try {
      final helpService = HelpService(ApiClient.baseUrl);
      final faqs = await helpService.getAllFaq();
      if (!mounted) return;
      setState(() {
        _faqs = faqs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load FAQs: $e')),
      );
    }
  }

  void _toggle(int id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All FAQs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFaqs,
              child: _faqs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No FAQs available yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _faqs.length,
                      itemBuilder: (context, index) {
                        final faq = _faqs[index];
                        final isExpanded = _expanded.contains(faq.faqId);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _toggle(faq.faqId),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          faq.question,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: AppColors.secondary,
                                      ),
                                    ],
                                  ),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        faq.answer,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration:
                                        const Duration(milliseconds: 200),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
