import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/_venue_/shared/data/venue_mock_catalog.dart';
import 'package:flutter/material.dart';

/// Акцент продукта «Бронь» — soft coral `#FFA39E`.
const AppServiceKind kVenueService = AppServiceKind.venue;

AppServiceAccent venueServiceAccent(AppPalette colors) => colors.serviceAccent(kVenueService);

Color venueStateSoft(AppPalette colors, VenueMockBookableState state) => switch (state) {
  VenueMockBookableState.free => colors.functionalSoftVenue,
  VenueMockBookableState.held => colors.functionalSoftYellow,
  VenueMockBookableState.taken => colors.functionalSoftRed,
};

Color venueStateInk(AppPalette colors, VenueMockBookableState state) => switch (state) {
  VenueMockBookableState.free => colors.functionalSoftVenueIcon,
  VenueMockBookableState.held => colors.functionalSoftYellowIcon,
  VenueMockBookableState.taken => colors.functionalSoftRedIcon,
};

class VenuePrimaryButton extends StatelessWidget {
  const VenuePrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isExpanded = true,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isExpanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onTap: onTap,
      service: kVenueService,
      isExpanded: isExpanded,
      isLoading: isLoading,
    );
  }
}
