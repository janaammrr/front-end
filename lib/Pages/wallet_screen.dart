import 'dart:ui';
import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<_Transaction> _transactions = [
    _Transaction(type: 'debit', title: 'Workshop: Creative Branding Sprint', amount: -49.0, date: 'May 8, 2025', icon: Icons.school_outlined),
    _Transaction(type: 'credit', title: 'Token Purchase — 20 Tokens', amount: 20.0, date: 'May 6, 2025', icon: Icons.add_circle_outline_rounded, isToken: true),
    _Transaction(type: 'debit', title: 'Workshop: Mobile UI Motion Lab', amount: -59.0, date: 'Apr 20, 2025', icon: Icons.school_outlined),
    _Transaction(type: 'debit', title: 'Event: Flame Creator Summit', amount: -120.0, date: 'Apr 15, 2025', icon: Icons.event_outlined),
    _Transaction(type: 'credit', title: 'Token Purchase — 10 Tokens', amount: 10.0, date: 'Apr 10, 2025', icon: Icons.add_circle_outline_rounded, isToken: true),
    _Transaction(type: 'debit', title: 'Token Seat: AI Webinar', amount: -2.0, date: 'Apr 8, 2025', icon: Icons.local_fire_department_outlined, isToken: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddTokens() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddTokensSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.18), size: 220)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.16), size: 240)),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Row(
                          children: [
                            _BackButton(onTap: () => Navigator.of(context).pop()),
                            const SizedBox(width: 12),
                            const Text('Wallet & Tokens', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _BalanceCard(onAddTokens: _showAddTokens),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _QuickActionButton(icon: Icons.add_rounded, label: 'Add Funds', onTap: () {})),
                            const SizedBox(width: 10),
                            Expanded(child: _QuickActionButton(icon: Icons.local_fire_department_rounded, label: 'Buy Tokens', onTap: _showAddTokens, accent: true)),
                            const SizedBox(width: 10),
                            Expanded(child: _QuickActionButton(icon: Icons.credit_card_outlined, label: 'Payment Methods', onTap: () {})),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _TokenInfoCard(),
                      ),
                      const SizedBox(height: 20),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFFFF7A18),
                        indicatorWeight: 2,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF6B7280),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                        dividerColor: Colors.white.withValues(alpha: 0.08),
                        tabs: const [Tab(text: 'Transactions'), Tab(text: 'Token History')],
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _TransactionsList(items: _transactions.where((t) => !t.isToken).toList()),
                            _TransactionsList(items: _transactions.where((t) => t.isToken).toList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onAddTokens});

  final VoidCallback onAddTokens;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFFF7A18).withValues(alpha: 0.22), const Color(0xFFB83280).withValues(alpha: 0.18)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Text('243.50', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _TokenBadge(tokens: 18),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onAddTokens,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Tokens', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenBadge extends StatelessWidget {
  const _TokenBadge({required this.tokens});

  final int tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A18), size: 18),
          const SizedBox(width: 6),
          Text('$tokens Flame Tokens', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap, this.accent = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent ? const Color(0xFFFF7A18).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent ? const Color(0xFFFF7A18).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent ? const Color(0xFFFF7A18) : Colors.white70, size: 22),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: accent ? const Color(0xFFFF7A18) : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TokenInfoCard extends StatelessWidget {
  const _TokenInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.09))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A18), size: 18),
              SizedBox(width: 8),
              Text('What are Flame Tokens?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Flame Tokens let you book reserved seats in workshops and events at a discounted rate. 1 token = 1 token seat.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.items});

  final List<_Transaction> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No transactions yet', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = items[i];
        final isCredit = t.type == 'credit';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: (isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(t.icon, color: isCredit ? const Color(0xFF10B981) : const Color(0xFFFF7A18), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(t.date, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Text(
                t.isToken ? '${isCredit ? '+' : '-'}${t.amount.toInt()} T' : '${isCredit ? '+' : ''}\$${t.amount.abs().toStringAsFixed(0)}',
                style: TextStyle(color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddTokensSheet extends StatelessWidget {
  const _AddTokensSheet();

  @override
  Widget build(BuildContext context) {
    const packs = [
      (tokens: 5, price: 4.99, label: 'Starter'),
      (tokens: 10, price: 8.99, label: 'Popular'),
      (tokens: 25, price: 19.99, label: 'Best Value'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buy Flame Tokens', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Use tokens to book reserved seats in workshops.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 20),
          ...packs.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: ListTile(
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFF7A18).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A18))),
              title: Text('${p.tokens} Tokens', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: Text(p.label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A18), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                child: Text('\$${p.price}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _Transaction {
  const _Transaction({required this.type, required this.title, required this.amount, required this.date, required this.icon, this.isToken = false});

  final String type, title, date;
  final double amount;
  final IconData icon;
  final bool isToken;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)]));
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
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}
