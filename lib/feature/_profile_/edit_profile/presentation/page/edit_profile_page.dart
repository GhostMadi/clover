import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/_catalog_/city/presentation/widget/city_single_select_field.dart';
import 'package:clover/feature/_catalog_/countries/presentation/widget/country_single_select_field.dart';
import 'package:clover/feature/_profile_/edit_profile/data/models/edit_profile_save_input.dart';
import 'package:clover/feature/_profile_/edit_profile/edit_profile_avatar_flow.dart';
import 'package:clover/feature/_profile_/edit_profile/edit_profile_banner_flow.dart';
import 'package:clover/feature/_profile_/edit_profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:clover/feature/_profile_/edit_profile/presentation/widget/edit_profile_bio_field.dart';
import 'package:clover/feature/_profile_/edit_profile/presentation/widget/edit_profile_media_section.dart';
import 'package:clover/feature/_profile_/edit_profile/presentation/widget/edit_profile_tags_field.dart';
import 'package:clover/feature/_profile_/edit_profile/presentation/widget/edit_profile_username_row.dart';
import 'package:clover/feature/_profile_/edit_profile/presentation/widget/edit_profile_username_sheet.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileCubit _profileCubit;
  late final EditProfileCubit _editProfileCubit;
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;

  bool _seededFromProfile = false;
  ProfileNewModel? _displayProfile;
  String _username = '';
  String? _countryCode;
  String? _cityCode;
  Set<String> _tagIds = {};
  String? _avatarUrl;
  String? _backgroundUrl;
  AppImageEditorResult? _backgroundPreview;
  AppImageEditorResult? _avatarPreview;

  @override
  void initState() {
    super.initState();
    _profileCubit = sl<ProfileCubit>();
    _editProfileCubit = sl<EditProfileCubit>();
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();

    final loaded = _profileCubit.state.mapOrNull(loaded: (s) => s.profile);
    if (loaded != null) {
      _seedFromProfile(loaded);
    } else {
      _profileCubit.load();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _editProfileCubit.close();
    super.dispose();
  }

  void _seedFromProfile(ProfileNewModel profile) {
    if (_seededFromProfile) return;
    _seededFromProfile = true;
    _displayProfile = profile;
    _fullNameController.text = profile.fullName?.trim() ?? '';
    _username = profile.username?.trim() ?? '';
    _bioController.text = profile.bio?.trim() ?? '';
    _countryCode = profile.countryCodeRaw?.trim();
    _cityCode = profile.cityCodeRaw?.trim();
    _tagIds = profile.tagKeySet;
    _avatarUrl = profile.avatarUrl?.trim();
    _backgroundUrl = profile.backgroundUrl?.trim();
  }

  void _applySavedProfile(ProfileNewModel profile) {
    _displayProfile = profile;
    _seededFromProfile = false;
    _seedFromProfile(profile);
    _avatarPreview = null;
    _backgroundPreview = null;
    _avatarUrl = profile.avatarUrl?.trim();
    _backgroundUrl = profile.backgroundUrl?.trim();
    _tagIds = profile.tagKeySet;
  }

  void _onCountryChanged(String code) {
    setState(() {
      _countryCode = code;
      _cityCode = null;
    });
  }

  void _onCityChanged(String code) {
    setState(() => _cityCode = code);
  }

  void _onTagsChanged(Set<String> tagIds) {
    setState(() => _tagIds = tagIds);
  }

  Future<void> _openBannerFlow() async {
    EditProfileBannerFlow.instance.reset();
    await context.router.push(const EditProfileBannerPickRoute());
    final result = EditProfileBannerFlow.instance.consumeResult();
    if (!mounted || result == null) return;
    setState(() => _backgroundPreview = result);
    EditProfileBannerFlow.instance.reset();
  }

  Future<void> _openAvatarFlow() async {
    EditProfileAvatarFlow.instance.reset();
    await context.router.push(const EditProfileAvatarPickRoute());
    final result = EditProfileAvatarFlow.instance.consumeResult();
    if (!mounted || result == null) return;
    setState(() => _avatarPreview = result);
    EditProfileAvatarFlow.instance.reset();
  }

  Future<void> _openUsernameSheet(ProfileNewModel profile) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final updated = await EditProfileUsernameSheet.show(
      context,
      profile: profile,
      currentUsername: _username,
      onSave: _editProfileCubit.saveUsername,
    );
    if (!mounted || updated == null) return;

    _applySavedProfile(updated);
    _profileCubit.applyProfile(updated);
    await _profileCubit.refresh();
    if (!mounted) return;

    setState(() {});
    AppSnackBar.show(context, message: 'Никнейм сохранён', kind: AppSnackBarKind.success);
  }

  Future<void> _onSave() async {
    final profile = await _editProfileCubit.saveProfile(
      EditProfileSaveInput(
        fullName: _fullNameController.text,
        bio: _bioController.text,
        countryCode: _countryCode,
        cityCode: _cityCode,
        tagIds: _tagIds,
        avatarPreview: _avatarPreview,
        backgroundPreview: _backgroundPreview,
      ),
    );
    if (!mounted || profile == null) return;

    _applySavedProfile(profile);
    _profileCubit.applyProfile(profile);
    await _profileCubit.refresh();
    if (!mounted) return;

    setState(() {});
    AppSnackBar.show(context, message: 'Профиль сохранён', kind: AppSnackBarKind.success);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileCubit),
        BlocProvider.value(value: _editProfileCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProfileCubit, ProfileState>(
            listenWhen: (prev, next) => next.mapOrNull(loaded: (_) => true) ?? false,
            listener: (context, state) {
              state.mapOrNull(loaded: (s) => _seedFromProfile(s.profile));
              if (mounted) setState(() {});
            },
          ),
          BlocListener<EditProfileCubit, EditProfileState>(
            listenWhen: (prev, next) => next.mapOrNull(error: (_) => true) ?? false,
            listener: (context, state) {
              state.mapOrNull(
                error: (s) {
                  AppSnackBar.show(context, message: s.message, kind: AppSnackBarKind.error);
                  _editProfileCubit.clearFeedback();
                },
              );
            },
          ),
        ],
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return BlocBuilder<EditProfileCubit, EditProfileState>(
              builder: (context, editState) {
                return SettingsScreenShell(
                  title: 'Редактировать профиль',
                  extraButtons: [
                    if (state.mapOrNull(loaded: (_) => true) ?? false)
                      FunctionalButtonItem(
                        icon: AppIcons.checkRounded.icon,
                        keepWhenCollapsed: true,
                        isLoading: editState.mapOrNull(saving: (_) => true) ?? false,
                        onTap: editState.mapOrNull(saving: (_) => true, savingUsername: (_) => true) ?? false
                            ? () {}
                            : _onSave,
                      ),
                  ],
                  body: state.when(
                    initial: () => const _EditProfileLoading(),
                    loading: () => const _EditProfileLoading(),
                    error: (message) => _EditProfileError(message: message, onRetry: _profileCubit.load),
                    loaded: (profile) {
                      _seedFromProfile(profile);
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: SettingsScreenShell.scrollBottomGap(context)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EditProfileMediaSection(
                              coverUrl: _backgroundPreview == null ? _backgroundUrl : null,
                              coverPreview: _backgroundPreview,
                              avatarUrl: _avatarPreview == null ? _avatarUrl : null,
                              avatarPreview: _avatarPreview,
                              onChangeCover: _openBannerFlow,
                              onChangeAvatar: _openAvatarFlow,
                            ),
                            const SizedBox(height: 52),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SettingsTileSectionTitle('Основное'),
                                  AppField(
                                    controller: _fullNameController,
                                    labelText: 'Имя',
                                    hintText: 'Как вас зовут',
                                    prefixIcon: AppIcons.badge.icon,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  EditProfileUsernameRow(
                                    profile: _displayProfile ?? profile,
                                    username: _username,
                                    onTap: () => _openUsernameSheet(profile),
                                  ),
                                  const SizedBox(height: 12),
                                  _EditProfileEmailRow(email: profile.email),
                                  const SizedBox(height: 20),
                                  const SettingsTileSectionTitle('Локация'),
                                  CountrySingleSelectField(
                                    label: 'Страна',
                                    hint: 'Выберите страну',
                                    value: _countryCode,
                                    onChanged: _onCountryChanged,
                                  ),
                                  const SizedBox(height: 12),
                                  CitySingleSelectField(
                                    label: 'Город',
                                    hint: 'Выберите город',
                                    countryCode: _countryCode,
                                    value: _cityCode,
                                    onChanged: _onCityChanged,
                                  ),
                                  const SizedBox(height: 20),
                                  const SettingsTileSectionTitle('Аккаунт'),
                                  EditProfileTagsField(
                                    values: _tagIds,
                                    onChanged: _onTagsChanged,
                                    enabled: !(editState.mapOrNull(saving: (_) => true) ?? false),
                                  ),
                                  const SizedBox(height: 20),
                                  EditProfileBioField(controller: _bioController),
                                ],
                              ),
                            ),
                            SizedBox(height: context.heightByContext(30)),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EditProfileEmailRow extends StatelessWidget {
  const _EditProfileEmailRow({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final value = email?.trim();
    final display = value != null && value.isNotEmpty ? value : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Email',
            style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: context.colors.fieldLabel),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: context.colors.fieldBackgroundDisabled,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.fieldBorder),
          ),
          child: Row(
            children: [
              Icon(AppIcons.mail.icon, size: 22, color: context.colors.fieldIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  display,
                  style: AppTextStyle.base(
                    16,
                    fontWeight: FontWeight.w500,
                    color: context.colors.fieldTextDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditProfileLoading extends StatelessWidget {
  const _EditProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EditProfileError extends StatelessWidget {
  const _EditProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
