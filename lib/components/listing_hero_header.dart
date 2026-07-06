import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// Dark greeting banner + search bar + Events/Workshops switcher, shared by
/// the Events and Workshops screens. Shows the real signed-in user's
/// name/photo/location (falls back gracefully when any of those aren't set)
/// — no invented data.
class ListingHeroHeader extends StatefulWidget {
  const ListingHeroHeader({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchChanged,
    required this.hintText,
    required this.activeSection,
    this.onSectionChanged,
  });

  final String title;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String hintText;

  /// Which of the two linked screens is currently showing.
  final ListingSection activeSection;

  /// Called when the user taps the other section's tab. Null hides the
  /// switcher (e.g. if this header is ever reused somewhere without a
  /// sibling screen to jump to).
  final ValueChanged<ListingSection>? onSectionChanged;

  @override
  State<ListingHeroHeader> createState() => _ListingHeroHeaderState();
}

enum ListingSection { events, workshops }

class _ListingHeroHeaderState extends State<ListingHeroHeader> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await UserService.getMe();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // Non-critical: header just shows a generic greeting.
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.firstname.isNotEmpty == true ? _user!.firstname : _user?.fullName;
    final location = _user?.location;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.listingHeaderBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                displayName: name ?? 'F',
                profileUrl: _user?.profileUrl,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null ? 'Hi, Welcome 👋' : 'Hi Welcome 👋 $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: const TextStyle(color: AppColors.listingAccentSoft, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (location != null && location.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.listingAccentSoft, size: 16),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (widget.onSectionChanged != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _sectionTab('Events', ListingSection.events)),
                  Expanded(child: _sectionTab('Workshops', ListingSection.workshops)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(color: AppColors.listingTextMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.listingTextMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTab(String label, ListingSection section) {
    final active = section == widget.activeSection;
    return GestureDetector(
      onTap: active ? null : () => widget.onSectionChanged?.call(section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? AppColors.listingAccentGradient : null,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.listingTextMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
