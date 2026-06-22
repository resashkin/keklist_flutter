part of 'date_gallery_bloc.dart';

sealed class DateGalleryEvent extends Equatable {
  const DateGalleryEvent();

  @override
  List<Object?> get props => const [];
}

final class DateGalleryLoad extends DateGalleryEvent {
  final int dayIndex;

  const DateGalleryLoad({required this.dayIndex});

  @override
  List<Object?> get props => [dayIndex];
}
