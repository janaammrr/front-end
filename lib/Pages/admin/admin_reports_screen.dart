import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

const _statuses = ['PENDING', 'RESOLVED', 'DISMISSED'];

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<AdminReportItem> _reports = [];
  bool _loading = true;
  String? _error;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await AdminService.getReports(status: _statuses[_tabController.index]);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load reports.');
        _loading = false;
      });
    }
  }

  Future<void> _resolve(AdminReportItem report, String status) async {
    String reviewNote = '';
    if (status != 'PENDING') {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(status == 'RESOLVED' ? 'Resolve report?' : 'Dismiss report?', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Optional review note', hintStyle: TextStyle(color: Colors.white38)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      reviewNote = controller.text.trim();
    }

    setState(() => _processingIds.add(report.id));
    try {
      await AdminService.updateReportStatus(report.id, status, reviewNote: reviewNote);
      if (mounted) setState(() => _reports.removeWhere((r) => r.id == report.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not update report.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(report.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.text3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: _statuses.map((s) => Tab(text: s)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports in this category.', style: TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final report = _reports[index];
          final processing = _processingIds.contains(report.id);
          final isPending = _statuses[_tabController.index] == 'PENDING';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(report.targetType, style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text('#${report.targetId ?? '-'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(report.reason, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Reported by ${report.reporterName}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                if (isPending) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: processing ? null : () => _resolve(report, 'RESOLVED'),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF10B981), side: const BorderSide(color: Color(0xFF10B981))),
                        child: const Text('Resolve'),
                      ),
                      OutlinedButton(
                        onPressed: processing ? null : () => _resolve(report, 'DISMISSED'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Colors.white24)),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
