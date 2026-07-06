import 'package:flutter/material.dart';

import '../../components/admin_suspend_actions.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class AdminProvidersScreen extends StatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  State<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends State<AdminProvidersScreen> {
  List<AdminUserItem> _providers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final providers = await AdminService.getProviders();
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load providers.');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Providers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    if (_providers.isEmpty) {
      return const Center(child: Text('No providers found.', style: TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final provider = _providers[index];
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(provider.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(provider.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (provider.suspended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Suspended', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AdminSuspendActions(
                  suspended: provider.suspended,
                  onToggleSuspend: (suspend, reason) async {
                    try {
                      await AdminService.setProviderSuspended(provider.id, suspend, reason: reason);
                      await _load();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not update provider.'))),
                      );
                    }
                  },
                  onDelete: () async {
                    try {
                      await AdminService.deleteProvider(provider.id);
                      if (mounted) setState(() => _providers.removeAt(index));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not delete provider.'))),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
