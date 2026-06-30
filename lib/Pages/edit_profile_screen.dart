import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: '');
  final _bioController = TextEditingController(text: '');
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _localPhotoPath;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null) return;

    setState(() { _localPhotoPath = xfile.path; _uploadingPhoto = true; });
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(xfile.path, filename: xfile.name),
      });
      await ApiClient.instance.post('/api/users/me/profile-image', data: formData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Profile photo updated!'),
            ]),
            backgroundColor: const Color(0xFFFF7A18),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _localPhotoPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.18), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.16), size: 240)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A18)))
                          : TextButton(
                              onPressed: _save,
                              child: const Text('Done', style: TextStyle(color: Color(0xFFFF7A18), fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFF7A18), width: 3),
                                ),
                                child: ClipOval(
                                  child: _localPhotoPath != null
                                      ? Image.file(File(_localPhotoPath!), fit: BoxFit.cover)
                                      : Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(colors: [Color(0xFFFF7A18), Color(0xFFB83280)]),
                                          ),
                                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 48),
                                        ),
                                ),
                              ),
                              if (_uploadingPhoto)
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Container(
                                      color: Colors.black54,
                                      child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A18)))),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: GestureDetector(
                                  onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                                  child: Container(
                                    width: 30, height: 30,
                                    decoration: const BoxDecoration(color: Color(0xFFFF7A18), shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          child: const Center(child: Text('Change photo', style: TextStyle(color: Color(0xFFFF7A18), fontSize: 13, fontWeight: FontWeight.w600))),
                        ),
                        const SizedBox(height: 28),
                        _FieldLabel('Full Name'),
                        _StyledField(controller: _nameController, hint: 'Your full name'),
                        const SizedBox(height: 16),
                        _FieldLabel('Bio'),
                        _StyledField(controller: _bioController, hint: 'Tell people about yourself…', maxLines: 3),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'To update your preferences, visit Profile → Settings → Preferences.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7A18),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              disabledBackgroundColor: const Color(0xFFFF7A18).withValues(alpha: 0.4),
                            ),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                        ),
                      ],
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({required this.controller, required this.hint, this.maxLines = 1});

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF7A18), width: 1.2)),
      ),
    );
  }
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
