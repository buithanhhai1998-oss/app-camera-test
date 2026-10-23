import 'package:flutter/material.dart';
import '../data/recordings_database.dart';
import '../domain/media_item.dart';
import '../../recording/services/recording_storage_service.dart';
import 'video_player_screen.dart';

/// Secure Media Library Screen displaying all locally recorded videos.
class MediaLibraryScreen extends StatefulWidget {
  final RecordingsDatabase database;
  final RecordingStorageService storageService;
  final VoidCallback? onOpenSettings;

  const MediaLibraryScreen({
    super.key,
    required this.database,
    required this.storageService,
    this.onOpenSettings,
  });

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  List<MediaItem> _recordings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'newest';
  int _totalStorageBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    final items = await widget.database.getAllRecordings(
      searchQuery: _searchQuery,
      sortBy: _sortBy,
    );
    final totalBytes = await widget.storageService.calculateTotalRecordingsBytes();

    if (mounted) {
      setState(() {
        _recordings = items;
        _totalStorageBytes = totalBytes;
        _isLoading = false;
      });
    }
  }

  String _formatTotalStorage(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteRecording(MediaItem item) async {
    if (item.id != null) {
      await widget.database.deleteRecording(item.id!);
    }
    await widget.storageService.deleteRecordingFile(item.filepath);
    await _loadRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Thư viện Video', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            initialValue: _sortBy,
            onSelected: (val) {
              setState(() => _sortBy = val);
              _loadRecordings();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'newest', child: Text('Mới nhất trước')),
              PopupMenuItem(value: 'oldest', child: Text('Cũ nhất trước')),
              PopupMenuItem(value: 'duration', child: Text('Thời lượng dài nhất')),
              PopupMenuItem(value: 'size', child: Text('Dung lượng lớn nhất')),
            ],
          ),
          if (widget.onOpenSettings != null)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Cài đặt',
              onPressed: widget.onOpenSettings,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Storage Summary Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val;
                _loadRecordings();
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên tệp...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_recordings.length} video',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'Tổng: ${_formatTotalStorage(_totalStorageBytes)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Main Grid / Empty view
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _recordings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecordings,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _recordings.length,
                          itemBuilder: (context, index) {
                            final item = _recordings[index];
                            return _buildVideoCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 72, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Chưa có video nào',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Các video quay bằng thao tác bí mật sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(MediaItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              item: item,
              onDelete: () => _deleteRecording(item),
            ),
          ),
        ).then((_) => _loadRecordings());
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview thumbnail / placeholder
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFF2C2C2E),
                    child: const Center(
                      child: Icon(Icons.play_circle_outline, size: 42, color: Colors.white54),
                    ),
                  ),
                  // Duration badge in bottom-right corner
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info text
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.formattedDate,
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      Text(
                        item.formattedSize,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
