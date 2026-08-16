import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:material_ui/material_ui.dart';
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
/// only place to manage emotions. Shows one tree level at a time in a fixed-height
/// sheet.
///
/// Normal mode: tap a chip to tag it, long-press (or the chevron) to drill in.
/// Edit mode: chips jiggle; tap to rename, corner cross to delete/archive (two
/// taps), long-press-drag to reorder among siblings.
///
/// Nesting is deliberately not authorable here — see
/// `documentation/adr/ADR-0002-emotion-nesting-ui-removal.md`. Existing nested
/// emotions stay reachable through drill-in, and new emotions can only be added
/// at the top level.
final class EmotionMarkingSheet extends StatefulWidget {
  final Set<String> initialSelectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  /// Opens the sheet aimed at this emotion: the path is seeded with its ancestor
  /// chain, then its chip is scrolled into view and briefly ringed.
  final String? focusEmotionId;

  const EmotionMarkingSheet({
    super.key,
    required this.initialSelectedIds,
    required this.onSelectionChanged,
    this.focusEmotionId,
  });

  /// Fraction of the screen the sheet occupies. Fixed — the sheet is not resizable.
  static const double _heightFactor = 0.5;
  static const Duration _focusRingDuration = Duration(milliseconds: 1800);

  static Future<void> show({
    required BuildContext context,
    required Set<String> initialSelectedIds,
    required ValueChanged<Set<String>> onSelectionChanged,
    String? focusEmotionId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmotionMarkingSheet(
        initialSelectedIds: initialSelectedIds,
        onSelectionChanged: onSelectionChanged,
        focusEmotionId: focusEmotionId,
      ),
    );
  }

  @override
  State<EmotionMarkingSheet> createState() => _EmotionMarkingSheetState();
}

class _EmotionMarkingSheetState extends State<EmotionMarkingSheet> {
  late final Set<String> _selected = {...widget.initialSelectedIds};
  final ScrollController _scrollController = ScrollController();

  /// Navigation path of parent ids; `null` is the root level.
  final List<String?> _path = [null];
  bool _editMode = false;

  // Latest built level, for the pointer handlers.
  EmotionsList? _state;
  List<Emotion> _levelChildren = const [];

  // Keys for hit-testing during a custom drag.
  final Map<String, GlobalKey> _chipKeys = {};
  final GlobalKey _scrollAreaKey = GlobalKey();

  // --- Focus (deep link) state -----------------------------------------------
  bool _focusApplied = false;
  String? _focusedId;
  Timer? _focusTimer;

  // --- Custom drag state -----------------------------------------------------
  String? _draggingId;
  Offset _pointerGlobal = Offset.zero;
  Size _dragChipSize = Size.zero;
  int? _insertIndex;
  OverlayEntry? _dragOverlay;
  Timer? _autoScrollTimer;

  // Two-step cross delete.
  String? _armedRemoveId;
  Timer? _armTimer;

  String? get _currentParentId => _path.last;
  bool get _canGoBack => _path.length > 1;

  GlobalKey _chipKey(String id) => _chipKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    // First open of the marker is where the starter emotions come into being.
    context.read<EmotionBloc>().add(EmotionSeedDefaults());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _armTimer?.cancel();
    _focusTimer?.cancel();
    _dragOverlay?.remove();
    _scrollController.dispose();
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

