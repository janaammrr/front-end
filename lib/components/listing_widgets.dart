import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared presentation widgets for the Events and Workshops screens, styled
/// to the requested light/peach-orange listings palette (see
/// [AppColors.listingInk] and friends).

/// Curated, verified-reachable stock photos used as cover art for
/// events/workshops, since the backend has no cover-image field. Purely
/// decorative — never presented as real data.
const _mockImagesByCategory = {
  'Development': [
    'https://images.unsplash.com/photo-1517180102446-f3ece451e9d8?w=800',
    'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800',
  ],
  'AI': [
    'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800',
    'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
  ],
  'Design': [
    'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800',
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800',
  ],
  'Business': [
    'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800',
  ],
  'Community': [
    'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800',
    'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
  ],
};
const _mockImagesDefault = [
  'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
  'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800',
];

String mockImageFor(String category, int id) {
  final options = _mockImagesByCategory[category] ?? _mockImagesDefault;
  return options[id % options.length];
}

/// The categories a creator can explicitly pick when making a new event or
/// workshop. The backend has no category column for either (confirmed
/// against its create/update request shapes), so the choice is encoded as a
/// small tag on the end of the real `description` field it already accepts
/// — this keeps it genuinely backend-persisted and consistent for every
/// viewer/device, rather than a client-only guess or local-only override.
const listingCategories = [
  'Development',
  'AI',
  'Design',
  'Business',
  'Community',
];

final _categoryTagPattern = RegExp(r'\s*\[cat:(\w+)\]\s*$');

String appendCategoryTag(String description, String? category) {
  final clean = stripCategoryTag(description);
  if (category == null) return clean;
  return '$clean [cat:$category]';
}

/// Explicit category chosen at creation time, if any.
String? extractCategoryTag(String description) {
  final match = _categoryTagPattern.firstMatch(description);
  final tag = match?.group(1);
  return listingCategories.contains(tag) ? tag : null;
}

/// The description with the internal category tag removed, safe to display.
String stripCategoryTag(String description) {
  return description.replaceFirst(_categoryTagPattern, '');
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Development':
      return Icons.code_rounded;
    case 'AI':
      return Icons.auto_awesome_rounded;
    case 'Design':
      return Icons.palette_outlined;
    case 'Business':
      return Icons.trending_up_rounded;
    case 'Community':
      return Icons.groups_outlined;
    default:
      return Icons.grid_view_rounded;
  }
}

class ListingCategoryChip extends StatelessWidget {
  const ListingCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.listingAccent
              : AppColors.listingAccentSoft.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.listingAccent
                : AppColors.listingAccentSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon(label),
              size: 16,
              color: selected ? Colors.white : AppColors.listingAccent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.listingInk,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Upcoming / Past" segmented toggle, filtering on each item's real date.
class UpcomingPastToggle extends StatelessWidget {
  const UpcomingPastToggle({
    super.key,
    required this.showUpcoming,
    required this.onChanged,
  });

  final bool showUpcoming;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.listingAccentSoft.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _segment(context, 'Upcoming', true)),
          Expanded(child: _segment(context, 'Past', false)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, bool value) {
    final active = value == showUpcoming;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.listingCard : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? AppColors.listingAccent
                : AppColors.listingTextMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Big featured card for the "Popular" horizontal carousel.
class ListingPopularCard extends StatelessWidget {
  const ListingPopularCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.dateText,
    required this.locationText,
    required this.ctaLabel,
    required this.ctaBusy,
    required this.ctaDone,
    required this.onCta,
    this.isPast = false,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String dateText;
  final String locationText;
  final String ctaLabel;
  final bool ctaBusy;
  final bool ctaDone;
  final VoidCallback? onCta;
  final bool isPast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _JoinButton(
                      label: ctaLabel,
                      busy: ctaBusy,
                      done: ctaDone,
                      onTap: onCta,
                      fullWidth: true,
                      isPast: isPast,
                    ),
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

/// Full-width vertical listing card used for the main list (cover image on
/// top, details below), matching the requested reference design.
class ListingRowCard extends StatelessWidget {
  const ListingRowCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.dateText,
    required this.locationText,
    required this.ctaLabel,
    required this.ctaBusy,
    required this.ctaDone,
    required this.onCta,
    this.seatsLabel,
    this.isPast = false,
    this.canDelete = false,
    this.deleting = false,
    this.onDelete,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String dateText;
  final String locationText;
  final String ctaLabel;
  final bool ctaBusy;
  final bool ctaDone;
  final VoidCallback? onCta;

  /// e.g. "8/20 seats available" — shown only when the backend actually
  /// provided a capacity, computed from the real `bookedCount` it returns.
  final String? seatsLabel;

  final bool isPast;
  final bool canDelete;
  final bool deleting;
  final VoidCallback? onDelete;

  /// Opens the full details screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.listingCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.listingCardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                if (canDelete)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: InkWell(
                      onTap: deleting ? null : onDelete,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: deleting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.listingInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.listingTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: TextStyle(
                          color: AppColors.listingTextMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.listingTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.listingTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (seatsLabel != null) ...[
                        Icon(
                          Icons.event_seat_outlined,
                          size: 15,
                          color: AppColors.listingTextMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            seatsLabel!,
                            style: TextStyle(
                              color: AppColors.listingTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      _JoinButton(
                        label: ctaLabel,
                        busy: ctaBusy,
                        done: ctaDone,
                        onTap: onCta,
                        isPast: isPast,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.label,
    required this.busy,
    required this.done,
    required this.onTap,
    this.fullWidth = false,
    this.isPast = false,
  });

  final String label;
  final bool busy;
  final bool done;
  final VoidCallback? onTap;
  final bool fullWidth;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    if (isPast) {
      final child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.listingTextMuted.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Finished',
          style: TextStyle(
            color: AppColors.listingTextMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      );
      return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
    }
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: done ? null : AppColors.listingAccentGradient,
        color: done ? const Color(0xFF10B981) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              done ? 'Booked ✓' : label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
    );
    return InkWell(
      onTap: busy || done ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: fullWidth ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}
