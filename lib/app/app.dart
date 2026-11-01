import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/app/app_router.dart';
import 'package:dummyjson_flutter_test/app/app_theme.dart';
import 'package:dummyjson_flutter_test/app/go_router_refresh_stream.dart';
import 'package:dummyjson_flutter_test/app/injection.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final GoRouterRefreshStream _refresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _refresh = GoRouterRefreshStream(_authBloc.stream);
    _router = createRouter(authBloc: _authBloc, refreshListenable: _refresh);
    _authBloc.add(const AuthSessionRequested());
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Catalog',
        theme: AppTheme.light(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
