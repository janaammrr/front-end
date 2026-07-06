import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../models/workshop_model.dart';
import '../services/api_client.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../services/workshop_service.dart';
import '../theme/app_theme.dart';

/// Mirrors the web app's "/recommendations" page: events and workshops
/// suggested based on the user's onboarding preferences.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _loading = true;
  String? _error;
  Recommendations? _data;
  final Set<int> _bookedEventIds = {};
  final Set<int> _bookedWorkshopIds = {};

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
      final data = await UserService.getRecommendations(limit: 10);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load recommendations.');
        _loading = false;
      });
    }
  }

  Future<void> _bookEvent(EventModel event) async {
    try {
      await EventService.bookEvent(event.id);
      if (mounted) {
        setState(() => _bookedEventIds.add(event.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event booked!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Booking failed.'))),
        );
      }
    }
  }

  Future<void> _bookWorkshop(WorkshopModel workshop) async {
    try {
      await WorkshopService.bookWorkshop(workshop.id);
      if (mounted) {
        setState(() => _bookedWorkshopIds.add(workshop.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workshop booked!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Booking failed.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Recommended for You', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.amber));
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

    final data = _data;
    if (data == null || (data.events.isEmpty && data.workshops.isEmpty)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No recommendations yet. Set your preferred categories to get personalized suggestions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.preferences.isNotEmpty) ...[
            Text(
              'Based on your interests: ${data.preferences}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
          if (data.events.isNotEmpty) ...[
            const _SectionTitle('Recommended Events'),
            for (final event in data.events)
              _RecommendationCard(
                title: event.title,
                subtitle: event.description ?? '',
                date: event.date,
                price: event.price,
                booked: _bookedEventIds.contains(event.id),
                onBook: () => _bookEvent(event),
              ),
            const SizedBox(height: 20),
          ],
          if (data.workshops.isNotEmpty) ...[
            const _SectionTitle('Recommended Workshops'),
            for (final workshop in data.workshops)
              _RecommendationCard(
                title: workshop.title,
                subtitle: workshop.description ?? '',
                date: workshop.date,
                price: workshop.price,
                booked: _bookedWorkshopIds.contains(workshop.id),
                onBook: () => _bookWorkshop(workshop),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.price,
    required this.booked,
    required this.onBook,
  });

  final String title;
  final String subtitle;
  final String? date;
  final double? price;
  final bool booked;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    if (date != null && date!.isNotEmpty) date!,
                    if (price != null) '\$${price!.toStringAsFixed(2)}',
                  ].join('  ·  '),
                  style: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: booked ? null : onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: booked ? Colors.white24 : AppColors.amber,
              disabledBackgroundColor: Colors.white24,
            ),
            child: Text(booked ? 'Booked' : 'Book'),
          ),
        ],
      ),
    );
  }
}
