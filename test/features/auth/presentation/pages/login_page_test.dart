import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dummyjson_flutter_test/core/network/session_notifier.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/entities/user.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/usecases/auth_usecases.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/pages/login_page.dart';

import '../../../../support/samples.dart';

class MockLogin extends Mock implements Login {}

class MockLogout extends Mock implements Logout {}

class MockRestoreSession extends Mock implements RestoreSession {}

void main() {
  late MockLogin login;
  late AuthBloc bloc;

  setUp(() {
    login = MockLogin();
    final notifier = SessionNotifier();
    bloc = AuthBloc(
      login: login,
      logout: MockLogout(),
      restoreSession: MockRestoreSession(),
      sessionNotifier: notifier,
    );
    addTearDown(() async {
      await bloc.close();
      await notifier.dispose();
    });
  });

  Future<void> pumpLogin(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const LoginPage()),
      ),
    );
  }

  testWidgets('shows validation when the form is empty', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('submits the test account', (tester) async {
    final result = Completer<Result<User>>();
    when(
      () => login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => result.future);
    await pumpLogin(tester);

    await tester.tap(find.text('Fill test account'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    verify(() => login(username: 'emilys', password: 'emilyspass')).called(1);

    result.complete(const Success(sampleUser));
    await tester.pump();

    expect(bloc.state.status, AuthStatus.authenticated);
    expect(find.text('Test account: emilys / emilyspass'), findsOneWidget);
  });
}
