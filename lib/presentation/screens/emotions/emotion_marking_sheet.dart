import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/widgets/kek_bottom_sheet.dart';
import 'package:keklist/presentation/screens/emotions/emotions_screen.dart';
import 'package:keklist/presentation/screens/emotions/widgets/emotion_chip.dart';

/// Bottom sheet for tagging a mind with emotions. Emotions form a tree; the sheet
/// shows one level at a time. Tap a chip to toggle the tag, long-press to drill
/// into its children. Opens at 33% of the screen and can be dragged up to ~95%
/// via the handle; dragging below the minimum dismisses it. Calls
/// [onSelectionChanged] on every toggle so the caller can persist immediately.
final class EmotionMarkingSheet extends StatefulWidget {
  final Set<String> initialSelectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  const EmotionMarkingSheet({
    super.key,
    required this.initialSelectedIds,
    required this.onSelectionChanged,
  });

  static const double _initialSize = 0.5;
  static const double _minSize = 0.25;
  static const double _maxSize = 0.95;

  static Future<void> show({
    required BuildContext context,
    required Set<String> initialSelectedIds,
    required ValueChanged<Set<String>> onSelectionChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmotionMarkingSheet(
        initialSelectedIds: initialSelectedIds,
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }

  @override
  State<EmotionMarkingSheet> createState() => _EmotionMarkingSheetState();
}

class _EmotionMarkingSheetState extends State<EmotionMarkingSheet> {
  late final Set<String> _selected = {...widget.initialSelectedIds};
  final DraggableScrollableController _dragController = DraggableScrollableController();

  /// Navigation path of parent ids; `null` is the root level.
  final List<String?> _path = [null];
  bool _dismissing = false;

  String? get _currentParentId => _path.last;

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _toggle(Emotion emotion) {
    final bool added = _selected.add(emotion.id);
    if (!added) _selected.remove(emotion.id);
    // Distinct feel: adding is a crisp light tap, removing a softer one.
    Haptics.vibrate(added ? HapticsType.light : HapticsType.soft);
    setState(() {});
    widget.onSelectionChanged({..._selected});
  }

  void _drillInto(Emotion emotion) {
    Haptics.vibrate(HapticsType.medium);
    setState(() => _path.add(emotion.id));
  }

  void _goBack() {
    Haptics.vibrate(HapticsType.light);
    setState(() => _path.removeLast());
  }

  void _openSetup() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmotionsScreen()),
      );

  // --- Draggable handle → drives the sheet size ------------------------------

  void _onHandleDrag(DragUpdateDetails details) {
    if (!_dragController.isAttached) return;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double next = (_dragController.size - details.primaryDelta! / screenHeight)
        .clamp(EmotionMarkingSheet._minSize, EmotionMarkingSheet._maxSize);
    _dragController.jumpTo(next);
  }

  void _onHandleDragEnd(DragEndDetails details) {
    if (!_dragController.isAttached) return;
    final double size = _dragController.size;
    if (size < 0.3) {
      _dismiss();
    } else {
      final double target = size < 0.72 ? EmotionMarkingSheet._initialSize : EmotionMarkingSheet._maxSize;
      _dragController.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  /// Pop only this sheet's route, exactly once. Both the drag-handle and the
  /// scroll-extent listener can request dismissal, so guard against a double pop
  /// that would also close the screen underneath.
  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _dragController,
      expand: false,
      snap: true,
      initialChildSize: EmotionMarkingSheet._initialSize,
      minChildSize: EmotionMarkingSheet._minSize,
      maxChildSize: EmotionMarkingSheet._maxSize,
      snapSizes: const [EmotionMarkingSheet._initialSize, EmotionMarkingSheet._maxSize],
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            if (n.extent <= n.minExtent + 0.001) _dismiss();
            return false;
          },
          child: Container(
            decoration: KekBottomSheetStyle.decoration(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHandle(context),
                Expanded(
                  child: BlocBuilder<EmotionBloc, EmotionState>(
                    builder: (context, state) {
                      if (state is! EmotionsList) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final children = state.childrenOf(_currentParentId);
                      final parent = _currentParentId == null ? null : state.byId(_currentParentId!);

                      return Column(
                        children: [
                          _buildHeader(context, state, parent),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16.0),
                              child: children.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                                      child: Center(child: Text(context.l10n.noEmotionsYet)),
                                    )
                                  : Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (final emotion in children)
                                          EmotionChip(
                                            emojis: [emotion.emoji],
                                            label: emotion.title,
                                            selected: _selected.contains(emotion.id),
                                            hasChildren: state.hasActiveChildren(emotion.id),
                                            selectedDescendantCount:
                                                state.descendantIdsOf(emotion.id).where(_selected.contains).length,
                                            onTap: () => _toggle(emotion),
                                            onLongPress: state.hasActiveChildren(emotion.id)
                                                ? () => _drillInto(emotion)
                                                : null,
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildHint(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onHandleDrag,
      onVerticalDragEnd: _onHandleDragEnd,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: KekBottomSheetStyle.handleBar(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EmotionsList state, Emotion? parent) {
    final String title =
        parent == null ? context.l10n.emotions : '${state.lineageEmojis(parent).join(' ')}  ${parent.title}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: parent == null
                ? null
                : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KekBottomSheetStyle.titleStyle(context),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.tune),
              tooltip: context.l10n.setupEmotions,
              onPressed: _openSetup,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0 + MediaQuery.paddingOf(context).bottom),
      child: Text(
        context.l10n.emotionPickHint,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}
