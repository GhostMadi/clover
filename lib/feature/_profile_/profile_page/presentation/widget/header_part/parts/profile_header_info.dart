import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Имя и никнейм под блоком статистики.
class ProfileHeaderIdentity extends StatelessWidget {
  const ProfileHeaderIdentity({
    super.key,
    required this.fullName,
    required this.username,
  });

  final String? fullName;
  final String? username;

  static const double _figmaNameFont = 18;
  static const double _figmaNickFont = 14;
  static const double _figmaGap = 2;

  @override
  Widget build(BuildContext context) {
    final name = fullName?.trim();
    final hasName = name != null && name.isNotEmpty;
    final nick = username?.trim();
    final hasNick = nick != null && nick.isNotEmpty;

    final nameFont = context.heightByContext(_figmaNameFont);
    final nickFont = context.heightByContext(_figmaNickFont);
    final gap = context.heightByContext(_figmaGap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasName) ...[
          Text(
            name,
            style: AppTextStyle.base(nameFont, color: context.colors.textColor, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: gap),
        ],
        if (!hasNick)
          Text(
            'пусто',
            style: AppTextStyle.base(nickFont, color: context.colors.iconMuted, fontWeight: FontWeight.w600),
          )
        else
          Text(
            '@$nick',
            style: AppTextStyle.base(nickFont, color: context.colors.primary, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

/// Сворачиваемое био.
class ProfileHeaderBio extends StatefulWidget {
  const ProfileHeaderBio({super.key, required this.text});

  final String text;

  static const double _figmaFont = 14;

  @override
  State<ProfileHeaderBio> createState() => _ProfileHeaderBioState();
}

class _ProfileHeaderBioState extends State<ProfileHeaderBio> {
  late final ValueNotifier<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = ValueNotifier(false);
  }

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bio = widget.text;
    final fontSize = context.heightByContext(ProfileHeaderBio._figmaFont);

    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, expanded, _) {
        return GestureDetector(
          onTap: () => _expanded.value = !expanded,
          child: RichText(
            text: TextSpan(
              style: AppTextStyle.base(fontSize, color: context.colors.textColor, height: 1.4),
              children: [
                TextSpan(text: bio.length > 90 && !expanded ? '${bio.substring(0, 90)}...' : bio),
                if (bio.length > 90 && !expanded)
                  TextSpan(
                    text: ' еще',
                    style: AppTextStyle.base(fontSize, color: context.colors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Строка локации.
class ProfileHeaderLocation extends StatelessWidget {
  const ProfileHeaderLocation({super.key, required this.location});

  final String location;

  static const double _figmaIconSize = 14;
  static const double _figmaGap = 4;
  static const double _figmaFont = 12;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          AppIcons.locationOn.icon,
          size: context.heightByContext(_figmaIconSize),
          color: context.colors.primary,
        ),
        SizedBox(width: context.widthByContext(_figmaGap)),
        Expanded(
          child: Text(
            location,
            style: AppTextStyle.base(
              context.heightByContext(_figmaFont),
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
