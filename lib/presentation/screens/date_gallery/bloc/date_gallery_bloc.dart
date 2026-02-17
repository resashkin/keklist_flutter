import 'package:bloc/bloc.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart' as kek_date;
import 'package:photo_manager/photo_manager.dart';

part 'date_gallery_event.dart';
part 'date_gallery_state.dart';

final class DateGalleryBloc extends Bloc<DateGalleryEvent, DateGalleryState> {
  DateGalleryBloc() : super(DateGalleryLoadingState()) {
    on<DateGalleryLoad>(_onLoad);
  }

  Future<void> _onLoad(DateGalleryLoad event, Emitter<DateGalleryState> emit) async {
    emit(DateGalleryLoadingState());

    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      emit(DateGalleryPermissionDeniedState());
      return;
    }

    final DateTime date = kek_date.DateUtils.getDateFromDayIndex(event.dayIndex);
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
        videoOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      ),
    );

    final Map<String, AssetEntity> assetMap = {};
    for (final AssetPathEntity path in paths) {
      final List<AssetEntity> assets = await path.getAssetListRange(
        start: 0,
        end: await path.assetCountAsync,
      );
      for (final AssetEntity asset in assets) {
        assetMap[asset.id] = asset;
      }
    }

    final List<AssetEntity> filtered = assetMap.values.where((AssetEntity a) {
      final DateTime d = a.createDateTime;
      return d.isAfter(startOfDay) && d.isBefore(endOfDay);
    }).toList()
      ..sort((AssetEntity a, AssetEntity b) => b.createDateTime.compareTo(a.createDateTime));

    emit(DateGalleryDataState(assets: filtered));
  }
}
