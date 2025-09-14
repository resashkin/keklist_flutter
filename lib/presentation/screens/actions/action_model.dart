import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

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
  factory ActionModel.chatWithAI(BuildContext context) => ChatWithAIActionModel(context: context);
  factory ActionModel.photosPerDay(BuildContext context) => PhotosPerDayActionModel(context: context);
  factory ActionModel.extraActions(BuildContext context) => ExtraActionsMenuActionModel(context: context);
  factory ActionModel.mindOptions(BuildContext context) => MindOptionsMenuActionModel(context: context);
  factory ActionModel.edit(BuildContext context) => EditMenuActionModel(context: context);
  factory ActionModel.delete(BuildContext context) => DeleteMenuActionModel(context: context);
  factory ActionModel.share(BuildContext context) => ShareMenuActionModel(context: context);
  factory ActionModel.switchDay(BuildContext context) => SwitchDayMenuActionModel(context: context);
  factory ActionModel.showDigest(BuildContext context) => ShowDigestActionModel(context: context);
  factory ActionModel.goToDate(BuildContext context) => GoToDateMenuActionModel(context: context);
  factory ActionModel.showAll(BuildContext context) => ShowAllMenuActionModel(context: context);
  factory ActionModel.tranlsateToEnglish(BuildContext context) => TranslateToEnglishMenuActionModel(context: context);
  factory ActionModel.convertToStandalone(BuildContext context) => ConvertToStandaloneMenuActionModel(context: context);
}

final class CustomActionModel extends ActionModel {
  const CustomActionModel({required super.title, required super.icon});
}

final class ChatWithAIActionModel extends ActionModel {
  ChatWithAIActionModel({required BuildContext context})
      : super(
          title: context.l10n.chatWithAI,
          icon: const Icon(Icons.chat),
        );
}

final class PhotosPerDayActionModel extends ActionModel {
  PhotosPerDayActionModel({required BuildContext context})
      : super(
          title: context.l10n.photosPerDay,
          icon: const Icon(Icons.photo),
        );
}

final class ExtraActionsMenuActionModel extends ActionModel {
  ExtraActionsMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.extraActions,
          icon: const Icon(Icons.read_more),
        );
}

final class MindOptionsMenuActionModel extends ActionModel {
  MindOptionsMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.mindOptions,
          icon: const Icon(Icons.more_vert),
        );
}

final class EditMenuActionModel extends ActionModel {
  EditMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.edit,
          icon: const Icon(Icons.edit),
        );
}

final class DeleteMenuActionModel extends ActionModel {
  DeleteMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.delete,
          icon: const Icon(Icons.delete),
        );
}

final class ShareMenuActionModel extends ActionModel {
  ShareMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.share,
          icon: const Icon(Icons.share),
        );
}

final class SwitchDayMenuActionModel extends ActionModel {
  SwitchDayMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.switchDay,
          icon: const Icon(Icons.calendar_today),
        );
}

final class GoToDateMenuActionModel extends ActionModel {
  GoToDateMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.goToDate,
          icon: const Icon(Icons.calendar_today),
        );
}

final class ShowDigestActionModel extends ActionModel {
  ShowDigestActionModel({required BuildContext context})
      : super(
          title: context.l10n.showDigest,
          icon: const Icon(Icons.filter_center_focus),
        );
}

final class ShowAllMenuActionModel extends ActionModel {
  ShowAllMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.showAll,
          icon: const Icon(Icons.show_chart),
        );
}

final class TranslateToEnglishMenuActionModel extends ActionModel {
  TranslateToEnglishMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.translateToEnglish,
          icon: const Icon(Icons.translate),
        );
}

final class ConvertToStandaloneMenuActionModel extends ActionModel {
  ConvertToStandaloneMenuActionModel({required BuildContext context})
      : super(
          title: context.l10n.convertToStandalone,
          icon: const Icon(Icons.transform),
        );
}
