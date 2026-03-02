part of 'date_gallery_bloc.dart';

sealed class DateGalleryEvent {}

final class DateGalleryLoad extends DateGalleryEvent {
  final int dayIndex;

  DateGalleryLoad({required this.dayIndex});
}
