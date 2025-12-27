import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/helpers/platform_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';

final class MindCreatorBottomBar extends StatefulWidget {
  final Mind? editableMind;
  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final String? selectedEmoji;
  final VoidCallback onTapEmoji;
  final String doneTitle;
  final String placeholder;
  final VoidCallback onTapCancelEdit;
  final Function(CreateMindData) onDone;
  final Function()? onTapRecordAudio;

  const MindCreatorBottomBar({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.selectedEmoji,
    required this.doneTitle,
    required this.onDone,
    required this.onTapEmoji,
    required this.placeholder,
    this.editableMind,
    required this.onTapCancelEdit,
    required this.onTapRecordAudio,
  });

  @override
  State<MindCreatorBottomBar> createState() => _MindCreatorBottomBarState();
}

final class _MindCreatorBottomBarState extends State<MindCreatorBottomBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            const _HorizontalSeparator(),
            if (widget.editableMind != null) ...[
              _EditableMindInfoWidget(
                editableMind: widget.editableMind!,
                onTapCancelEdit: widget.onTapCancelEdit,
                onTapEmoji: widget.onTapEmoji,
              ),
              const _HorizontalSeparator(),
            ],
            const SizedBox(height: 8.0),
            _TextFieldWidget(
              onSearchEmoji: widget.onTapEmoji,
              placeholder: widget.placeholder,
              focusNode: widget.focusNode,
              textEditingController: widget.textEditingController,
              doneTitle: widget.doneTitle.toUpperCase(),
              onDone: () {
                widget.onDone(
                  CreateMindData(emoji: widget.selectedEmoji ?? '', text: widget.textEditingController.text),
                );
              },
              onTapRecordAudio: widget.onTapRecordAudio,
            ),
            const SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }
}

final class _EditableMindInfoWidget extends StatelessWidget {
  final Mind editableMind;
  final Function() onTapEmoji;
  final Function() onTapCancelEdit;

  const _EditableMindInfoWidget({required this.editableMind, required this.onTapEmoji, required this.onTapCancelEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(padding: EdgeInsets.all(10.0), child: Icon(Icons.edit)),
        Container(color: Theme.of(context).disabledColor, height: 38.0, width: 0.3),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(editableMind.note.replaceAll('\n', ' '), overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onTapCancelEdit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _HorizontalSeparator extends StatelessWidget {
  const _HorizontalSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).disabledColor, height: 0.3);
  }
}

final class _TextFieldWidget extends StatelessWidget {
  const _TextFieldWidget({
    required this.placeholder,
    required this.onSearchEmoji,
    required this.focusNode,
    required this.textEditingController,
    required this.doneTitle,
    required this.onDone,
    required this.onTapRecordAudio,
  });

  final VoidCallback onSearchEmoji;
  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final String placeholder;
  final String doneTitle;
  final Function() onDone;
  final Function()? onTapRecordAudio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8.0),
        Flexible(
          flex: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
            child: TextField(
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              maxLines: () {
                if (MediaQuery.of(context).orientation != Orientation.landscape && DeviceUtils.isPhone(context)) {
                  return null;
                } else {
                  return 1;
                }
              }(),
              textCapitalization: TextCapitalization.sentences,
              controller: textEditingController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(12.0),
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                hintText: placeholder,
                suffixIcon: SensitiveWidget(
                  mode: SensitiveMode.blurredAndNonTappable,
                  child: TextButton(
                    style: ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                      foregroundColor: WidgetStateProperty.all(Colors.blueAccent),
                    ),
                    onPressed: onDone,
                    child: Text(doneTitle, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        ),
        BoolWidget(
          condition: onTapRecordAudio != null,
          trueChild: IconButton(
            onPressed: onTapRecordAudio,
            icon: Icon(Icons.mic, color: Colors.blueAccent),
          ),
          falseChild: Gap(0),
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }
}

final class CreateMindData {
  final String text;
  final String emoji;

  const CreateMindData({required this.text, required this.emoji});
}
