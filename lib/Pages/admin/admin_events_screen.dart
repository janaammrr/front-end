import 'package:flutter/material.dart';

import '../../components/admin_suspend_actions.dart';
import '../../components/edit_listing_dialog.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  List<AdminListingItem> _events = [];
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
      final events = await AdminService.getEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load events.');
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
        title: const Text('Events', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    if (_events.isEmpty) {
      return const Center(child: Text('No events found.', style: TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final event = _events[index];
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
                      child: Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    if (event.suspended)
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
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(event.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
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
                            dialogTitle: 'Edit Event',
                            initialTitle: event.title,
                            initialDescription: event.description ?? '',
                            initialLocation: event.location ?? '',
                            initialDate: event.date ?? '',
                            initialPrice: event.price ?? 0,
                            onSave: ({
                              required title,
                              required description,
                              required location,
                              required date,
                              required price,
                              capacity,
                            }) => AdminService.updateEvent(
                              event.id,
                              title: title,
                              description: description,
                              location: location,
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
                      suspended: event.suspended,
                      onToggleSuspend: (suspend, reason) async {
                        try {
                          await AdminService.setEventSuspended(event.id, suspend, reason: reason);
                          await _load();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not update event.'))),
                          );
                        }
                      },
                      onDelete: () async {
                        try {
                          await AdminService.deleteEvent(event.id);
                          if (mounted) setState(() => _events.removeAt(index));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not delete event.'))),
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
