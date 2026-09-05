import 'package:clover/core/auth/cubit/auth_cubit.dart';
import 'package:clover/core/auth/cubit/auth_state.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/resources.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'или'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: context.colors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.widthByContext(16)),
          child: Text(
            label,
            style: AppTextStyle.base(12, color: context.colors.subTextColor, letterSpacing: 0.6),
          ),
        ),
        Expanded(child: Container(height: 1, color: context.colors.border)),
      ],
    );
  }
}

class AuthGoogleSignInButton extends StatelessWidget {
  const AuthGoogleSignInButton({
    super.key,
    this.label = 'Continue with Google',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthCubit, bool>((c) => c.state is AuthLoading);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : () => context.read<AuthCubit>().loginWithGoogle(),
        style: OutlinedButton.styleFrom(
          backgroundColor: context.colors.surface,
          side: BorderSide(color: context.colors.borderInput),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(AppSvg.google, height: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: context.colors.textColor),
                  ),
                ],
              ),
      ),
    );
  }
}
