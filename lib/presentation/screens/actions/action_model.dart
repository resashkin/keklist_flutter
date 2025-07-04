import 'package:flutter/material.dart';

sealed class ActionModel {
  final String title;
  final Icon icon;

  const ActionModel({
    required this.title,
    required this.icon,
  });

  // TODO: get rid from this list and make it smarter

  factory ActionModel.custom({required String title, required Icon icon}) =>
      CustomActionModel(title: title, icon: icon);
  factory ActionModel.chatWithAI() => const ChatWithAIActionModel();
  factory ActionModel.photosPerDay() => const PhotosPerDayActionModel();
  factory ActionModel.extraActions() => const ExtraActionsMenuActionModel();
  factory ActionModel.mindOptions() => const MindOptionsMenuActionModel();
  factory ActionModel.edit() => const EditMenuActionModel();
  factory ActionModel.delete() => const DeleteMenuActionModel();
  factory ActionModel.share() => const ShareMenuActionModel();
  factory ActionModel.switchDay() => const SwitchDayMenuActionModel();
  factory ActionModel.showDigest() => const ShowDigestActionModel();
  factory ActionModel.goToDate() => const GoToDateMenuActionModel();
  factory ActionModel.showAll() => const ShowAllMenuActionModel();
  factory ActionModel.tranlsateToEnglish() => const TranslateToEnglishMenuActionModel();
  factory ActionModel.convertToStandalone() => const ConvertToStandaloneMenuActionModel();
}

final class CustomActionModel extends ActionModel {
  const CustomActionModel({required super.title, required super.icon});
}

final class ChatWithAIActionModel extends ActionModel {
  const ChatWithAIActionModel()
      : super(
          title: 'Chat with AI',
          icon: const Icon(Icons.chat),
        );
}

final class PhotosPerDayActionModel extends ActionModel {
  const PhotosPerDayActionModel()
      : super(
          title: 'Photos per day',
          icon: const Icon(Icons.photo),
        );
}

final class ExtraActionsMenuActionModel extends ActionModel {
  const ExtraActionsMenuActionModel()
      : super(
          title: 'Extra actions',
          icon: const Icon(Icons.read_more),
        );
}

final class MindOptionsMenuActionModel extends ActionModel {
  const MindOptionsMenuActionModel()
      : super(
          title: 'Mind options',
          icon: const Icon(Icons.more_vert),
        );
}

final class EditMenuActionModel extends ActionModel {
  const EditMenuActionModel()
      : super(
          title: 'Edit',
          icon: const Icon(Icons.edit),
        );
}

final class DeleteMenuActionModel extends ActionModel {
  const DeleteMenuActionModel()
      : super(
          title: 'Delete',
          icon: const Icon(Icons.delete),
        );
}

final class ShareMenuActionModel extends ActionModel {
  const ShareMenuActionModel()
      : super(
          title: 'Share',
          icon: const Icon(Icons.share),
        );
}

final class SwitchDayMenuActionModel extends ActionModel {
  const SwitchDayMenuActionModel()
      : super(
          title: 'Switch day',
          icon: const Icon(Icons.calendar_today),
        );
}

final class GoToDateMenuActionModel extends ActionModel {
  const GoToDateMenuActionModel()
      : super(
          title: 'Go to date',
          icon: const Icon(Icons.calendar_today),
        );
}

final class ShowDigestActionModel extends ActionModel {
  const ShowDigestActionModel()
      : super(
          title: 'Show digest for ...',
          icon: const Icon(Icons.filter_center_focus),
        );
}

final class ShowAllMenuActionModel extends ActionModel {
  const ShowAllMenuActionModel()
      : super(
          title: 'Show all',
          icon: const Icon(Icons.show_chart),
        );
}

final class TranslateToEnglishMenuActionModel extends ActionModel {
  const TranslateToEnglishMenuActionModel()
      : super(
          title: 'Translate to English',
          icon: const Icon(Icons.translate),
        );
}

final class ConvertToStandaloneMenuActionModel extends ActionModel {
  const ConvertToStandaloneMenuActionModel()
      : super(
          title: 'Convert to standalone entry',
          icon: const Icon(Icons.move_up),
        );
}

