part of '../../mind_collection_screen.dart';

final class _MindCollectionAppBar extends StatelessWidget {
  final bool isUpdating;
  final bool isOfflineMode;
  final VoidCallback onSearch;
  final VoidCallback onTitle;
  final VoidCallback onCalendar;
  final VoidCallback onCalendarLongTap;
  final VoidCallback? onUserProfile = null;
  final VoidCallback? onInsights = null;
  final VoidCallback onOfflineMode;

  const _MindCollectionAppBar({
    required this.isUpdating,
    required this.onSearch,
    required this.onTitle,
    required this.onCalendar,
    required this.onCalendarLongTap,
    required this.isOfflineMode,
    required this.onOfflineMode,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      automaticallyImplyLeading: true,
      actions: _makeAppBarActions(),
      title: GestureDetector(
        onTap: onTitle,
        child: Row(
          children: [
            IconButton(
              onPressed: onOfflineMode,
              icon: BoolWidget(
                condition: isUpdating,
                trueChild: const CupertinoActivityIndicator(),
                falseChild: BoolWidget(
                  condition: isOfflineMode,
                  trueChild: const Icon(Icons.cloud_off),
                  falseChild: const Icon(Icons.cloud_done_outlined),
                ),
              ),
            ),
            const Text('Notes'),
          ],
        ),
      ),
    );
  }

  List<Widget>? _makeAppBarActions() => [
        if (onInsights != null) ...{
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: onInsights,
          ),
        },
        if (onUserProfile != null) ...{
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: onUserProfile,
          ),
        },
        IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: onCalendar,
          onLongPress: onCalendarLongTap,
        ),
        SensitiveWidget(
          mode: SensitiveMode.blurred,
          child: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              !SensitiveWidget.isProtected ? onSearch() : null;
            },
          ),
        ),
      ];
}