  /// Seeds the path with the focused emotion's ancestors, then scrolls its chip
  /// into view and rings it. Runs once, on the first frame with a loaded state.
  void _applyFocus(EmotionsList state) {
    _focusApplied = true;
    final String? id = widget.focusEmotionId;
    final Emotion? target = id == null ? null : state.byId(id);
    if (target == null) return;

    final List<String?> ancestors = state.ancestorsOf(target).map((e) => e.id).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _path
          ..clear()
          ..addAll([null, ...ancestors]);
        _focusedId = target.id;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? chipContext = _chipKey(target.id).currentContext;
        if (chipContext != null) {
          Scrollable.ensureVisible(chipContext, duration: const Duration(milliseconds: 250), alignment: 0.5);
        }
      });
      _focusTimer = Timer(EmotionMarkingSheet._focusRingDuration, () {
        if (mounted) setState(() => _focusedId = null);
      });
    });
  }

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
  // recognized it WINS the gesture arena — the inner scroll then yields instead
  // of also moving. Reorder among siblings is the only drop intent.

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
    final target = _chipIdAt(pos, exclude: _draggingId);
    if (target != null) {
      final box = _chipKey(target).currentContext?.findRenderObject() as RenderBox?;
      final index = _levelChildren.indexWhere((e) => e.id == target);
      double frac = 0.5;
      if (box != null) frac = (box.globalToLocal(pos).dx / box.size.width).clamp(0.0, 1.0);
      final int insert = frac > 0.5 ? index + 1 : index;
      if (_insertIndex != insert) setState(() => _insertIndex = insert);
    } else {
      final end = _levelChildren.length;
      if (_insertIndex != end) setState(() => _insertIndex = end);
    }
    _maybeAutoScroll(pos);
  }

  void _finishDrag() {
    final id = _draggingId;
    final int? insertIndex = _insertIndex;
    _cancelDrag();
    if (id == null) return;

    final List<String> ids = _levelChildren.map((e) => e.id).toList();
    final int from = ids.indexOf(id);
    if (from < 0) return;
    int to = insertIndex ?? ids.length;
    ids.removeAt(from);
    if (from < to) to -= 1;
    ids.insert(to.clamp(0, ids.length), id);
    if (from == to) return;

    Haptics.vibrate(HapticsType.light);
    context.read<EmotionBloc>().add(EmotionReorder(orderedEmotionIds: ids));
  }

  void _cancelDrag() {
    _stopAutoScroll();
    _dragOverlay?.remove();
    _dragOverlay = null;
    setState(() {
      _draggingId = null;
      _insertIndex = null;
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
    if (area == null || !_scrollController.hasClients) {
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
      if (!_scrollController.hasClients) return;
      final p = _scrollController.position;
      _scrollController.jumpTo((p.pixels + direction * 8).clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  // --- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: EmotionMarkingSheet._heightFactor,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: KekBottomSheetStyle.decoration(context),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            KekBottomSheetStyle.handle(context),
            Expanded(
              child: BlocBuilder<EmotionBloc, EmotionState>(
                builder: (context, state) {
                  if (state is! EmotionsList) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  _state = state;
                  _levelChildren = state.childrenOf(_currentParentId);
                  final parent = _currentParentId == null ? null : state.byId(_currentParentId!);
                  if (!_focusApplied) _applyFocus(state);

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
                            controller: _scrollController,
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
                                // Creating an emotion is a top-level-only action, so the
                                // link never offers to nest one inside another.
                                if (_currentParentId == null) ...[
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
  }

  Widget _buildChipsArea(BuildContext context, EmotionsList state, List<Emotion> children) {
    if (!_editMode) {
      return Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        alignment: WrapAlignment.center,
        children: [
          for (final emotion in children)
            _FocusRing(
              key: _chipKey(emotion.id),
              active: _focusedId == emotion.id,
              child: _staticChip(context, state, emotion),
            ),
        ],
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
          armed: _armedRemoveId == emotion.id,
          dragActive: _draggingId != null,
          onCross: () => _onCrossTap(emotion, state),
          child: _staticChip(context, state, emotion, forEdit: true),
        ));
      }
    }
    widgets.add(_gap(children.length));
    return Wrap(spacing: 0, runSpacing: 10.0, alignment: WrapAlignment.center, children: widgets);
  }

  /// Landing slot for a reordered chip. When open it shows a transparent ghost
  /// of the held chip at the exact footprint it will occupy on release (net-zero
  /// with the removed chip, so rows don't hop). Instant, so moving it snaps
  /// instead of wobbling the wrap.
  Widget _gap(int index) {
    final bool open = _draggingId != null && _insertIndex == index;
    final double height = _dragChipSize.height > 0 ? _dragChipSize.height : 34.0;
    if (!open) return SizedBox(width: 10.0, height: height);
    final Emotion? dragged = _draggingId == null ? null : _state?.byId(_draggingId!);
    return SizedBox(
      width: _dragChipSize.width + 10.0,
      height: height,
      child: Center(
        child: dragged == null
            ? null
            : Opacity(
                opacity: 0.35,
                child: EmotionChip(
                  emojis: [dragged.emoji],
                  label: dragged.title,
                  hasChildren: _state!.hasActiveChildren(dragged.id),
                ),
              ),
      ),
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

  /// Left slot holds Edit at the root and the back arrow when drilled in — the
  /// two never compete for it, since editing is a root-level activity.
  Widget _buildHeader(BuildContext context, EmotionsList state, Emotion? parent) {
    final String title =
        parent == null ? context.l10n.emotions : '${state.lineageEmojis(parent).join(' ')}  ${parent.title}';

    final Widget leading = _canGoBack
        ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
        : TextButton(
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
          Align(alignment: Alignment.centerLeft, child: leading),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// Long-press only drills in when a chip actually has children, and nesting can
  /// no longer be authored (ADR-0002) — so the hint promises it only where some
  /// chip on this level can deliver it.
  String _pickHint(BuildContext context) {
    final state = _state;
    final bool canDrill =
        state != null && _levelChildren.any((emotion) => state.hasActiveChildren(emotion.id));
    return canDrill
        ? '${context.l10n.emotionPickHint} · ${context.l10n.emotionDrillHint}'
        : context.l10n.emotionPickHint;
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
            TextSpan(text: '${_editMode ? context.l10n.emotionEditHint : _pickHint(context)}   ·   '),
            link(context.l10n.archived, _openArchived),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Briefly rings a chip that the sheet was opened to point at, so the target is
/// obvious even when the level already fits on screen and nothing scrolls.
class _FocusRing extends StatelessWidget {
  final bool active;
  final Widget child;

  const _FocusRing({super.key, required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 3.0,
        ),
      ),
      child: child,
    );
  }
}

/// Wraps a chip in edit mode: an iOS-style jiggle and a corner cross badge.
class _EditableChip extends StatefulWidget {
  final int index;
  final Widget child;
  final bool armed;
  final bool dragActive;
  final VoidCallback onCross;

  const _EditableChip({
    super.key,
    required this.index,
    required this.child,
    required this.armed,
    required this.dragActive,
    required this.onCross,
  });

  @override
  State<_EditableChip> createState() => _EditableChipState();
}

class _EditableChipState extends State<_EditableChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 0.5,
    duration: Duration(milliseconds: 110 + (widget.index % 4) * 15),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.dragActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _EditableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dragActive == oldWidget.dragActive) return;
    if (widget.dragActive) {
      _controller.stop();
      _controller.animateTo(0.5, duration: const Duration(milliseconds: 120));
    } else {
      _controller.repeat(reverse: true);
    }
  }

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
                color: widget.armed ? scheme.error : Colors.transparent,
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
