import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/moderation_service.dart';
import '../theme/app_theme.dart';

class ModerationPanelScreen extends StatefulWidget {
  const ModerationPanelScreen({super.key});

  @override
  State<ModerationPanelScreen> createState() => _ModerationPanelScreenState();
}

class _ModerationPanelScreenState extends State<ModerationPanelScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<ModerationItem> _all = [];
  bool _loading = true;
  String? _error;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ModerationService.getAll();
      if (mounted) setState(() { _all = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ModerationItem> _byStatus(String status) => _all.where((i) => i.status == status).toList();

  Future<void> _review(ModerationItem item, bool approve) async {
    if (_processingIds.contains(item.reelId)) return;
    setState(() => _processingIds.add(item.reelId));
    try {
      await ModerationService.review(item.reelId, approve: approve);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.reelId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber), child: const Text('Retry', style: TextStyle(color: Colors.white))),
          ]),
        ),
      );
    }

    final pending = _byStatus('pending');
    final approved = _byStatus('approved');
    final rejected = _byStatus('rejected');
    final flagged = _byStatus('flagged');
    final pendingAll = [...pending, ...flagged];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: AppColors.amber.withValues(alpha: 0.16), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: AppColors.amberSoft.withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Moderation Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Admin only', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      const Spacer(),
                      IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white70)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatCard(label: 'Pending', count: pendingAll.length, color: AppColors.amber),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Approved', count: approved.length, color: const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Rejected', count: rejected.length, color: AppColors.error),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.amber,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.text3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  dividerColor: Colors.white.withValues(alpha: 0.08),
                  tabs: [
                    Tab(text: 'Pending (${pendingAll.length})'),
                    Tab(text: 'Approved (${approved.length})'),
                    Tab(text: 'Rejected (${rejected.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ModerationList(items: pendingAll, processingIds: _processingIds, onApprove: (item) => _review(item, true), onReject: (item) => _review(item, false), showActions: true),
                      _ModerationList(items: approved, processingIds: _processingIds, onApprove: (item) => _review(item, true), onReject: (item) => _review(item, false)),
                      _ModerationList(items: rejected, processingIds: _processingIds, onApprove: (item) => _review(item, true), onReject: (item) => _review(item, false)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ModerationList extends StatelessWidget {
  const _ModerationList({required this.items, required this.processingIds, required this.onApprove, required this.onReject, this.showActions = false});

  final List<ModerationItem> items;
  final Set<int> processingIds;
  final ValueChanged<ModerationItem> onApprove;
  final ValueChanged<ModerationItem> onReject;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing here', style: TextStyle(color: AppColors.text3)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ModerationCard(item: items[i], processing: processingIds.contains(items[i].reelId), onApprove: onApprove, onReject: onReject, showActions: showActions),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard({required this.item, required this.processing, required this.onApprove, required this.onReject, required this.showActions});

  final ModerationItem item;
  final bool processing;
  final ValueChanged<ModerationItem> onApprove;
  final ValueChanged<ModerationItem> onReject;
  final bool showActions;

  Color get _statusColor {
    switch (item.status) {
      case 'approved': return const Color(0xFF10B981);
      case 'rejected': return AppColors.error;
      case 'flagged': return const Color(0xFFF59E0B);
      default: return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.surface2, AppColors.bg]))),
                      Container(color: Colors.black26),
                      const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 36)),
                      if (item.aiFlagged)
                        Positioned(top: 10, left: 12,
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(999)), child: const Text('AI FLAGGED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
                      Positioned(top: 10, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(999)),
                          child: Text(item.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.reelCaption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.text3),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item.creatorEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text3, fontSize: 12))),
                        if (item.aiConfidenceScore > 0) ...[
                          const SizedBox(width: 8),
                          Text('${(item.aiConfidenceScore * 100).toStringAsFixed(0)}% confidence', style: const TextStyle(color: AppColors.text3, fontSize: 11)),
                        ],
                      ],
                    ),
                    if (item.aiReason != null && item.aiReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('AI note: ${item.aiReason}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text3, fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                    if (showActions) ...[
                      const SizedBox(height: 12),
                      processing
                          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber)))
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => onReject(item),
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    label: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => onApprove(item),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)]));
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}
