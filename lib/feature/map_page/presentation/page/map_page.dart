import 'package:auto_route/auto_route.dart';
import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          TextButton(onPressed: () => context.read<AuthCubit>().logout(), child: const Text('Выйти')),
        ],
      ),
      body: AppButton(text: 'asd', onTap: () {}),
    );
  }
}
