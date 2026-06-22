part of 'date_gallery_bloc.dart';

sealed class DateGalleryState extends Equatable {
  const DateGalleryState();

  @override
  List<Object?> get props => const [];
}

final class DateGalleryLoadingState extends DateGalleryState {
  const DateGalleryLoadingState();
}

final class DateGalleryPermissionDeniedState extends DateGalleryState {
  const DateGalleryPermissionDeniedState();
}

final class DateGalleryDataState extends DateGalleryState {
  final List<AssetEntity> assets;

  const DateGalleryDataState({required this.assets});

  @override
  List<Object?> get props => [assets];
}
