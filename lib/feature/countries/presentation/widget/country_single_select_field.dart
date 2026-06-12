// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:side_project/feature/countries/data/models/country_code.dart';
// import 'package:side_project/core/resources/color_settings/app_colors.dart';
// import 'package:side_project/core/resources/text_settings/app_text_style.dart';
// import 'package:side_project/core/shared/app_single_select.dart';
// import 'package:side_project/feature/countries/presentation/cubit/countries_cubit.dart';

// /// Одиночный выбор страны: данные с бэка через [CountriesCubit].
// class CountrySingleSelectField extends StatefulWidget {
//   const CountrySingleSelectField({
//     super.key,
//     this.label,
//     required this.hint,
//     required this.value,
//     required this.onChanged,
//     this.searchHint = 'Поиск',
//     this.sheetTitle,
//   });

//   final String? label;
//   final String hint;
//   final String? value;
//   final ValueChanged<String> onChanged;
//   final String searchHint;
//   final String? sheetTitle;

//   @override
//   State<CountrySingleSelectField> createState() => _CountrySingleSelectFieldState();
// }

// class _CountrySingleSelectFieldState extends State<CountrySingleSelectField> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       _ensureLoaded();
//     });
//   }

//   void _ensureLoaded() {
//     final cubit = context.read<CountriesCubit>();
//     final hasData = cubit.state.maybeWhen(loaded: (_) => true, orElse: () => false);
//     if (hasData) return;
//     final inFlight = cubit.state.maybeWhen(loading: () => true, orElse: () => false);
//     if (inFlight) return;
//     cubit.load();
//   }

//   String? _normalize(String? code) {
//     if (code == null || code.trim().isEmpty) return null;
//     return code.trim().toLowerCase();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<CountriesCubit, CountriesState>(
//       builder: (context, state) {
//         return state.when(
//           initial: _skeleton,
//           loading: _skeleton,
//           error: (message) => _error(message),
//           loaded: (items) {
//             final options = items
//                 .map(
//                   (c) => AppSingleSelectOption<String>(
//                     value: c.code.trim().toLowerCase(),
//                     label: CountryCode.tryParse(c.code)?.labelRu ?? c.code,
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
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               color: AppColors.primary.withValues(alpha: 0.85),
//             ),
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
//           onPressed: () => context.read<CountriesCubit>().load(),
//           child: Text(
//             'Повторить',
//             style: AppTextStyle.base(15, color: AppColors.primary, fontWeight: FontWeight.w600),
//           ),
//         ),
//       ],
//     );
//   }
// }
