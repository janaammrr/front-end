import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/workshop_service.dart';
import '../models/workshop_model.dart';
import '../components/edit_listing_dialog.dart';
import '../theme/app_theme.dart';

class MyWorkshopsScreen extends StatefulWidget {
  const MyWorkshopsScreen({super.key});

  @override
  State<MyWorkshopsScreen> createState() => _MyWorkshopsScreenState();
}

class _MyWorkshopsScreenState extends State<MyWorkshopsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<WorkshopModel> _booked = [];
  final Map<int, int> _bookingIds = {};
  List<WorkshopModel> _created = [];
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
    });
    try {
      final bookedRows = await WorkshopService.getBookedRows();
      final booked = bookedRows.map((row) {
        final item = row['item'] as Map<String, dynamic>;
        final model = WorkshopModel.fromJson(item);
        _bookingIds[model.id] = (row['bookingId'] as num).toInt();
        return model;
      }).toList();
      final created = await WorkshopService.getCreated();
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
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowOrb(
              color: AppColors.amberSoft.withValues(alpha: 0.14),
              size: 240,
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
                      Text(
                        'My Workshops',
                        style: TextStyle(
                          color: AppColors.text1,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.text3,
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
                    indicatorWeight: 2,
                    labelColor: AppColors.text1,
                    unselectedLabelColor: AppColors.text3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    dividerColor: AppColors.text1.withValues(alpha: 0.08),
                    tabs: [
                      Tab(text: 'Booked (${_booked.length})'),
                      Tab(text: 'Created (${_created.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _WorkshopList(
                          items: _booked,
                          emptyMessage:
                              'No booked workshops yet. Browse and book one!',
                          actionLabel: 'Cancel booking',
                          actionIcon: Icons.event_busy_rounded,
                          onAction: (item) async {
                            final bookingId = _bookingIds[item.id];
                            if (bookingId == null) return;
                            await WorkshopService.cancelBooking(bookingId);
                            await _load();
                          },
                        ),
                        _WorkshopList(
                          items: _created,
                          emptyMessage:
                              'You haven\'t created any workshops yet.',
                          actionLabel: 'Delete workshop',
                          actionIcon: Icons.delete_outline_rounded,
                          destructive: true,
                          onAction: (item) async {
                            await WorkshopService.deleteWorkshop(item.id);
                            await _load();
                          },
                          onEdit: (item) async {
                            final saved = await showDialog<bool>(
                              context: context,
                              builder: (_) => EditListingDialog(
                                dialogTitle: 'Edit Workshop',
                                initialTitle: item.title,
                                initialDescription: item.description ?? '',
                                initialLocation: item.location ?? '',
                                initialDate: item.date ?? '',
                                initialPrice: item.price ?? 0,
                                showCapacity: true,
                                initialCapacity: item.capacity,
                                onSave:
                                    ({
                                      required title,
                                      required description,
                                      required location,
                                      required date,
                                      required price,
                                      capacity,
                                    }) => WorkshopService.updateWorkshop(
                                      item.id,
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

class _WorkshopList extends StatelessWidget {
  const _WorkshopList({
    required this.items,
    required this.emptyMessage,
    this.actionLabel,
    this.actionIcon,
    this.destructive = false,
    this.onAction,
    this.onEdit,
  });

  final List<WorkshopModel> items;
  final String emptyMessage;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool destructive;
  final Future<void> Function(WorkshopModel item)? onAction;
  final Future<void> Function(WorkshopModel item)? onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, color: AppColors.border, size: 48),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text3),
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
        itemBuilder: (_, i) => _WorkshopCard(
          item: items[i],
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          destructive: destructive,
          onAction: onAction == null ? null : () => onAction!(items[i]),
          onEdit: onEdit == null ? null : () => onEdit!(items[i]),
        ),
      ),
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard({
    required this.item,
    this.actionLabel,
    this.actionIcon,
    this.destructive = false,
    this.onAction,
    this.onEdit,
  });

  final WorkshopModel item;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool destructive;
  final Future<void> Function()? onAction;
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
            color: AppColors.text1.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.text1.withValues(alpha: 0.1)),
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
                    child: Text(
                      'Workshop',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.capacity != null) ...[
                    _MetaChip(text: '${item.capacity} seats'),
                    const SizedBox(width: 8),
                  ],
                  _MetaChip(
                    text: price <= 0 ? 'Free' : '\$${price.toStringAsFixed(0)}',
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onEdit,
                      child: Padding(
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
                style: TextStyle(
                  color: AppColors.text1,
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
                  style: TextStyle(color: AppColors.text3, fontSize: 13),
                ),
              ],
              if (item.location != null && item.location!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _Detail(icon: Icons.location_on_outlined, text: item.location!),
              ],
              if (item.date != null && item.date!.isNotEmpty) ...[
                const SizedBox(height: 2),
                _Detail(icon: Icons.calendar_today_outlined, text: item.date!),
              ],
              if (onAction != null && actionLabel != null) ...[
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
                            actionLabel!,
                            style: TextStyle(color: AppColors.text1),
                          ),
                          content: Text(
                            'Are you sure?',
                            style: TextStyle(color: AppColors.text2),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                actionLabel!,
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
                      if (ok == true) await onAction!();
                    },
                    icon: Icon(actionIcon ?? Icons.delete_outline_rounded),
                    label: Text(actionLabel!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: destructive
                          ? AppColors.error
                          : AppColors.amber,
                      side: BorderSide(
                        color: (destructive ? AppColors.error : AppColors.amber)
                            .withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.text1.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.text2, fontSize: 12),
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
              style: TextStyle(color: AppColors.text2, fontSize: 13),
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
          color: AppColors.text1.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.text1.withValues(alpha: 0.12)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.text1,
          size: 18,
        ),
      ),
    );
  }
}
