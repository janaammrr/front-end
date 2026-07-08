import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full details view shared by Events and Workshops — shows everything the
/// backend actually has (time, location, description, capacity/available
/// seats) with no invented fields. No price is shown anywhere: this app
/// doesn't process payments.
class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({
    super.key,
    required this.kind,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startDateRaw,
    required this.endDateRaw,
    required this.location,
    required this.capacity,
    required this.availableSeats,
    required this.isPast,
    required this.alreadyBooked,
    required this.onBook,
    this.canDelete = false,
    this.onDelete,
  });

  /// "Event" or "Workshop", used for labels only.
  final String kind;
  final String title;
  final String description;
  final String imageUrl;
  final String? startDateRaw;
  final String? endDateRaw;
  final String location;
  final int? capacity;
  final int? availableSeats;
  final bool isPast;
  final bool alreadyBooked;
  final Future<void> Function() onBook;
  final bool canDelete;
  final Future<void> Function()? onDelete;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _booking = false;
  bool _booked = false;
  bool _deleting = false;

  bool get _full =>
      widget.availableSeats != null && widget.availableSeats! <= 0;

  Future<void> _book() async {
    setState(() => _booking = true);
    try {
      await widget.onBook();
      if (mounted) setState(() => _booked = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.listingCard,
        title: Text(
          'Delete ${widget.kind.toLowerCase()}',
          style: TextStyle(color: AppColors.listingInk),
        ),
        content: Text(
          'Delete ${widget.title}?',
          style: TextStyle(color: AppColors.listingTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || widget.onDelete == null) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'TBA';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
    final hasTime = parsed.hour != 0 || parsed.minute != 0;
    final datePart = '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    return hasTime ? '$datePart, $hour:$minute $ampm' : datePart;
  }

  @override
  Widget build(BuildContext context) {
    final booked = widget.alreadyBooked || _booked;
    final startText = _formatDateTime(widget.startDateRaw);
    final endText = widget.endDateRaw != null && widget.endDateRaw!.isNotEmpty
        ? _formatDateTime(widget.endDateRaw)
        : null;

    return Scaffold(
      backgroundColor: AppColors.listingBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.listingHeaderBg,
            pinned: true,
            expandedHeight: 240,
            leading: const BackButton(color: Colors.white),
            actions: [
              if (widget.canDelete)
                IconButton(
                  onPressed: _deleting ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: AppColors.listingInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (widget.isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.listingTextMuted.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Finished',
                            style: TextStyle(
                              color: AppColors.listingTextMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Starts',
                    value: startText,
                  ),
                  if (endText != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'Ends',
                      value: endText,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: widget.location,
                  ),
                  if (widget.capacity != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.event_seat_rounded,
                      label: 'Seats',
                      value:
                          '${widget.availableSeats}/${widget.capacity} available',
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'About',
                    style: TextStyle(
                      color: AppColors.listingInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description.isEmpty
                        ? 'No description provided.'
                        : widget.description,
                    style: TextStyle(
                      color: AppColors.listingTextMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (widget.isPast || booked || _full || _booking)
                          ? null
                          : _book,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: booked
                            ? const Color(0xFF10B981)
                            : AppColors.listingAccent,
                        disabledBackgroundColor: widget.isPast
                            ? AppColors.listingTextMuted.withValues(alpha: 0.2)
                            : (booked
                                  ? const Color(0xFF10B981)
                                  : AppColors.listingAccent.withValues(
                                      alpha: 0.5,
                                    )),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _booking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isPast
                                  ? '${widget.kind} finished'
                                  : booked
                                  ? 'Booked ✓'
                                  : _full
                                  ? 'Fully booked'
                                  : 'Book ${widget.kind}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.listingAccent),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.listingTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.listingInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
