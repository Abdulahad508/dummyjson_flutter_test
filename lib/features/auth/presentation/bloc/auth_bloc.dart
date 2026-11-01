import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/network/session_notifier.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/entities/user.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/usecases/auth_usecases.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

enum AuthStatus { unknown, authenticated, unauthenticated, sessionError }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._login,
    required this._logout,
    required this._restoreSession,
    required SessionNotifier sessionNotifier,
  }) : super(const AuthState()) {
    _subscription = sessionNotifier.onUnauthorized.listen(
      (_) => add(const AuthSessionExpired()),
    );
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthLoginRequested>(_onLogin, transformer: droppable());
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onSessionExpired, transformer: droppable());
  }

  final Login _login;
  final Logout _logout;
  final RestoreSession _restoreSession;
  late final StreamSubscription<void> _subscription;

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final checking = state.copyWith(
      status: AuthStatus.unknown,
      isSubmitting: false,
      clearError: true,
      clearUser: true,
    );
    // Skip a no-op emit so a cold start does not look like a new state.
    if (checking != state) {
      emit(checking);
    }
    final result = await _restoreSession();
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Success(:final value):
        emit(AuthState(status: AuthStatus.authenticated, user: value));
      case ResultFailure(:final failure):
        if (failure is UnauthorizedFailure) {
          emit(const AuthState(status: AuthStatus.unauthenticated));
        } else {
          emit(
            AuthState(
              status: AuthStatus.sessionError,
              errorMessage: failure.message,
            ),
          );
        }
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final username = event.username.trim();
    if (username.isEmpty || event.password.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isSubmitting: false,
          errorMessage: 'Enter your username and password.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: true,
        clearError: true,
      ),
    );
    final result = await _login(username: username, password: event.password);
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Success(:final value):
        emit(AuthState(status: AuthStatus.authenticated, user: value));
      case ResultFailure(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            isSubmitting: false,
            errorMessage: failure.message,
            clearUser: true,
          ),
        );
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _logout();
    } catch (_) {
      // Leave the screen anyway so a storage failure cannot trap the user.
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _logout();
    } catch (_) {
      // The token is already rejected; still drop the local session.
    }
    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Your session has expired. Please sign in again.',
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
