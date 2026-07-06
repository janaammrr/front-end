import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// Shared edit form for a workshop or event, matching the web app's unified
/// `/edit-listing/:itemType/:itemId` flow. [onSave] performs the actual
/// service call and should rethrow on failure.
class EditListingDialog extends StatefulWidget {
  const EditListingDialog({
    super.key,
    required this.dialogTitle,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialLocation,
    required this.initialDate,
    required this.initialPrice,
    required this.onSave,
    this.showCapacity = false,
    this.initialCapacity,
  });

  final String dialogTitle;
  final String initialTitle;
  final String initialDescription;
  final String initialLocation;
  final String initialDate;
  final double initialPrice;
  final bool showCapacity;
  final int? initialCapacity;

  /// Called with the edited fields. Throw to surface an error in the dialog.
  final Future<void> Function({
    required String title,
    required String description,
    required String location,
    required String date,
    required double price,
    int? capacity,
  }) onSave;

  @override
  State<EditListingDialog> createState() => _EditListingDialogState();
}

class _EditListingDialogState extends State<EditListingDialog> {
  late final _titleController = TextEditingController(text: widget.initialTitle);
  late final _descController = TextEditingController(text: widget.initialDescription);
  late final _locationController = TextEditingController(text: widget.initialLocation);
  late final _dateController = TextEditingController(text: widget.initialDate);
  late final _priceController = TextEditingController(
    text: widget.initialPrice > 0 ? widget.initialPrice.toString() : '',
  );
  late final _capacityController = TextEditingController(
    text: widget.initialCapacity != null && widget.initialCapacity! > 0
        ? widget.initialCapacity.toString()
        : '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        title: title,
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        date: _dateController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        capacity: int.tryParse(_capacityController.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e, fallback: 'Failed to save changes.')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
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
              width: media.width * 0.9,
              constraints: BoxConstraints(maxHeight: media.height * 0.75),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.dialogTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
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
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field('Title *', _titleController),
                          const SizedBox(height: 14),
                          _field('Description', _descController, maxLines: 3),
                          const SizedBox(height: 14),
                          _field('Location', _locationController),
                          const SizedBox(height: 14),
                          _field('Date (YYYY-MM-DD)', _dateController),
                          const SizedBox(height: 14),
                          _field('Price', _priceController, keyboardType: TextInputType.number),
                          if (widget.showCapacity) ...[
                            const SizedBox(height: 14),
                            _field('Capacity', _capacityController, keyboardType: TextInputType.number),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
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

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
