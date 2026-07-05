import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/auth.dart';
import 'profile_screen.dart';
import '../models/workshop_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/workshop_service.dart';
import '../theme/app_theme.dart';

class WorkshopPage extends StatefulWidget {
  const WorkshopPage({super.key});

  @override
  State<WorkshopPage> createState() => _WorkshopPageState();
}

class _WorkshopPageState extends State<WorkshopPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
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
    ..._workshops.map((w) => w.category).where((c) => c.isNotEmpty),
  }.toList();

  List<_WorkshopItem> get _filteredWorkshops {
    final search = _searchController.text.trim().toLowerCase();
    return _workshops.where((workshop) {
      final categoryMatch =
          _selectedCategory == 'All' || workshop.category == _selectedCategory;
      final searchMatch =
          search.isEmpty ||
          workshop.name.toLowerCase().contains(search) ||
          workshop.creator.toLowerCase().contains(search) ||
          workshop.description.toLowerCase().contains(search);
      return categoryMatch && searchMatch;
    }).toList();
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
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white38,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.white54)),
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
                  backgroundColor: AppColors.amber,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 700;
    final crossAxisCount = isMobile ? 1 : (size.width < 1120 ? 2 : 3);
    final workshops = _filteredWorkshops;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _BrandMark(),
                            const Spacer(),
                            _GlassIconButton(
                              icon: Icons.person_outline_rounded,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Workshop Marketplace',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Discover, create, and book premium learning experiences.',
                          style: TextStyle(
                            color: AppColors.text2,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SearchInput(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final selected = category == _selectedCategory;
                              return _CategoryChip(
                                label: category,
                                selected: selected,
                                onTap: () => setState(
                                  () => _selectedCategory = category,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '${workshops.length} Workshops',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _openCreateWorkshopPanel,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amber,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                  sliver: workshops.isEmpty
                      ? const SliverToBoxAdapter(child: _EmptyState())
                      : SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: isMobile ? 0.86 : 0.92,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            childCount: workshops.length,
                            (context, index) => _WorkshopCard(
                              workshop: workshops[index],
                              animationDelay: index * 70,
                              canDelete: _createdWorkshopIds.contains(
                                workshops[index].id,
                              ),
                              onDelete: () => _deleteWorkshop(workshops[index]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkshop(_WorkshopItem workshop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text(
          'Delete workshop',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete ${workshop.name}?',
          style: const TextStyle(color: Colors.white70),
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
    if (ok != true) return;
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

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.bg, AppColors.bg],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/FLAME_LOGO.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        const Text(
          'Flame Workshops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search workshops, creators, or topics',
        hintStyle: const TextStyle(color: AppColors.text2),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.text2),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.1),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.amber.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.amberSoft
                : Colors.white.withValues(alpha: 0.11),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.text2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WorkshopCard extends StatefulWidget {
  const _WorkshopCard({
    required this.workshop,
    required this.animationDelay,
    required this.canDelete,
    required this.onDelete,
  });

  final _WorkshopItem workshop;
  final int animationDelay;
  final bool canDelete;
  final Future<void> Function() onDelete;

  @override
  State<_WorkshopCard> createState() => _WorkshopCardState();
}

class _WorkshopCardState extends State<_WorkshopCard> {
  bool _hovered = false;
  bool _booking = false;
  bool _booked = false;
  bool _deleting = false;

  Future<void> _book() async {
    if (_booking || _booked) return;
    setState(() => _booking = true);
    try {
      await WorkshopService.bookWorkshop(widget.workshop.id);
      if (mounted) {
        setState(() {
          _booked = true;
          _booking = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workshop booked successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
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
    if (_deleting) return;
    setState(() => _deleting = true);
    await widget.onDelete();
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.workshop;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 380 + widget.animationDelay),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 28 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.015 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(item.imageUrl, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _PillTag(label: item.category),
                          ),
                          if (widget.canDelete)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'Delete workshop',
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
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: _PillTag(
                              label: item.isFree
                                  ? 'Free'
                                  : '\$${item.price.toStringAsFixed(0)}',
                              solid: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text2,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CardDetail(
                            icon: Icons.person_outline,
                            text: item.creator,
                          ),
                          _CardDetail(
                            icon: Icons.schedule_rounded,
                            text: item.dateTime,
                          ),
                          _CardDetail(
                            icon: Icons.event_seat_outlined,
                            text:
                                '${item.availableSeats} seats • ${item.tokenSeats} token seats',
                          ),
                          _CardDetail(
                            icon: Icons.location_on_outlined,
                            text: item.location,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _booking || _booked ? null : _book,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _booked
                                    ? const Color(0xFF10B981)
                                    : AppColors.amber,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _booked
                                    ? const Color(0xFF10B981)
                                    : AppColors.amber.withValues(alpha: 0.5),
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _booking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _booked ? 'Booked ✓' : 'Book',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.text2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text2, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.label, this.solid = false});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid
            ? AppColors.amber
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CreateWorkshopDialog extends StatefulWidget {
  const _CreateWorkshopDialog();

  @override
  State<_CreateWorkshopDialog> createState() => _CreateWorkshopDialogState();
}

class _CreateWorkshopDialogState extends State<_CreateWorkshopDialog> {
  bool _creating = false;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _priceController.dispose();
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
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        date: _dateController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
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
    final width = media.width * 0.8;
    final height = media.height * 0.8;

    return Center(
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
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
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Build your workshop details and publish to the backend.',
                                style: TextStyle(color: AppColors.text2),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),
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
                          _FormFieldBlock(
                            label: 'Price',
                            child: _StyledTextField(
                              hint: '300',
                              keyboardType: TextInputType.number,
                              controller: _priceController,
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
                            backgroundColor: AppColors.amber,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.amber.withValues(alpha: 0.5),
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
        : (width > 900 ? (width * 0.8 - 74) / 2 : width);
    return SizedBox(
      width: blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
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
    this.keyboardType,
    this.controller,
  });

  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.text3),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white70),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No workshops found for this search. Try another category or query.',
              style: TextStyle(color: AppColors.text2),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopItem {
  const _WorkshopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.creator,
    required this.dateTime,
    required this.availableSeats,
    required this.tokenSeats,
    required this.isFree,
    required this.price,
    required this.category,
    required this.location,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String description;
  final String creator;
  final String dateTime;
  final int availableSeats;
  final int tokenSeats;
  final bool isFree;
  final double price;
  final String category;
  final String location;
  final String imageUrl;

  factory _WorkshopItem.fromModel(WorkshopModel m) => _WorkshopItem(
    id: m.id,
    name: m.title,
    description: m.description ?? '',
    creator: 'Flame',
    dateTime: (m.date == null || m.date!.isEmpty) ? 'TBA' : m.date!,
    availableSeats: m.capacity ?? 0,
    tokenSeats: 0,
    isFree: (m.price ?? 0) <= 0,
    price: m.price ?? 0,
    category: _categoryFor('${m.title} ${m.description ?? ''}'),
    location: m.location ?? 'TBA',
    imageUrl:
        'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=1200',
  );
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
