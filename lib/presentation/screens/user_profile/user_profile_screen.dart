import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/blocs/user_profile_bloc/user_profile_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/my_chip_widget.dart';
import 'package:keklist/presentation/screens/mind_creator_screen.dart';
import 'package:keklist/presentation/screens/settings/settings_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// TODO: fill empty sections

final class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

final class _UserProfileScreenState extends KekWidgetState<UserProfileScreen> {
  UserProfileState _userProfileState = UserProfileState(
    nickname: '',
    userDescriptionMinds: [],
    userDescriptionSuggestionEmojies: [],
  );

  @override
  void initState() {
    super.initState();

    context
        .read<UserProfileBloc>()
        .stream
        .listen((state) => setState(() => _userProfileState = state))
        .disposed(by: this);

    context.read<UserProfileBloc>().add(UserProfileGet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(16.0),
              const _UserAvatarPlaceholder(),
              const Gap(16.0),
              _UserName(name: _userProfileState.nickname),
              const Gap(4.0),
              const Text(
                'About me',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              _UserIdentityChipsWidget(
                minds: _userProfileState.userDescriptionMinds,
                onAddIdentityTag: () => _showMindCreator(initialEmoji: '🙂'),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(4.0),
              //   child: Wrap(
              //     alignment: WrapAlignment.center,
              //     spacing: 8.0,
              //     runSpacing: 8.0,
              //     children: [
              //       ..._userProfileState.userDescriptionSuggestionEmojies.map(
              //         (emoji) => MyChipWidget(
              //           isSelected: false,
              //           onSelect: (_) => {
              //             _showMindCreator(initialEmoji: emoji),
              //           },
              //           selectedColor: Colors.grey,
              //           child: Text(
              //             emoji,
              //             style: const TextStyle(fontSize: 24.0),
              //           ),
              //         ),
              //       )
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showMindCreator({required String initialEmoji}) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (_) {
        return MindCreatorScreen(
          buttonIcon: const Icon(Icons.add),
          buttonText: 'Create',
          initialEmoji: initialEmoji,
          shouldSuggestEmoji: false,
          hintText: 'Who are you?',
          onDone: (String text, String emoji) {
            sendEventTo<UserProfileBloc>(
              UserProfileAddDescribingMind(
                emoji: emoji,
                note: text,
              ),
            );
          },
        );
      },
    );
  }
}

final class _UserName extends StatelessWidget {
  const _UserName({
    required String name,
  }) : _name = name;

  final String _name;

  @override
  Widget build(BuildContext context) {
    return Text(
      _name,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

final class _UserAvatarPlaceholder extends StatelessWidget {
  const _UserAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: AlignmentDirectional.center,
      children: [
        CircleAvatar(
          radius: 80.0,
          backgroundColor: Colors.blueAccent,
        ),
        Text(
          'S', // TODO: first letter of name
          style: TextStyle(fontSize: 64.0),
        ),
      ],
    );
  }
}

final class _UserIdentityChipsWidget extends StatelessWidget {
  final List<Mind> _minds;
  final Function() _onAddIdentityTag;

  const _UserIdentityChipsWidget({
    required List<Mind> minds,
    required dynamic Function() onAddIdentityTag,
  })  : _onAddIdentityTag = onAddIdentityTag,
        _minds = minds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4.0,
        runSpacing: 0.0,
        children: [
          ..._minds.map(
            (mind) => MyChipWidget(
              isSelected: false,
              onSelect: (_) => print('didSelect'),
              selectedColor: Colors.white,
              child: Text(
                '${mind.emoji} ${mind.note}',
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ),
          MyChipWidget(
            isSelected: false,
            onSelect: (_) => {
              // TODO: show picker with suggestions
              //_showMindCreator(initialEmoji: '🙂')
              _onAddIdentityTag()
            },
            selectedColor: Colors.white,
            child: const Text(
              '+ ADD TAG',
              style: TextStyle(fontSize: 14.0),
            ),
          ),
        ],
      ),
    );
  }
}
