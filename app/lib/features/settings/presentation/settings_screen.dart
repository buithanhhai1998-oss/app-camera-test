import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../overlay/domain/overlay_state.dart';
import '../../overlay/presentation/overlay_controller.dart';
import '../../media_library/data/recordings_database.dart';
import '../../recording/services/recording_storage_service.dart';

/// Screen managing disguise wallpaper, biometrics, auto-record limits, and storage cleanup.
class SettingsScreen extends StatefulWidget {
  final OverlayController overlayController;
  final CameraOverlayState overlayState;
  final RecordingsDatabase database;
  final RecordingStorageService storageService;
  final VoidCallback? onClearedAll;

  const SettingsScreen({
    super.key,
    required this.overlayController,
    required this.overlayState,
    required this.database,
    required this.storageService,
    this.onClearedAll,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useBiometrics = true;
  String _preferredLens = 'back'; // 'back' | 'front'
  int _maxDurationMinutes = 0; // 0 = unlimited

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _useBiometrics = prefs.getBool('settings_use_biometrics') ?? true;
        _preferredLens = prefs.getString('settings_preferred_lens') ?? 'back';
        _maxDurationMinutes = prefs.getInt('settings_max_duration_minutes') ?? 0;
      });
    }
  }

  Future<void> _pickNewDecoyImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        await widget.overlayController.setDecoyImage(picked.path);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _resetToDefaultWallpaper() async {
    await widget.overlayController.setDecoyImage('');
    if (mounted) setState(() {});
  }

  Future<void> _updateBiometrics(bool val) async {
    setState(() => _useBiometrics = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_use_biometrics', val);
  }

  Future<void> _updatePreferredLens(String val) async {
    setState(() => _preferredLens = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_preferred_lens', val);
  }

  Future<void> _updateMaxDuration(int minutes) async {
    setState(() => _maxDurationMinutes = minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_max_duration_minutes', minutes);
  }

  Future<void> _confirmClearAllData() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Xóa toàn bộ video?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tất cả bản ghi trong thư viện sẽ bị xóa vĩnh viễn khỏi thiết bị.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.database.clearAll();
              final dir = await widget.storageService.getRecordingsDirectory();
              if (await dir.exists()) {
                await for (final f in dir.list()) {
                  if (f is File) {
                    try {
                      await f.delete();
                    } catch (_) {}
                  }
                }
              }
              widget.onClearedAll?.call();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa sạch toàn bộ video')),
                );
              }
            },
            child: const Text('Xóa hết', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.overlayState.imagePath;
    final hasCustomImage = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cài đặt Ứng dụng', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section: Giao diện ngụy trang
          _buildSectionHeader('GIAO DIỆN NGỤY TRANG (DECOY OVERLAY)'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white12,
                        image: hasCustomImage
                            ? DecorationImage(
                                image: FileImage(File(imagePath)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !hasCustomImage
                          ? const Icon(Icons.wallpaper, color: Colors.white54)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasCustomImage ? 'Ảnh ngụy trang tùy chọn' : 'Hình nền ngụy trang mặc định',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasCustomImage ? 'Đã cài từ Thư viện' : 'Giao diện đồng hồ màn hình khóa',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Đổi ảnh ngụy trang'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                        onPressed: _pickNewDecoyImage,
                      ),
                    ),
                    if (hasCustomImage) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Đặt lại mặc định',
                        icon: const Icon(Icons.refresh, color: Colors.white54),
                        onPressed: _resetToDefaultWallpaper,
                      ),
                    ],
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                // Opacity slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Độ phủ ngụy trang:', style: TextStyle(color: Colors.white)),
                    Text(
                      '${(widget.overlayState.opacity * 100).toInt()}%',
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: widget.overlayState.opacity,
                  min: 0.1,
                  max: 1.0,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) {
                    widget.overlayController.setOpacity(val);
                    setState(() {});
                  },
                ),
                const Text(
                  '100% che kín hoàn toàn camera preview bên dưới.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section: Hành vi tự động & An toàn
          _buildSectionHeader('HÀNH VI TỰ ĐỘNG & BẢO MẬT'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mở app là quay luôn', style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'Tự động ghi hình ngầm ngay khi khởi động ứng dụng',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: widget.overlayState.isAutoRecordOnLaunch,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (val) {
                    widget.overlayController.setAutoRecordOnLaunch(val);
                    setState(() {});
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: const Text('Bảo vệ bằng Face ID / Passcode', style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'Bắt buộc xác thực khi nhấn giữ góc trên-trái để mở thư viện',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _useBiometrics,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: _updateBiometrics,
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  title: const Text('Camera mặc định khi mở app', style: TextStyle(color: Colors.white)),
                  trailing: DropdownButton<String>(
                    value: _preferredLens,
                    dropdownColor: const Color(0xFF2C2C2E),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'back', child: Text('Camera sau (Back)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'front', child: Text('Camera trước (Front)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) _updatePreferredLens(val);
                    },
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  title: const Text('Giới hạn thời lượng an toàn', style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'Tự ngắt quay sau thời gian đã định',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: DropdownButton<int>(
                    value: _maxDurationMinutes,
                    dropdownColor: const Color(0xFF2C2C2E),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Vô hạn', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 5, child: Text('5 phút', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 10, child: Text('10 phút', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 20, child: Text('20 phút', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 30, child: Text('30 phút', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) _updateMaxDuration(val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section: Bộ nhớ & Dữ liệu
          _buildSectionHeader('DỮ LIỆU & BỘ NHỚ'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Xóa sạch tất cả video', style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text(
                'Giải phóng bộ nhớ và xóa toàn bộ dữ liệu ghi hình',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: _confirmClearAllData,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
