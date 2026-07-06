import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../components/edit_listing_dialog.dart';
import '../theme/app_theme.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<EventModel> _booked = [];
  final Map<int, int> _bookingIds = {};
  List<EventModel> _created = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _bookingIds.clear();
    });
    try {
      final bookedRows = await EventService.getBookedRows();
      final booked = bookedRows.map((row) {
        final item = row['item'] as Map<String, dynamic>;
        final model = EventModel.fromJson(item);
        _bookingIds[model.id] = (row['bookingId'] as num).toInt();
        return model;
      }).toList();
      final created = await EventService.getCreated();
      if (mounted) {
        setState(() {
          _booked = booked;
          _created = created;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              color: AppColors.amber.withValues(alpha: 0.16),
              size: 200,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Text(
                        'My Events',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.amber,
                      ),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white38,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber,
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.amber,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.text3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    dividerColor: Colors.white.withValues(alpha: 0.08),
                    tabs: [
                      Tab(text: 'Booked (${_booked.length})'),
                      Tab(text: 'Created (${_created.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _EventList(
                          items: _booked,
                          emptyMessage: 'No booked events yet.',
                          actionLabel: 'Cancel booking',
                          actionIcon: Icons.event_busy_rounded,
                          onAction: (item) async {
                            final bookingId = _bookingIds[item.id];
                            if (bookingId == null) return;
                            await EventService.cancelBooking(bookingId);
                            await _load();
                          },
                        ),
                        _EventList(
                          items: _created,
                          emptyMessage: 'You have not created any events yet.',
                          actionLabel: 'Delete event',
                          actionIcon: Icons.delete_outline_rounded,
                          destructive: true,
                          onAction: (item) async {
                            await EventService.deleteEvent(item.id);
                            await _load();
                          },
                          onEdit: (item) async {
                            final saved = await showDialog<bool>(
                              context: context,
                              builder: (_) => EditListingDialog(
                                dialogTitle: 'Edit Event',
                                initialTitle: item.title,
                                initialDescription: item.description ?? '',
                                initialLocation: item.location ?? '',
                                initialDate: item.date ?? '',
                                initialPrice: item.price ?? 0,
                                onSave: ({
                                  required title,
                                  required description,
                                  required location,
                                  required date,
                                  required price,
                                  capacity,
                                }) => EventService.updateEvent(
                                  item.id,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.items,
    required this.emptyMessage,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.destructive = false,
    this.onEdit,
  });

  final List<EventModel> items;
  final String emptyMessage;
  final String actionLabel;
  final IconData actionIcon;
  final bool destructive;
  final Future<void> Function(EventModel item) onAction;
  final Future<void> Function(EventModel item)? onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_outlined,
              color: AppColors.border,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text3),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.amber,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _EventCard(
          item: items[i],
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          destructive: destructive,
          onAction: () => onAction(items[i]),
          onEdit: onEdit == null ? null : () => onEdit!(items[i]),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.item,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.destructive = false,
    this.onEdit,
  });

  final EventModel item;
  final String actionLabel;
  final IconData actionIcon;
  final bool destructive;
  final Future<void> Function() onAction;
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    final price = item.price ?? 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Event',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    price <= 0 ? 'Free' : '\$${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          color: AppColors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (item.location != null && item.location!.isNotEmpty)
                _Detail(icon: Icons.location_on_outlined, text: item.location!),
              if (item.date != null && item.date!.isNotEmpty)
                _Detail(icon: Icons.calendar_today_outlined, text: item.date!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface2,
                        title: Text(
                          actionLabel,
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              actionLabel,
                              style: TextStyle(
                                color: destructive
                                    ? AppColors.error
                                    : AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await onAction();
                  },
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: destructive
                        ? AppColors.error
                        : AppColors.amber,
                    side: BorderSide(
                      color:
                          (destructive
                                  ? AppColors.error
                                  : AppColors.amber)
                              .withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.text3),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text2, fontSize: 13),
            ),
          ),
        ],
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
      ),
    );
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
