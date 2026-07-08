import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Suspend/Unsuspend + Delete action row shared by every admin list screen
/// (Users, Posts, Providers, Events, Workshops), matching the web app's
/// consistent `.../{id}/suspension` + `DELETE .../{id}` admin API shape.
class AdminSuspendActions extends StatelessWidget {
  const AdminSuspendActions({
    super.key,
    required this.suspended,
    required this.onToggleSuspend,
    required this.onDelete,
  });

  final bool suspended;
  final Future<void> Function(bool suspend, String reason) onToggleSuspend;
  final Future<void> Function() onDelete;

  Future<void> _handleSuspendTap(BuildContext context) async {
    if (suspended) {
      await onToggleSuspend(false, '');
      return;
    }
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Suspend?', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (confirmed == true)
      await onToggleSuspend(true, reasonController.text.trim());
  }

  Future<void> _handleDeleteTap(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete permanently?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _handleSuspendTap(context),
          icon: Icon(
            suspended ? Icons.play_circle_outline : Icons.pause_circle_outline,
            size: 16,
          ),
          label: Text(suspended ? 'Unsuspend' : 'Suspend'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.amber,
            side: BorderSide(color: AppColors.amber),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _handleDeleteTap(context),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      ],
    );
  }
}
