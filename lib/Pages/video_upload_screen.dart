import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart';
import '../services/reel_service.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'AI';
  XFile? _videoFile;
  bool _uploading = false;

  final List<String> _categories = ['AI', 'Design', 'Business', 'Finance', 'Tech', 'Science', 'Education', 'Health'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _videoFile = file);
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a caption'), backgroundColor: Color(0xFF374151)),
      );
      return;
    }
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video'), backgroundColor: Color(0xFF374151)),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      await ReelService.upload(
        videoPath: _videoFile!.path,
        caption: _titleController.text.trim(),
        category: _selectedCategory,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video submitted for review!'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e, fallback: 'Upload failed.')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.18), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Text('Upload Reel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickVideo,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 180,
                            decoration: BoxDecoration(
                              color: _videoFile != null ? const Color(0xFFFF7A18).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _videoFile != null ? const Color(0xFFFF7A18) : Colors.white.withValues(alpha: 0.15),
                                width: _videoFile != null ? 1.5 : 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _videoFile != null ? Icons.check_circle_rounded : Icons.video_call_rounded,
                                    color: _videoFile != null ? const Color(0xFFFF7A18) : Colors.white38,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _videoFile != null ? 'Video selected ✓' : 'Tap to select video',
                                    style: TextStyle(color: _videoFile != null ? const Color(0xFFFF7A18) : Colors.white54, fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  if (_videoFile == null) ...[
                                    const SizedBox(height: 6),
                                    const Text('MP4, MOV — Max 60 seconds', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Label('Caption *'),
                        _Field(controller: _titleController, hint: 'What will people learn from this video?'),
                        const SizedBox(height: 16),
                        _Label('Category'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _categories.map((cat) {
                            final sel = cat == _selectedCategory;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? const Color(0xFFFF7A18).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: sel ? const Color(0xFFFF7A18) : Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Text(cat, style: TextStyle(color: sel ? Colors.white : const Color(0xFFB2B8CB), fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Your video will be reviewed by our moderation team before going live.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.4))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _uploading ? null : _publish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7A18),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              disabledBackgroundColor: const Color(0xFFFF7A18).withValues(alpha: 0.4),
                            ),
                            child: _uploading
                                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    SizedBox(width: 12),
                                    Text('Uploading…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  ])
                                : const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
