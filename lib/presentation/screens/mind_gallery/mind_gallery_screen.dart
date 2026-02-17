import 'package:flutter/material.dart' hide DateUtils;
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/screens/date_gallery/date_gallery_preview_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:intl/intl.dart';

final class MindGalleryScreen extends StatefulWidget {
  final int dayIndex;

  const MindGalleryScreen({super.key, required this.dayIndex});

  @override
  State<MindGalleryScreen> createState() => _MindGalleryScreenState();
}

final class _MindGalleryScreenState extends State<MindGalleryScreen> {
  List<AssetEntity>? _assets;
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    // Request permission
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      return;
    }

    // Convert dayIndex to date range
    final DateTime date = DateUtils.getDateFromDayIndex(widget.dayIndex);
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all asset paths (albums)
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common, // Photos and videos
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        createTimeCond: DateTimeCond(
          min: startOfDay,
          max: endOfDay,
        ),
      ),
    );

    // Collect all assets from all albums, deduplicated by id
    // (same asset can appear in multiple albums like Camera Roll + Recents + Favorites)
    final Map<String, AssetEntity> assetMap = {};
    for (final AssetPathEntity path in paths) {
      final List<AssetEntity> assets = await path.getAssetListRange(
        start: 0,
        end: await path.assetCountAsync,
      );
      for (final asset in assets) {
        assetMap[asset.id] = asset;
      }
    }
    final List<AssetEntity> allAssets = assetMap.values.toList();

    // Filter assets by the exact date (in case the filterOption didn't work perfectly)
    final List<AssetEntity> filteredAssets = allAssets.where((asset) {
      final DateTime? createDate = asset.createDateTime;
      if (createDate == null) return false;
      return createDate.isAfter(startOfDay) && createDate.isBefore(endOfDay);
    }).toList();

    // Sort by creation time (newest first)
    filteredAssets.sort((a, b) {
      final DateTime? aDate = a.createDateTime;
      final DateTime? bDate = b.createDateTime;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    setState(() {
      _assets = filteredAssets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = DateUtils.getDateFromDayIndex(widget.dayIndex);
    final String formattedDate = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.photosFromDay(formattedDate)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                context.l10n.noPhotosForDay,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Permission denied. Please enable photo access in settings.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => PhotoManager.openSetting(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    final List<AssetEntity>? assets = _assets;
    if (assets == null || assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                context.l10n.noPhotosForDay,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final AssetEntity asset = assets[index];
        return _buildThumbnail(asset);
      },
    );
  }

  Widget _buildThumbnail(AssetEntity asset) {
    return GestureDetector(
      onTap: () => _openPreview(asset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(200),
            fit: BoxFit.cover,
          ),
          if (asset.type == AssetType.video)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _openPreview(AssetEntity asset) {
    Navigator.of(context).push(
      BackSwipePageRoute(
        builder: (_) => DateGalleryPreviewScreen(asset: asset),
      ),
    );
  }
}
