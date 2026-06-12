// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:side_project/core/resources/color_settings/app_colors.dart';
// import 'package:side_project/core/resources/text_settings/app_text_style.dart';
// import 'package:side_project/core/shared/app_single_select.dart';
// import 'package:side_project/feature/cities/presentation/cubit/cities_cubit.dart';

// /// Одиночный выбор города: данные с бэка через [CitiesCubit] для выбранной страны [countryCode].
// class CitySingleSelectField extends StatefulWidget {
//   const CitySingleSelectField({
//     super.key,
//     this.label,
//     required this.hint,
//     required this.countryCode,
//     required this.value,
//     required this.onChanged,
//     this.searchHint = 'Поиск',
//     this.sheetTitle,
//   });

//   final String? label;
//   final String hint;

//   /// Код страны (`kz`, `ru`, …).
//   final String? countryCode;
//   final String? value;
//   final ValueChanged<String> onChanged;
//   final String searchHint;
//   final String? sheetTitle;

//   @override
//   State<CitySingleSelectField> createState() => _CitySingleSelectFieldState();
// }

// class _CitySingleSelectFieldState extends State<CitySingleSelectField> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
//   }

//   @override
//   void didUpdateWidget(CitySingleSelectField oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.countryCode != oldWidget.countryCode) {
//       _loadIfNeeded();
//     }
//   }

//   void _loadIfNeeded() {
//     final c = widget.countryCode?.trim() ?? '';
//     if (c.isEmpty) return;
//     final cubit = context.read<CitiesCubit>();
//     final want = c.toLowerCase();
//     final alreadyForCountry = cubit.state.maybeWhen(
//       loaded: (cc, _) => cc.trim().toLowerCase() == want,
//       orElse: () => false,
//     );
//     if (alreadyForCountry) return;
//     cubit.load(c);
//   }

//   String? _normalize(String? code) {
//     if (code == null || code.trim().isEmpty) return null;
//     return code.trim();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final country = widget.countryCode?.trim() ?? '';
//     if (country.isEmpty) {
//       return _disabledPlaceholder('Сначала выберите страну');
//     }

//     return BlocBuilder<CitiesCubit, CitiesState>(
//       builder: (context, state) {
//         return state.when(
//           initial: () => _skeleton(),
//           loading: () => _skeleton(),
//           error: (message) => _error(message),
//           loaded: (loadedCountry, items) {
//             final cc = loadedCountry.trim().toLowerCase();
//             if (cc != country.toLowerCase()) {
//               return _skeleton();
//             }
//             final options = items
//                 .map(
//                   (city) => AppSingleSelectOption<String>(
//                     value: city.cityCode.trim(),
//                     label: city.asEnum?.labelRu ?? '${city.cityCode} · ${city.countryCode}',
//                   ),
//                 )
//                 .toList();
//             return AppSingleSelect<String>(
//               label: widget.label,
//               hint: widget.hint,
//               options: options,
//               value: _normalize(widget.value),
//               onChanged: widget.onChanged,
//               searchHint: widget.searchHint,
//               sheetTitle: widget.sheetTitle,
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _disabledPlaceholder(String text) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (widget.label != null) ...[
//           Text(
//             widget.label!,
//             style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//         ],
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           decoration: BoxDecoration(
//             color: AppColors.inputBackground,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppColors.inputBorder),
//           ),
//           child: Text(
//             text,
//             style: AppTextStyle.base(16, color: AppColors.subTextColor.withValues(alpha: 0.55), height: 1.25),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _skeleton() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (widget.label != null) ...[
//           Text(
//             widget.label!,
//             style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//         ],
//         Container(
//           height: 56,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: AppColors.inputBackground,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppColors.inputBorder),
//           ),
//           child: SizedBox(
//             width: 22,
//             height: 22,
//             child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withValues(alpha: 0.85)),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _error(String message) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (widget.label != null) ...[
//           Text(
//             widget.label!,
//             style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//         ],
//         Text(message, style: AppTextStyle.base(13, color: AppColors.error, height: 1.35)),
//         const SizedBox(height: 8),
//         TextButton(
//           onPressed: () {
//             final c = widget.countryCode?.trim() ?? '';
//             if (c.isEmpty) return;
//             context.read<CitiesCubit>().load(c);
//           },
//           child: Text(
//             'Повторить',
//             style: AppTextStyle.base(15, color: AppColors.primary, fontWeight: FontWeight.w600),
//           ),
//         ),
//       ],
//     );
//   }
// }
