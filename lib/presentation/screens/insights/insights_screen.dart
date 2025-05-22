import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/insights/widgets/insights_pie_widget.dart';
import 'package:keklist/presentation/screens/insights/widgets/insights_random_mind_widget.dart';
import 'package:keklist/presentation/screens/insights/widgets/insights_top_chart.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/mind_day_collection_screen.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';

final class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

final class _InsightsScreenState extends KekWidgetState<InsightsScreen> {
  final List<Mind> _minds = [];

  @override
  void initState() {
    super.initState();

    context.read<MindBloc>().stream.listen((state) {
      if (state is MindList) {
        setState(() {
          _minds
            ..clear()
            ..addAll(state.values);
        });
      }
    }).disposed(by: this);

    context.read<MindBloc>().add(MindGetList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
            final int crossAxisCellCount = constraints.maxWidth > 600 ? 2 : 3;
            return BoolWidget(
              condition: _minds.isNotEmpty,
              falseChild: MindCollectionEmptyDayWidget.noInsights(),
              trueChild: SingleChildScrollView(
                child: StaggeredGrid.count(
                  axisDirection: AxisDirection.down,
                  crossAxisCount: crossAxisCount,
                  children: [
                    // StaggeredGridTile.fit(
                    //   crossAxisCellCount: crossAxisCellCount,
                    //   child: GestureDetector(
                    //     onTap: () => _showDayCollectionScreen(groupDayIndex: MindUtils.getTodayIndex()),
                    //     child: InsightsTodayMindsWidget(
                    //       todayMinds: MindUtils.findTodayMinds(allMinds: _minds),
                    //     ),
                    //   ),
                    // ),
                    StaggeredGridTile.fit(
                      crossAxisCellCount: crossAxisCellCount,
                      child: InsightsPieWidget(allMinds: _minds),
                    ),
                    StaggeredGridTile.fit(
                      crossAxisCellCount: crossAxisCellCount,
                      child: InsightsTopChartWidget(allMinds: _minds),
                    ),
                    StaggeredGridTile.fit(
                      crossAxisCellCount: crossAxisCellCount,
                      child: InsightsRandomMindWidget(
                        allMinds: _minds,
                        onTapToMind: (mind) => _showDayCollectionScreen(groupDayIndex: mind.dayIndex),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDayCollectionScreen({required int groupDayIndex}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MindDayCollectionScreen(
          allMinds: _minds,
          initialDayIndex: groupDayIndex,
        ),
      ),
    );
  }
}
