import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Опциональная привязка услуги записи — только если у профиля тег `booking`.
class PostCreateBookingServiceField extends StatefulWidget {
  const PostCreateBookingServiceField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<PostCreateBookingServiceField> createState() => _PostCreateBookingServiceFieldState();
}

class _PostCreateBookingServiceFieldState extends State<PostCreateBookingServiceField> {
  final _profileCubit = sl<ProfileCubit>();

  List<BookingService>? _services;
  bool _loadingServices = false;
  String? _servicesLoadedForProfileId;

  @override
  void initState() {
    super.initState();
    _ensureProfileLoaded();
  }

  void _ensureProfileLoaded() {
    _profileCubit.state.when(
      initial: () => _profileCubit.load(),
      loading: () {},
      loaded: (profile) {
        if (profile.hasAccountTags && profile.tags.isEmpty) {
          _profileCubit.refresh();
        } else if (profile.hasBookingTag) {
          _loadServicesIfNeeded(profile.id);
        }
      },
      error: (_) => _profileCubit.load(),
    );
  }

  Future<void> _loadServicesIfNeeded(String profileId) async {
    if (_loadingServices || _servicesLoadedForProfileId == profileId) return;

    setState(() => _loadingServices = true);
    try {
      final all = await sl<BookingServicesRepository>().listMyServices();
      if (!mounted) return;
      setState(() {
        _services = all.where((s) => s.isActive).toList(growable: false);
        _loadingServices = false;
        _servicesLoadedForProfileId = profileId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _services = const [];
        _loadingServices = false;
        _servicesLoadedForProfileId = profileId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      bloc: _profileCubit,
      builder: (context, state) {
        final profile = state.mapOrNull(loaded: (s) => s.profile);
        if (profile == null || !profile.hasBookingTag) {
          return const SizedBox.shrink();
        }

        if (_servicesLoadedForProfileId != profile.id && !_loadingServices) {
          _loadServicesIfNeeded(profile.id);
        }

        if (_loadingServices || _services == null) {
          return const SizedBox.shrink();
        }

        final services = _services!;
        if (services.isEmpty) {
          return AppSingleSelect<String?>(
            label: 'Услуга для записи',
            hint: 'Сначала создайте услугу в записях',
            sheetTitle: 'Услуга для записи',
            options: const [],
            value: null,
            onChanged: (_) {},
          );
        }

        final options = <AppSingleSelectOption<String?>>[
          const AppSingleSelectOption(value: null, label: 'Без услуги'),
          for (final service in services)
            AppSingleSelectOption(
              value: service.id,
              label: '${service.emojiText} ${service.title} · ${service.priceLabel}',
            ),
        ];

        return AppSingleSelect<String?>(
          label: 'Услуга для записи',
          hint: 'Не привязана',
          sheetTitle: 'Услуга для записи',
          options: options,
          value: widget.value,
          onChanged: widget.enabled ? widget.onChanged : (_) {},
        );
      },
    );
  }
}
