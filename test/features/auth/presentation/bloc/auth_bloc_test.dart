import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/network/session_notifier.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/usecases/auth_usecases.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../support/samples.dart';

class MockLogin extends Mock implements Login {}

class MockLogout extends Mock implements Logout {}

class MockRestoreSession extends Mock implements RestoreSession {}

void main() {
  late MockLogin login;
  late MockLogout logout;
  late MockRestoreSession restoreSession;
  late SessionNotifier sessionNotifier;

  setUp(() {
    login = MockLogin();
    logout = MockLogout();
    restoreSession = MockRestoreSession();
    sessionNotifier = SessionNotifier();
    when(() => logout()).thenAnswer((_) async {});
  });

  tearDown(() => sessionNotifier.dispose());

  AuthBloc buildBloc() {
    return AuthBloc(
      login: login,
      logout: logout,
      restoreSession: restoreSession,
      sessionNotifier: sessionNotifier,
    );
  }

  blocTest<AuthBloc, AuthState>(
    'restores an authenticated session',
    build: buildBloc,
    setUp: () {
      when(() => restoreSession())
          .thenAnswer((_) async => const Success(sampleUser));
    },
    act: (bloc) => bloc.add(const AuthSessionRequested()),
    expect: () => [
      const AuthState(status: AuthStatus.authenticated, user: sampleUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'sends the user to sign in when no session is stored',
    build: buildBloc,
    setUp: () {
      when(() => restoreSession())
          .thenAnswer((_) async => const ResultFailure(UnauthorizedFailure()));
    },
    act: (bloc) => bloc.add(const AuthSessionRequested()),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
  );

  blocTest<AuthBloc, AuthState>(
    'keeps the splash in an error state when restore fails offline',
    build: buildBloc,
    setUp: () {
      when(() => restoreSession())
          .thenAnswer((_) async => const ResultFailure(NetworkFailure()));
    },
    act: (bloc) => bloc.add(const AuthSessionRequested()),
    expect: () => [
      const AuthState(
        status: AuthStatus.sessionError,
        errorMessage: 'Check your internet connection and try again.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'login emits submitting then authenticated',
    build: buildBloc,
    setUp: () {
      when(
        () => login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(sampleUser));
    },
    seed: () => const AuthState(status: AuthStatus.unauthenticated),
    act: (bloc) => bloc.add(
      const AuthLoginRequested(username: 'emilys', password: 'emilyspass'),
    ),
    expect: () => [
      const AuthState(status: AuthStatus.unauthenticated, isSubmitting: true),
      const AuthState(status: AuthStatus.authenticated, user: sampleUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'login keeps the form up when credentials are rejected',
    build: buildBloc,
    setUp: () {
      when(
        () => login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const ResultFailure(ServerFailure('Invalid credentials')),
      );
    },
    seed: () => const AuthState(status: AuthStatus.unauthenticated),
    act: (bloc) => bloc.add(
      const AuthLoginRequested(username: 'emilys', password: 'wrong'),
    ),
    expect: () => [
      const AuthState(status: AuthStatus.unauthenticated, isSubmitting: true),
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Invalid credentials',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout clears the session',
    build: buildBloc,
    seed: () =>
        const AuthState(status: AuthStatus.authenticated, user: sampleUser),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
    verify: (_) {
      verify(() => logout()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'an expired session returns to sign in with a message',
    build: buildBloc,
    seed: () =>
        const AuthState(status: AuthStatus.authenticated, user: sampleUser),
    act: (bloc) => bloc.add(const AuthSessionExpired()),
    expect: () => [
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Your session has expired. Please sign in again.',
      ),
    ],
  );
}
