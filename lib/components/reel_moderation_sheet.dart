import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/reel_service.dart';
import '../theme/app_theme.dart';

const _reportReasons = ['Spam', 'Inappropriate', 'Harassment', 'Other'];

/// Opens the delete/report action sheet for a reel. Shows "Delete" when
/// [isMine] is true (the viewer posted it), otherwise "Report".
Future<void> showReelActionsSheet(
  BuildContext context, {
  required int reelId,
  required bool isMine,
  VoidCallback? onDeleted,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.surface2,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Delete video',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          'Delete video?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'This cannot be undone.',
                          style: TextStyle(color: AppColors.text2),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      await ReelService.deleteReel(reelId);
                      onDeleted?.call();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ApiClient.errorMessage(
                              e,
                              fallback: 'Could not delete video.',
                            ),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: AppColors.amber,
                  ),
                  title: const Text(
                    'Report video',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (!context.mounted) return;
                    await showReportReasonPicker(context, reelId);
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showReportReasonPicker(BuildContext context, int reelId) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.surface2,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Why are you reporting this?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              for (final reason in _reportReasons)
                ListTile(
                  title: Text(
                    reason,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(reason),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  try {
    await ReelService.reportReel(reelId, reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report sent. Thanks for helping keep Flame safe.'),
        backgroundColor: AppColors.amber,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ApiClient.errorMessage(e, fallback: 'Could not report video.'),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
