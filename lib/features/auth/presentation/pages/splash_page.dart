import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/core/widgets/status_views.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.sessionError) {
            return ErrorView(
              message: state.errorMessage ?? 'Could not restore your session.',
              onRetry: () {
                context.read<AuthBloc>().add(const AuthSessionRequested());
              },
            );
          }
          return const LoadingView(message: 'Restoring your session...');
        },
      ),
    );
  }
}
