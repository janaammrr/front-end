import 'package:flutter/material.dart';
import '../auth/auth.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  List<String> _available = [];
  final Set<String> _selected = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _maxSelect = 5;
  static const _fallbackPreferences = [
    'Design',
    'Finance',
    'Technology & Computing',
    'AI',
    'UI/UX Design',
    'Health',
    'Business',
    'Science',
    'Education',
    'Entrepreneurship',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/categories');
      final list = (res.data as List<dynamic>).cast<String>();
      if (mounted) {
        setState(() {
          _available = list.isEmpty ? _fallbackPreferences : list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _available = _fallbackPreferences;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.instance.put(
        '/api/users/categories',
        data: {'categories': _selected.join(',')},
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
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
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.errorMessage(
                e,
                fallback: 'Failed to save preferences.',
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  void _toggle(String pref) {
    setState(() {
      if (_selected.contains(pref)) {
        _selected.remove(pref);
      } else if (_selected.length < _maxSelect) {
        _selected.add(pref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _GlowOrb(
              color: AppColors.amber.withValues(alpha: 0.14),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _GlowOrb(
              color: AppColors.amberSoft.withValues(alpha: 0.12),
              size: 250,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/FLAME_LOGO.png',
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.amber, AppColors.amberSoft],
                        ).createShader(r),
                        child: const Text(
                          'What do you want to learn?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pick up to $_maxSelect topics to personalise your feed.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selected.isNotEmpty)
                        Text(
                          '${_selected.length}/$_maxSelect selected',
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.amber,
                          ),
                        )
                      : _error != null
                      ? Center(
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
                                onPressed: _loadPreferences,
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
                        )
                      : _available.isEmpty
                      ? const Center(
                          child: Text(
                            'No preferences available',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _available.map((pref) {
                              final selected = _selected.contains(pref);
                              final disabled =
                                  !selected && _selected.length >= _maxSelect;
                              return GestureDetector(
                                onTap: disabled ? null : () => _toggle(pref),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.amber
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.amber
                                          : Colors.white.withValues(
                                              alpha: disabled ? 0.08 : 0.35,
                                            ),
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.amber.withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (selected) ...[
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 7),
                                      ],
                                      Text(
                                        _capitalize(pref),
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : AppColors.amber.withValues(
                                                  alpha: disabled ? 0.35 : 1,
                                                ),
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _selected.isEmpty
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      AppColors.amber,
                                      AppColors.amberSoft,
                                    ],
                                  ),
                            color: _selected.isEmpty
                                ? Colors.white.withValues(alpha: 0.07)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _selected.isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.amber.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: (_saving || _selected.isEmpty)
                                ? null
                                : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _selected.isEmpty
                                        ? 'Select at least 1 topic'
                                        : 'Get Started',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: _selected.isEmpty ? 0.4 : 1.0,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _saving ? null : _skip,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
