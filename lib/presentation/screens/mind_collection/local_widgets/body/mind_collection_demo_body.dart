// part of '../../mind_collection_screen.dart';

// final class _MindCollectionDemoBody extends StatefulWidget {
//   static final DateFormat _formatter = DateFormat('dd.MM.yyyy - EEEE');

//   @override
//   State<_MindCollectionDemoBody> createState() => _MindCollectionDemoBodyState();
// }

// final class _MindCollectionDemoBodyState extends State<_MindCollectionDemoBody> {
//   final ItemScrollController _itemScrollController = ItemScrollController();
//   final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
//   late final _demoModeRandom = Random();
//   Timer? _demoAutoScrollingTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       int nextDayIndex = 0;
//       _demoAutoScrollingTimer = Timer.periodic(
//         const Duration(seconds: 4),
//         (timer) {
//           _itemScrollController.scrollTo(
//             index: nextDayIndex++,
//             alignment: 0.015,
//             duration: const Duration(milliseconds: 4100),
//           );
//         },
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Blur(
//       blur: 3,
//       blurColor: Colors.transparent,
//       colorOpacity: 0.2,
//       child: ScrollablePositionedList.builder(
//         padding: const EdgeInsets.only(top: 16.0),
//         itemCount: 99999999999,
//         itemScrollController: _itemScrollController,
//         itemPositionsListener: _itemPositionsListener,
//         itemBuilder: (_, int dayIndex) {
//           final List<Mind> minds = List.generate(
//             15,
//             (index) {
//               final String randomEmoji = KeklistConstants
//                   .demoModeEmojiList[_demoModeRandom.nextInt(KeklistConstants.demoModeEmojiList.length - 1)];
//               return Mind(
//                 emoji: randomEmoji,
//                 creationDate: DateTime.now(),
//                 note: '',
//                 dayIndex: 0,
//                 id: const Uuid().v4(),
//                 sortIndex: 0,
//                 rootId: null,
//               );
//             },
//           ).toList();

//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 18.0),
//               Text(_MindCollectionDemoBody._formatter.format(MindUtils.getDateFromDayIndex(dayIndex))),
//               const SizedBox(height: 4.0),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: MindRowWidget(minds: minds),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _demoAutoScrollingTimer?.cancel();

//     super.dispose();
//   }
// }
