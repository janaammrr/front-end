import 'package:flutter/material.dart';

import '../../components/admin_suspend_actions.dart';
import '../../components/edit_listing_dialog.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class AdminWorkshopsScreen extends StatefulWidget {
  const AdminWorkshopsScreen({super.key});

  @override
  State<AdminWorkshopsScreen> createState() => _AdminWorkshopsScreenState();
}

class _AdminWorkshopsScreenState extends State<AdminWorkshopsScreen> {
  List<AdminListingItem> _workshops = [];
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
      final workshops = await AdminService.getWorkshops();
      if (!mounted) return;
      setState(() {
        _workshops = workshops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load workshops.');
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
        title: const Text('Workshops', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    if (_workshops.isEmpty) {
      return const Center(child: Text('No workshops found.', style: TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _workshops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final workshop = _workshops[index];
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
                      child: Text(workshop.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    if (workshop.suspended)
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
                if (workshop.description != null && workshop.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(workshop.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final saved = await showDialog<bool>(
                          context: context,
                          builder: (_) => EditListingDialog(
                            dialogTitle: 'Edit Workshop',
                            initialTitle: workshop.title,
                            initialDescription: workshop.description ?? '',
                            initialLocation: workshop.location ?? '',
                            initialDate: workshop.date ?? '',
                            initialPrice: workshop.price ?? 0,
                            showCapacity: true,
                            initialCapacity: workshop.capacity,
                            onSave: ({
                              required title,
                              required description,
                              required location,
                              required date,
                              required price,
                              capacity,
                            }) => AdminService.updateWorkshop(
                              workshop.id,
                              title: title,
                              description: description,
                              location: location,
                              capacity: capacity ?? 0,
                              date: date,
                              price: price,
                            ),
                          ),
                        );
                        if (saved == true) await _load();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                    ),
                    AdminSuspendActions(
                      suspended: workshop.suspended,
                      onToggleSuspend: (suspend, reason) async {
                        try {
                          await AdminService.setWorkshopSuspended(workshop.id, suspend, reason: reason);
                          await _load();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not update workshop.'))),
                          );
                        }
                      },
                      onDelete: () async {
                        try {
                          await AdminService.deleteWorkshop(workshop.id);
                          if (mounted) setState(() => _workshops.removeAt(index));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not delete workshop.'))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
