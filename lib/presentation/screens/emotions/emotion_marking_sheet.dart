import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/widgets/kek_bottom_sheet.dart';
import 'package:keklist/presentation/screens/emotions/emotion_archived_screen.dart';
import 'package:keklist/presentation/screens/emotions/emotion_editor_sheet.dart';
import 'package:keklist/presentation/screens/emotions/widgets/emotion_chip.dart';

/// Bottom sheet for tagging a mind with emotions, and — via its edit mode — the
/// only place to manage the emotion tree. Shows one tree level at a time: tap a
/// chip to toggle the tag, long-press to drill into children.
///
/// Edit mode (toggled from the footer hint) makes the chips jiggle, shows a
/// corner cross to delete/archive, and lets you rename (tap) or add emotions.
/// Opens at 50% of the screen and drags up to ~95%; dragging below the minimum
/// dismisses it.
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
  bool _editMode = false;

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

  void _toggleEditMode() {
    Haptics.vibrate(HapticsType.light);
    setState(() => _editMode = !_editMode);
  }

  void _openArchived() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmotionArchivedScreen()));

  void _openEditor({Emotion? emotion}) =>
      EmotionEditorSheet.show(context: context, initial: emotion, parentId: _currentParentId);

  Future<void> _onCross(Emotion emotion, EmotionsList state) async {
    Haptics.vibrate(HapticsType.soft);
    final referenced = context.read<MindRepository>().values.expand((mind) => mind.emotionIds).toSet();
    final subtree = {emotion.id, ...state.descendantIdsOf(emotion.id)};
    final bool isUsed = subtree.any(referenced.contains);

    if (!isUsed) {
      context.read<EmotionBloc>().add(EmotionDelete(id: emotion.id));
      return;
    }

    final action = await showModalActionSheet<String>(
      context: context,
      title: emotion.title,
      message: context.l10n.emotionInUseMessage,
      actions: [
        SheetAction(key: 'archive', label: context.l10n.archive),
        SheetAction(key: 'delete', label: context.l10n.delete, isDestructiveAction: true),
      ],
    );
    if (!mounted) return;
    if (action == 'archive') {
      context.read<EmotionBloc>().add(EmotionArchive(id: emotion.id));
    } else if (action == 'delete') {
      context.read<EmotionBloc>().add(EmotionDelete(id: emotion.id));
    }
  }

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (children.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                                      child: Center(child: Text(context.l10n.noEmotionsYet)),
                                    )
                                  else
                                    Wrap(
                                      spacing: 10.0,
                                      runSpacing: 10.0,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (int i = 0; i < children.length; i++)
                                          _buildChip(context, state, children[i], i),
                                      ],
                                    ),
                                  const SizedBox(height: 12.0),
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton.icon(
                                      onPressed: () => _openEditor(),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text(context.l10n.addEmotion),
                                    ),
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

  Widget _buildChip(BuildContext context, EmotionsList state, Emotion emotion, int index) {
    final bool hasChildren = state.hasActiveChildren(emotion.id);
    final chip = EmotionChip(
      emojis: [emotion.emoji],
      label: emotion.title,
      selected: !_editMode && _selected.contains(emotion.id),
      hasChildren: hasChildren,
      selectedDescendantCount: state.descendantIdsOf(emotion.id).where(_selected.contains).length,
      onTap: _editMode ? () => _openEditor(emotion: emotion) : () => _toggle(emotion),
      onLongPress: hasChildren ? () => _drillInto(emotion) : null,
    );

    if (!_editMode) return chip;

    return _EditableChip(
      index: index,
      onCross: () => _onCross(emotion, state),
      child: chip,
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
            child: parent == null ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHint(BuildContext context) {
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor);
    final linkStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        );

    WidgetSpan link(String text, VoidCallback onTap) => WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(onTap: onTap, child: Text(text, style: linkStyle)),
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0 + MediaQuery.paddingOf(context).bottom),
      child: Text.rich(
        TextSpan(
          style: hintStyle,
          children: [
            TextSpan(text: '${_editMode ? context.l10n.emotionEditHint : context.l10n.emotionPickHint}   ·   '),
            link(_editMode ? context.l10n.doneEditing : context.l10n.edit, _toggleEditMode),
            const TextSpan(text: '   ·   '),
            link(context.l10n.archived, _openArchived),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Wraps a chip in edit mode: an iOS-style jiggle plus a corner cross badge.
class _EditableChip extends StatefulWidget {
  final int index;
  final Widget child;
  final VoidCallback onCross;

  const _EditableChip({required this.index, required this.child, required this.onCross});

  @override
  State<_EditableChip> createState() => _EditableChipState();
}

class _EditableChipState extends State<_EditableChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Slightly different periods per chip so they don't jiggle in lockstep.
    duration: Duration(milliseconds: 110 + (widget.index % 4) * 15),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double angle = (_controller.value * 2 - 1) * 0.035;
            return Transform.rotate(angle: angle, child: child);
          },
          child: widget.child,
        ),
        Positioned(
          top: -6,
          left: -6,
          child: GestureDetector(
            onTap: widget.onCross,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
              child: Icon(Icons.close, size: 12, color: scheme.surface),
            ),
          ),
        ),
      ],
    );
  }
}
