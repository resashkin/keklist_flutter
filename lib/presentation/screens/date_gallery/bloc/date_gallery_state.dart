part of 'date_gallery_bloc.dart';

sealed class DateGalleryState {}

final class DateGalleryLoadingState extends DateGalleryState {}

final class DateGalleryPermissionDeniedState extends DateGalleryState {}

final class DateGalleryDataState extends DateGalleryState {
  final List<AssetEntity> assets;

  DateGalleryDataState({required this.assets});
}
