import 'dart:async';

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
/// only place to manage the emotion tree. Shows one tree level at a time.
///
/// Normal mode: tap a chip to tag it, long-press (or the chevron) to drill in.
/// Edit mode: chips jiggle; tap to rename, corner cross to delete/archive (two
/// taps), long-press-drag to move. While dragging, holding ~1s over a chip
/// drills into it (so you can drop inside), and holding ~1s over the back arrow
/// goes up a level — the drag stays alive across navigation.
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
  static const Duration _springDelay = Duration(seconds: 1);

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

  // Latest built level, for the pointer handlers.
  EmotionsList? _state;
  List<Emotion> _levelChildren = const [];
  ScrollController? _scrollController;

  // Keys for hit-testing during a custom drag.
  final Map<String, GlobalKey> _chipKeys = {};
  final GlobalKey _scrollAreaKey = GlobalKey();
  final GlobalKey _backKey = GlobalKey();

  // --- Custom drag state -----------------------------------------------------
  String? _draggingId;
  Offset _pointerGlobal = Offset.zero;
  Size _dragChipSize = Size.zero;
  int? _insertIndex;
  OverlayEntry? _dragOverlay;

  String? _springTargetId; // chip being hovered toward a spring-in
  Timer? _springTimer;
  bool _overBack = false;
  Timer? _backSpringTimer;
  Timer? _autoScrollTimer;

  // Two-step cross delete.
  String? _armedRemoveId;
  Timer? _armTimer;

  String? get _currentParentId => _path.last;
  bool get _canGoBack => _path.length > 1;

  GlobalKey _chipKey(String id) => _chipKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void dispose() {
    _springTimer?.cancel();
    _backSpringTimer?.cancel();
    _autoScrollTimer?.cancel();
    _armTimer?.cancel();
    _dragOverlay?.remove();
    _dragController.dispose();
    super.dispose();
  }

  // --- Tagging & navigation --------------------------------------------------

  void _toggle(Emotion emotion) {
    final bool added = _selected.add(emotion.id);
    if (!added) _selected.remove(emotion.id);
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
    final referenced = context.read<MindRepository>().values.expand((mind) => mind.emotionIds).toSet();
    final subtree = {emotion.id, ...state.descendantIdsOf(emotion.id)};
    if (!subtree.any(referenced.contains)) {
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

  /// Two-step delete: first tap arms the cross (turns red), second removes.
  void _onCrossTap(Emotion emotion, EmotionsList state) {
    if (_armedRemoveId == emotion.id) {
      _armTimer?.cancel();
      setState(() => _armedRemoveId = null);
      _onCross(emotion, state);
      return;
    }
    Haptics.vibrate(HapticsType.soft);
    setState(() => _armedRemoveId = emotion.id);
    _armTimer?.cancel();
    _armTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _armedRemoveId == emotion.id) setState(() => _armedRemoveId = null);
    });
  }

  // --- Custom drag: long-press lifecycle -------------------------------------
  // A long-press (not a passive Listener) is used so that once the drag is
  // recognized it WINS the gesture arena — the sheet and inner scroll then yield
  // instead of also moving. The recognizer lives on the persistent body wrapper,
  // so spring-load navigation (rebuilding the level) doesn't cancel the drag.

  void _onLongPressStart(Offset pos) {
    if (!_editMode || _draggingId != null) return;
    final id = _chipIdAt(pos);
    if (id == null) return;
    _pointerGlobal = pos;
    _startDrag(id);
  }

  void _onLongPressMove(Offset pos) {
    if (_draggingId == null) return;
    _pointerGlobal = pos;
    _dragOverlay?.markNeedsBuild();
    _updateHover(pos);
  }

  void _onLongPressEnd() {
    if (_draggingId != null) _finishDrag();
  }

  void _startDrag(String id) {
    if (!mounted) return;
    final box = _chipKey(id).currentContext?.findRenderObject() as RenderBox?;
    final index = _levelChildren.indexWhere((e) => e.id == id);
    Haptics.vibrate(HapticsType.medium);
    setState(() {
      _draggingId = id;
      _dragChipSize = box?.size ?? const Size(88, 34);
      _insertIndex = index < 0 ? 0 : index;
    });
    _dragOverlay = OverlayEntry(builder: _buildDragFeedback);
    Overlay.of(context).insert(_dragOverlay!);
  }

  void _updateHover(Offset pos) {
    // Back arrow → spring up a level.
    if (_canGoBack && _rectOf(_backKey)?.contains(pos) == true) {
      if (!_overBack) setState(() => _overBack = true);
      _springTargetId = null;
      _springTimer?.cancel();
      _backSpringTimer ??= Timer(EmotionMarkingSheet._springDelay, _springBack);
      _stopAutoScroll();
      return;
    }
    if (_overBack) setState(() => _overBack = false);
    _backSpringTimer?.cancel();
    _backSpringTimer = null;

    final target = _chipIdAt(pos, exclude: _draggingId);
    if (target != null) {
      final box = _chipKey(target).currentContext?.findRenderObject() as RenderBox?;
      final index = _levelChildren.indexWhere((e) => e.id == target);
      double frac = 0.5;
      if (box != null) frac = (box.globalToLocal(pos).dx / box.size.width).clamp(0.0, 1.0);

      // Central band springs into the chip; the edges are reorder zones.
      final bool canSpring = frac > 0.25 && frac < 0.75;
      if (canSpring) {
        if (_springTargetId != target) {
          _springTargetId = target;
          _springTimer?.cancel();
          _springTimer = Timer(EmotionMarkingSheet._springDelay, () => _springInto(target));
        }
      } else {
        _springTargetId = null;
        _springTimer?.cancel();
      }
      final int insert = frac > 0.5 ? index + 1 : index;
      if (_insertIndex != insert) setState(() => _insertIndex = insert);
    } else {
      _springTargetId = null;
      _springTimer?.cancel();
      final end = _levelChildren.length;
      if (_insertIndex != end) setState(() => _insertIndex = end);
    }
    _maybeAutoScroll(pos);
  }

  void _springInto(String id) {
    if (!mounted || _draggingId == null) return;
    Haptics.vibrate(HapticsType.medium);
    _springTargetId = null;
    _springTimer?.cancel();
    setState(() {
      _path.add(id);
      _insertIndex = null;
    });
  }

  void _springBack() {
    if (!mounted || _draggingId == null || !_canGoBack) return;
    Haptics.vibrate(HapticsType.medium);
    _backSpringTimer?.cancel();
    _backSpringTimer = null;
    setState(() {
      _path.removeLast();
      _overBack = false;
      _insertIndex = null;
    });
  }

  void _finishDrag() {
    final id = _draggingId;
    _cancelDrag();
    if (id == null) return;

    final sameParent = _state?.byId(id)?.parentId == _currentParentId;
    int idx = _insertIndex ?? _levelChildren.length;
    if (sameParent) {
      final from = _levelChildren.indexWhere((e) => e.id == id);
      if (from >= 0 && from < idx) idx -= 1;
    }
    Haptics.vibrate(HapticsType.light);
    context.read<EmotionBloc>().add(EmotionMove(id: id, newParentId: _currentParentId, index: idx));
  }

  void _cancelDrag() {
    _springTimer?.cancel();
    _backSpringTimer?.cancel();
    _backSpringTimer = null;
    _stopAutoScroll();
    _dragOverlay?.remove();
    _dragOverlay = null;
    setState(() {
      _draggingId = null;
      _insertIndex = null;
      _springTargetId = null;
      _overBack = false;
    });
  }

  /// Emotion id whose chip rect contains [pos] at the current level.
  String? _chipIdAt(Offset pos, {String? exclude}) {
    for (final emotion in _levelChildren) {
      if (emotion.id == exclude) continue;
      if (_rectOf(_chipKey(emotion.id))?.contains(pos) == true) return emotion.id;
    }
    return null;
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _maybeAutoScroll(Offset pos) {
    final area = _rectOf(_scrollAreaKey);
    final controller = _scrollController;
    if (area == null || controller == null || !controller.hasClients) {
      _stopAutoScroll();
      return;
    }
    const double edge = 52.0;
    double direction = 0;
    if (pos.dy < area.top + edge) {
      direction = -1;
    } else if (pos.dy > area.bottom - edge) {
      direction = 1;
    }
    if (direction == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!controller.hasClients) return;
      final p = controller.position;
      controller.jumpTo((p.pixels + direction * 8).clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  // --- Sheet drag handle -----------------------------------------------------

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

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // --- Build -----------------------------------------------------------------

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
        _scrollController = scrollController;
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            if (_draggingId == null && n.extent <= n.minExtent + 0.001) _dismiss();
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
                      _state = state;
                      _levelChildren = state.childrenOf(_currentParentId);
                      final parent = _currentParentId == null ? null : state.byId(_currentParentId!);

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onLongPressStart: _editMode ? (d) => _onLongPressStart(d.globalPosition) : null,
                        onLongPressMoveUpdate: _editMode ? (d) => _onLongPressMove(d.globalPosition) : null,
                        onLongPressEnd: _editMode ? (_) => _onLongPressEnd() : null,
                        onLongPressCancel: _editMode
                            ? () {
                                if (_draggingId != null) _cancelDrag();
                              }
                            : null,
                        child: Column(
                          children: [
                            _buildHeader(context, state, parent),
                            Expanded(
                              child: SingleChildScrollView(
                                key: _scrollAreaKey,
                                controller: scrollController,
                                physics: _draggingId != null
                                    ? const NeverScrollableScrollPhysics()
                                    : const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_levelChildren.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                                        child: Center(child: Text(context.l10n.noEmotionsYet)),
                                      )
                                    else
                                      _buildChipsArea(context, state, _levelChildren),
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
                        ),
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

  Widget _buildChipsArea(BuildContext context, EmotionsList state, List<Emotion> children) {
    if (!_editMode) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        alignment: WrapAlignment.center,
        children: [for (final emotion in children) _staticChip(context, state, emotion)],
      );
    }

    final List<Widget> widgets = [];
    for (int i = 0; i < children.length; i++) {
      final emotion = children[i];
      widgets.add(_gap(i));
      if (_draggingId == emotion.id) {
        // Hide the dragged chip from the flow; the animated gap is its stand-in.
        widgets.add(const SizedBox.shrink());
      } else {
        widgets.add(_EditableChip(
          key: _chipKey(emotion.id),
          index: i,
          isNestTarget: _springTargetId == emotion.id,
          armed: _armedRemoveId == emotion.id,
          onCross: () => _onCrossTap(emotion, state),
          child: _staticChip(context, state, emotion, forEdit: true),
        ));
      }
    }
    widgets.add(_gap(children.length));
    return Wrap(spacing: 0, runSpacing: 10.0, alignment: WrapAlignment.center, children: widgets);
  }

  /// Animated placeholder that opens where the dragged chip will land.
  Widget _gap(int index) {
    final bool open = _draggingId != null && _springTargetId == null && _insertIndex == index;
    final double height = _dragChipSize.height > 0 ? _dragChipSize.height : 34.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: open ? _dragChipSize.width + 10.0 : 10.0,
      height: height,
    );
  }

  Widget _staticChip(BuildContext context, EmotionsList state, Emotion emotion, {bool forEdit = false}) {
    final bool hasChildren = state.hasActiveChildren(emotion.id);
    return EmotionChip(
      emojis: [emotion.emoji],
      label: emotion.title,
      selected: !forEdit && _selected.contains(emotion.id),
      hasChildren: hasChildren,
      selectedDescendantCount: state.descendantIdsOf(emotion.id).where(_selected.contains).length,
      onTap: forEdit ? () => _openEditor(emotion: emotion) : () => _toggle(emotion),
      onLongPress: forEdit ? null : (hasChildren ? () => _drillInto(emotion) : null),
      onChevronTap: forEdit && hasChildren ? () => _drillInto(emotion) : null,
    );
  }

  Widget _buildDragFeedback(BuildContext context) {
    final state = _state;
    final id = _draggingId;
    if (state == null || id == null) return const SizedBox.shrink();
    final emotion = state.byId(id);
    if (emotion == null) return const SizedBox.shrink();
    return Positioned(
      left: _pointerGlobal.dx - _dragChipSize.width / 2,
      top: _pointerGlobal.dy - _dragChipSize.height / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.92,
          child: Material(
            color: Colors.transparent,
            child: EmotionChip(
              emojis: [emotion.emoji],
              label: emotion.title,
              hasChildren: state.hasActiveChildren(emotion.id),
            ),
          ),
        ),
      ),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String title =
        parent == null ? context.l10n.emotions : '${state.lineageEmojis(parent).join(' ')}  ${parent.title}';

    Widget back;
    if (parent == null) {
      back = const SizedBox(width: 48);
    } else {
      final bool active = _draggingId != null && _overBack;
      back = AnimatedContainer(
        key: _backKey,
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: active ? scheme.onPrimaryContainer : null),
          onPressed: _goBack,
        ),
      );
    }

    final editButton = TextButton(
      onPressed: _toggleEditMode,
      child: Text(
        _editMode ? context.l10n.doneEditing : context.l10n.edit,
        style: TextStyle(fontSize: 16.0, fontWeight: _editMode ? FontWeight.bold : FontWeight.normal),
      ),
    );

    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 76.0),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KekBottomSheetStyle.titleStyle(context),
              ),
            ),
          ),
          Align(alignment: Alignment.centerLeft, child: back),
          Align(alignment: Alignment.centerRight, child: editButton),
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
            link(context.l10n.archived, _openArchived),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Wraps a chip in edit mode: an iOS-style jiggle, a corner cross badge, and a
/// highlight ring when it is the current spring-in / nest target.
class _EditableChip extends StatefulWidget {
  final int index;
  final Widget child;
  final bool isNestTarget;
  final bool armed;
  final VoidCallback onCross;

  const _EditableChip({
    super.key,
    required this.index,
    required this.child,
    required this.isNestTarget,
    required this.armed,
    required this.onCross,
  });

  @override
  State<_EditableChip> createState() => _EditableChipState();
}

class _EditableChipState extends State<_EditableChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.0),
              border: Border.all(
                color: widget.armed
                    ? scheme.error
                    : widget.isNestTarget
                        ? scheme.primary
                        : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: widget.child,
          ),
        ),
        Positioned(
          top: -6,
          left: -6,
          child: GestureDetector(
            onTap: widget.onCross,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.armed ? scheme.error : scheme.onSurfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
              child: Icon(Icons.close, size: 12, color: widget.armed ? scheme.onError : scheme.surface),
            ),
          ),
        ),
      ],
    );
  }
}
