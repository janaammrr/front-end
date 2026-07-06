import 'package:flutter/material.dart';
import '../auth/auth.dart';
import '../components/listing_hero_header.dart';
import '../components/listing_widgets.dart';
import '../models/workshop_model.dart';
import 'listing_detail_screen.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/workshop_service.dart';
import '../theme/app_theme.dart';

class WorkshopPage extends StatefulWidget {
  const WorkshopPage({
    super.key,
    this.activeSection = ListingSection.workshops,
    this.onSectionChanged,
  });

  final ListingSection activeSection;
  final ValueChanged<ListingSection>? onSectionChanged;

  @override
  State<WorkshopPage> createState() => _WorkshopPageState();
}

class _WorkshopPageState extends State<WorkshopPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showUpcoming = true;
  List<_WorkshopItem> _workshops = [];
  Set<int> _createdWorkshopIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  Future<void> _loadWorkshops() async {
    try {
      final models = await WorkshopService.getAll();
      Set<int> createdIds = {};
      try {
        final created = await WorkshopService.getCreated();
        createdIds = created.map((workshop) => workshop.id).toSet();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _workshops = models.map(_WorkshopItem.fromModel).toList();
        _createdWorkshopIds = createdIds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
        return;
      }
      setState(() {
        _error = ApiClient.errorMessage(
          e,
          fallback: 'Could not load workshops.',
        );
        _loading = false;
      });
    }
  }

  List<String> get _categories => <String>{
    'All',
    ...listingCategories,
    ..._workshops.map((w) => w.category).where((c) => c.isNotEmpty),
  }.toList();

  bool _isUpcoming(_WorkshopItem workshop) {
    final parsed = DateTime.tryParse(workshop.dateTime);
    if (parsed == null) return true;
    final today = DateTime.now();
    return !parsed.isBefore(DateTime(today.year, today.month, today.day));
  }

  List<_WorkshopItem> get _filteredWorkshops {
    final search = _searchController.text.trim().toLowerCase();
    return _workshops.where((workshop) {
      final categoryMatch =
          _selectedCategory == 'All' || workshop.category == _selectedCategory;
      final searchMatch =
          search.isEmpty ||
          workshop.name.toLowerCase().contains(search) ||
          workshop.description.toLowerCase().contains(search);
      final timeMatch = _isUpcoming(workshop) == _showUpcoming;
      return categoryMatch && searchMatch && timeMatch;
    }).toList();
  }

  List<_WorkshopItem> get _popularWorkshops {
    final sorted = [..._workshops]
      ..sort((a, b) {
        final da = DateTime.tryParse(a.dateTime);
        final db = DateTime.tryParse(b.dateTime);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return sorted.take(4).toList();
  }

  Future<void> _openCreateWorkshopPanel() async {
    final created = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create workshop',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: const _CreateWorkshopDialog(),
          ),
        );
      },
    );
    if (created == true) {
      setState(() {
        _loading = true;
        _error = null;
      });
      _loadWorkshops();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.listingBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.listingAccent),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.listingBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.listingTextMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.listingInk),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadWorkshops();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.listingAccent,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final workshops = _filteredWorkshops;
    final popular = _popularWorkshops;

    return Scaffold(
      backgroundColor: AppColors.listingBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateWorkshopPanel,
        backgroundColor: AppColors.listingAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ListingHeroHeader(
                title: 'Learn something new today',
                searchController: _searchController,
                onSearchChanged: (_) => setState(() {}),
                hintText: 'Find amazing workshops',
                activeSection: widget.activeSection,
                onSectionChanged: widget.onSectionChanged,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (popular.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Popular Workshops 🔥',
                        trailing: '${workshops.length} found',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: popular.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) =>
                              _PopularWorkshopCard(workshop: popular[index]),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    const Text(
                      'Choose By Category',
                      style: TextStyle(
                        color: AppColors.listingInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return ListingCategoryChip(
                            label: category,
                            selected: category == _selectedCategory,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    UpcomingPastToggle(
                      showUpcoming: _showUpcoming,
                      onChanged: (value) =>
                          setState(() => _showUpcoming = value),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: workshops.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyState())
                  : SliverList.separated(
                      itemCount: workshops.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _WorkshopRow(
                        workshop: workshops[index],
                        canDelete: _createdWorkshopIds.contains(
                          workshops[index].id,
                        ),
                        onDelete: () => _deleteWorkshop(workshops[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWorkshop(_WorkshopItem workshop) async {
    try {
      await WorkshopService.deleteWorkshop(workshop.id);
      if (!mounted) return;
      setState(() {
        _workshops.removeWhere((item) => item.id == workshop.id);
        _createdWorkshopIds.remove(workshop.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workshop deleted.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiClient.errorMessage(e, fallback: 'Could not delete workshop.'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.listingInk,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: const TextStyle(
            color: AppColors.listingAccent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─── Popular card wrapper ──────────────────────────────────────────────────────

class _PopularWorkshopCard extends StatefulWidget {
  const _PopularWorkshopCard({required this.workshop});

  final _WorkshopItem workshop;

  @override
  State<_PopularWorkshopCard> createState() => _PopularWorkshopCardState();
}

class _PopularWorkshopCardState extends State<_PopularWorkshopCard> {
  bool _booking = false;
  bool _booked = false;

  Future<void> _openDetails() async {
    final item = widget.workshop;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          kind: 'Workshop',
          title: item.name,
          description: item.description,
          imageUrl: item.imageUrl,
          startDateRaw: item.startDateRaw,
          endDateRaw: item.endDateRaw,
          location: item.location,
          capacity: item.capacity,
          availableSeats: item.availableSeats,
          isPast: item.isPast,
          alreadyBooked: _booked,
          onBook: () => WorkshopService.bookWorkshop(item.id),
        ),
      ),
    );
  }

  Future<void> _book() async {
    if (widget.workshop.isPast) return;
    setState(() => _booking = true);
    try {
      await WorkshopService.bookWorkshop(widget.workshop.id);
      if (mounted) {
        setState(() {
          _booked = true;
          _booking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.errorMessage(e, fallback: 'Booking failed.'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.workshop;
    return ListingPopularCard(
      imageUrl: item.imageUrl,
      title: item.name,
      dateText: item.dateTime,
      locationText: item.location,
      ctaLabel: 'Book',
      ctaBusy: _booking,
      ctaDone: _booked,
      onCta: item.isPast ? null : _book,
      isPast: item.isPast,
      onTap: _openDetails,
    );
  }
}

// ─── Row card wrapper ──────────────────────────────────────────────────────────

class _WorkshopRow extends StatefulWidget {
  const _WorkshopRow({
    required this.workshop,
    required this.canDelete,
    required this.onDelete,
  });

  final _WorkshopItem workshop;
  final bool canDelete;
  final Future<void> Function() onDelete;

  @override
  State<_WorkshopRow> createState() => _WorkshopRowState();
}

class _WorkshopRowState extends State<_WorkshopRow> {
  bool _booking = false;
  bool _booked = false;
  bool _deleting = false;

  Future<void> _openDetails() async {
    final item = widget.workshop;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          kind: 'Workshop',
          title: item.name,
          description: item.description,
          imageUrl: item.imageUrl,
          startDateRaw: item.startDateRaw,
          endDateRaw: item.endDateRaw,
          location: item.location,
          capacity: item.capacity,
          availableSeats: item.availableSeats,
          isPast: item.isPast,
          alreadyBooked: _booked,
          onBook: () => WorkshopService.bookWorkshop(item.id),
          canDelete: widget.canDelete,
          onDelete: widget.onDelete,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _book() async {
    if (widget.workshop.isPast) return;
    setState(() => _booking = true);
    try {
      await WorkshopService.bookWorkshop(widget.workshop.id);
      if (mounted) {
        setState(() {
          _booked = true;
          _booking = false;
        });
      }
    } catch (e) {
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        return;
      }
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.errorMessage(e, fallback: 'Booking failed.'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    await widget.onDelete();
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.workshop;
    return ListingRowCard(
      imageUrl: item.imageUrl,
      title: item.name,
      dateText: item.dateTime,
      locationText: item.location,
      ctaLabel: 'Book',
      ctaBusy: _booking,
      ctaDone: _booked,
      onCta: item.isPast ? null : _book,
      seatsLabel: item.capacity != null
          ? '${item.availableSeats}/${item.capacity} seats available'
          : null,
      isPast: item.isPast,
      canDelete: widget.canDelete,
      deleting: _deleting,
      onDelete: _delete,
      onTap: _openDetails,
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.listingCard,
        border: Border.all(color: AppColors.listingCardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.listingTextMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No workshops found for this search. Try another category or query.',
              style: TextStyle(color: AppColors.listingTextMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Create Workshop Dialog ────────────────────────────────────────────────────

class _CreateWorkshopDialog extends StatefulWidget {
  const _CreateWorkshopDialog();

  @override
  State<_CreateWorkshopDialog> createState() => _CreateWorkshopDialogState();
}

class _CreateWorkshopDialogState extends State<_CreateWorkshopDialog> {
  bool _creating = false;
  String? _category;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a workshop name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      await WorkshopService.createWorkshop(
        title: title,
        description: appendCategoryTag(_descController.text.trim(), _category),
        location: _locationController.text.trim(),
        date: _dateController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
        return;
      }
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.errorMessage(e, fallback: 'Failed to create workshop.'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final width = media.width * 0.9;
    final height = media.height * 0.8;

    return Center(
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.listingCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.listingCardBorder),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Workshop',
                              style: TextStyle(
                                color: AppColors.listingInk,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Build your workshop details and publish to the backend.',
                              style: TextStyle(
                                color: AppColors.listingTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.listingTextMuted,
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.listingCardBorder, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _FormFieldBlock(
                          label: 'Title *',
                          child: _StyledTextField(
                            hint: 'Spring Boot Masterclass',
                            controller: _nameController,
                          ),
                        ),
                        _FormFieldBlock(
                          label: 'Category',
                          wide: true,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final option in listingCategories)
                                ListingCategoryChip(
                                  label: option,
                                  selected: _category == option,
                                  onTap: () => setState(
                                    () => _category = _category == option
                                        ? null
                                        : option,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _FormFieldBlock(
                          label: 'Description',
                          wide: true,
                          child: _StyledTextField(
                            hint: 'Deep dive into Spring',
                            maxLines: 4,
                            controller: _descController,
                          ),
                        ),
                        _FormFieldBlock(
                          label: 'Location',
                          child: _StyledTextField(
                            hint: 'Alexandria',
                            controller: _locationController,
                          ),
                        ),
                        _FormFieldBlock(
                          label: 'Date',
                          child: _StyledTextField(
                            hint: '2026-06-15',
                            controller: _dateController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _creating ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.listingAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.listingAccent
                              .withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Workshop'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormFieldBlock extends StatelessWidget {
  const _FormFieldBlock({
    required this.label,
    required this.child,
    this.wide = false,
  });

  final String label;
  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final blockWidth = wide
        ? width
        : (width > 900 ? (width * 0.9 - 74) / 2 : width);
    return SizedBox(
      width: blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.listingInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.hint,
    this.maxLines = 1,
    this.controller,
  });

  final String hint;
  final int maxLines;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.listingInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.listingTextMuted),
        filled: true,
        fillColor: AppColors.listingAccentSoft.withValues(alpha: 0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.listingAccent),
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _WorkshopItem {
  const _WorkshopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.dateTime,
    required this.category,
    required this.location,
    required this.imageUrl,
    this.startDateRaw,
    this.endDateRaw,
    this.capacity,
    this.availableSeats,
  });

  final int id;
  final String name;
  final String description;
  final String dateTime;
  final String category;
  final String location;
  final String imageUrl;
  final String? startDateRaw;
  final String? endDateRaw;
  final int? capacity;
  final int? availableSeats;

  bool get isPast => _isPastDate(endDateRaw ?? startDateRaw);

  factory _WorkshopItem.fromModel(WorkshopModel m) {
    final rawDescription = m.description ?? '';
    final category =
        extractCategoryTag(rawDescription) ??
        _categoryFor('${m.title} $rawDescription');
    return _WorkshopItem(
      id: m.id,
      name: m.title,
      description: stripCategoryTag(rawDescription),
      capacity: m.capacity,
      availableSeats: m.availableSeats,
      dateTime: (m.date == null || m.date!.isEmpty) ? 'TBA' : m.date!,
      startDateRaw: m.startDateRaw,
      endDateRaw: m.endDateRaw,
      category: category,
      location: m.location ?? 'TBA',
      imageUrl: mockImageFor(category, m.id),
    );
  }
}

bool _isPastDate(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return false;
  return parsed.isBefore(DateTime.now());
}

String _categoryFor(String value) {
  final text = value.toLowerCase();
  if (text.contains('spring') ||
      text.contains('boot') ||
      text.contains('code') ||
      text.contains('programming') ||
      text.contains('software')) {
    return 'Development';
  }
  if (text.contains('ai') ||
      text.contains('data') ||
      text.contains('machine')) {
    return 'AI';
  }
  if (text.contains('design') || text.contains('ui') || text.contains('ux')) {
    return 'Design';
  }
  if (text.contains('business') ||
      text.contains('marketing') ||
      text.contains('startup')) {
    return 'Business';
  }
  return 'General';
}
