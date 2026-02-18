import 'package:bloc/bloc.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart' as kek_date;
import 'package:photo_manager/photo_manager.dart';

sealed class DayMediaPreviewState {}

class DayMediaPreviewLoading extends DayMediaPreviewState {}

class DayMediaPreviewData extends DayMediaPreviewState {
  final List<AssetEntity> assets;
  final int total;

  DayMediaPreviewData({required this.assets, required this.total});
}

class DayMediaPreviewPermissionDenied extends DayMediaPreviewState {}

final class DayMediaPreviewCubit extends Cubit<DayMediaPreviewState> {
  DayMediaPreviewCubit() : super(DayMediaPreviewLoading());

  Future<void> load(int dayIndex) async {
    emit(DayMediaPreviewLoading());

    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      emit(DayMediaPreviewPermissionDenied());
      return;
    }

    final DateTime date = kek_date.DateUtils.getDateFromDayIndex(dayIndex);
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

    final List<AssetEntity> all = assetMap.values.where((AssetEntity a) {
      final DateTime d = a.createDateTime;
      return d.isAfter(startOfDay) && d.isBefore(endOfDay);
    }).toList()
      ..sort((AssetEntity a, AssetEntity b) => b.createDateTime.compareTo(a.createDateTime));

    emit(DayMediaPreviewData(assets: all.take(5).toList(), total: all.length));
  }
}
