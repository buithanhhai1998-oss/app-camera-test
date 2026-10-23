import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../overlay/presentation/overlay_controller.dart';

/// Interactive onboarding flow shown on first application launch.
class OnboardingScreen extends StatefulWidget {
  final OverlayController overlayController;
  final VoidCallback onFinish;

  const OnboardingScreen({
    super.key,
    required this.overlayController,
    required this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedImagePath;
  bool _autoRecord = true;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedImagePath = picked.path);
        await widget.overlayController.setDecoyImage(picked.path);
      }
    } catch (_) {}
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch_done', true);
    await widget.overlayController.setAutoRecordOnLaunch(_autoRecord);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Center(
                child: Icon(Icons.security, size: 48, color: Colors.blueAccent),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Hướng dẫn Thao tác Bí mật',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Màn hình sẽ hiển thị 100% ảnh ngụy trang để bảo vệ riêng tư.\nHãy ghi nhớ các cử chỉ sau để điều khiển:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Gestures guide cards
              Expanded(
                child: ListView(
                  children: [
                    _buildGestureTile(
                      color: Colors.redAccent,
                      icon: Icons.stop_circle_outlined,
                      title: 'Góc Trên - Phải (Top-Right)',
                      subtitle: 'Nhấp đúp 2 lần để DỪNG & LƯU video.\n(Điện thoại sẽ rung 2 nhịp để báo hiệu)',
                    ),
                    const SizedBox(height: 12),
                    _buildGestureTile(
                      color: Colors.amberAccent,
                      icon: Icons.lock_open,
                      title: 'Góc Trên - Trái (Top-Left)',
                      subtitle: 'Nhấn giữ 2 giây để MỞ KHÓA Thư viện & Cài đặt.\n(Yêu cầu Face ID / Mật mã)',
                    ),
                    const SizedBox(height: 12),
                    _buildGestureTile(
                      color: Colors.cyanAccent,
                      icon: Icons.flip_camera_ios,
                      title: 'Góc Dưới - Phải (Bottom-Right)',
                      subtitle: 'Nhấp đúp 2 lần để ĐỔI camera Trước / Sau.',
                    ),
                    const SizedBox(height: 12),
                    _buildGestureTile(
                      color: Colors.tealAccent,
                      icon: Icons.opacity,
                      title: 'Góc Dưới - Trái (Bottom-Left)',
                      subtitle: 'Chạm để đổi độ mờ ảnh che (100% ⟷ Nhìn xuyên 35%) để kiểm tra góc quay của camera.',
                    ),
                    const SizedBox(height: 12),
                    _buildGestureTile(
                      color: Colors.greenAccent,
                      icon: Icons.touch_app,
                      title: 'Chạm 3 ngón tay cùng lúc',
                      subtitle: 'Bật / Tắt viền hướng dẫn kèm nút tăng giảm độ mờ [+]/[-] trực tiếp.',
                    ),
                    const SizedBox(height: 16),

                    // Decoy image selector
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn ảnh ngụy trang:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white12,
                                  image: _selectedImagePath != null
                                      ? DecorationImage(
                                          image: FileImage(File(_selectedImagePath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _selectedImagePath == null
                                    ? const Icon(Icons.wallpaper, color: Colors.white54)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedImagePath != null
                                      ? 'Đã chọn ảnh tùy chỉnh'
                                      : 'Dùng màn hình khóa mặc định',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.photo, size: 16),
                                label: const Text('Chọn ảnh'),
                                onPressed: _pickImage,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mở app là quay luôn', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Tự động ghi hình ngầm ở các lần mở app sau', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      value: _autoRecord,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (v) => setState(() => _autoRecord = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _completeOnboarding,
                  child: const Text(
                    'ĐÃ HIỂU & BẮT ĐẦU',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureTile({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
