import 'package:flutter/material.dart' hide DateUtils;
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/messaged_list/mind_message_widget.dart';

final class MindUniversalListScreen extends StatefulWidget {
  final String title;
  final String emptyStateMessage;
  final bool Function(Mind) filterFunction;
  final Iterable<Mind> allMinds;
  final Function? onSelectMind;
  final VoidCallback? onCreate;
  final IconData? createButtonIcon;
  final String? createButtonLabel;

  const MindUniversalListScreen({
    super.key,
    required this.allMinds,
    required this.filterFunction,
    this.title = "Minds",
    this.emptyStateMessage = "No minds",
    this.onSelectMind,
    this.onCreate,
    this.createButtonIcon,
    this.createButtonLabel,
  });

  @override
  State<MindUniversalListScreen> createState() => _MindUniversalListScreenState();
}

final class _MindUniversalListScreenState extends KekWidgetState<MindUniversalListScreen> {
  final List<Mind> _allMinds = [];
  final List<Mind> _filteredMinds = [];

  bool get _isSingleDay => _filteredMinds.map((m) => m.dayIndex).toSet().length <= 1;

  @override
  void initState() {
    super.initState();

    _allMinds.addAll(widget.allMinds);
    _recomputeFiltered();

    subscribeToBloc<MindBloc>(
      onNewState: (state) async {
        if (state is MindList) {
          setState(() {
            _allMinds
              ..clear()
              ..addAll(state.values);
            _recomputeFiltered();
          });
        }
      },
    )?.disposed(by: this);
  }

  void _recomputeFiltered() {
    _filteredMinds
      ..clear()
      ..addAll(
        _allMinds
            .where(widget.filterFunction)
            .where((element) => element.rootId == null)
            .sortedByProperty((mind) => mind.dayIndex),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.onCreate,
              icon: Icon(widget.createButtonIcon ?? Icons.add),
              label: Text(
                widget.createButtonLabel ?? '',
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
              enableFeedback: true,
            ),
      body: BoolWidget(
        condition: _filteredMinds.isNotEmpty,
        falseChild: Center(
          child: MindCollectionEmptyStateWidget.noMinds(context: context, text: widget.emptyStateMessage),
        ),
        trueChild: Scrollbar(
          child: ListView.builder(
            itemBuilder: (context, index) {
              final bool shouldShowTitle = !_isSingleDay &&
                  (index == 0 || _filteredMinds[index].dayIndex != _filteredMinds[index - 1].dayIndex);
              final String title = DateFormatters.formatFullDate(
                DateUtils.getDateFromDayIndex(_filteredMinds[index].dayIndex),
                Localizations.localeOf(context),
              );
              final Mind mind = _filteredMinds[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    BoolWidget(
                      condition: shouldShowTitle,
                      trueChild: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(title, style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                      ),
                      falseChild: const SizedBox.shrink(),
                    ),
                    GestureDetector(
                      onTap: () => widget.onSelectMind?.call(mind),
                      child: MindMessageWidget(
                        mind: mind,
                        children: widget.allMinds.where((element) => element.rootId == mind.id).toList(growable: false),
                        onRootOptions: null,
                        onChildOptions: null,
                      ),
                    ),
                  ],
                ),
              );
            },
            itemCount: _filteredMinds.length,
          ),
        ),
      ),
    );
  }
}
