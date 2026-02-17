import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart' as kek_date;
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/date_gallery/bloc/date_gallery_bloc.dart';
import 'package:keklist/presentation/screens/date_gallery/date_gallery_preview_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

const int _kGalleryColumnCount = 4;

final class DateGalleryScreen extends StatefulWidget {
  final int dayIndex;

  const DateGalleryScreen({super.key, required this.dayIndex});

  @override
  State<DateGalleryScreen> createState() => _DateGalleryScreenState();
}

final class _DateGalleryScreenState extends KekWidgetState<DateGalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DateGalleryBloc()..add(DateGalleryLoad(dayIndex: widget.dayIndex)),
      child: Builder(builder: (context) => _buildScaffold(context)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final DateTime date = kek_date.DateUtils.getDateFromDayIndex(widget.dayIndex);
    final String formattedDate = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.photosFromDay(formattedDate)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<DateGalleryBloc, DateGalleryState>(
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DateGalleryState state) {
    if (state is DateGalleryLoadingState) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DateGalleryPermissionDeniedState) {
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

    if (state is DateGalleryDataState) {
      if (state.assets.isEmpty) {
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
          crossAxisCount: _kGalleryColumnCount,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: state.assets.length,
        itemBuilder: (context, index) => _buildThumbnail(context, state.assets[index]),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildThumbnail(BuildContext context, AssetEntity asset) {
    return GestureDetector(
      onTap: () => _openPreview(context, asset),
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
                  color: Colors.black.withValues(alpha: 0.7),
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

  void _openPreview(BuildContext context, AssetEntity asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DateGalleryPreviewScreen(asset: asset),
      ),
    );
  }
}
