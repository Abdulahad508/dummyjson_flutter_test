import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dummyjson_flutter_test/app/injection.dart';
import 'package:dummyjson_flutter_test/core/widgets/status_views.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/pages/login_page.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/pages/splash_page.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/pages/product_detail_page.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/pages/product_list_page.dart';

GoRouter createRouter({
  required AuthBloc authBloc,
  required Listenable refreshListenable,
}) {
  // Product detail is a real route, so a push should show /products/:id
  // in the browser. The default leaves imperative pushes off the URL.
  if (kIsWeb) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
  }
  // A cold start redirects to the splash while the saved token is checked.
  // Remember the page the user actually opened so it is restored afterward.
  String? returnTo;
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final status = authBloc.state.status;
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final onLogin = location == '/login';

      if (status == AuthStatus.unknown || status == AuthStatus.sessionError) {
        if (!onSplash && !onLogin) {
          returnTo = location;
        }
        return onSplash ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        if (!onSplash && !onLogin) {
          returnTo = location;
        }
        return onLogin ? null : '/login';
      }
      if (onSplash || onLogin) {
        final next = returnTo;
        returnTo = null;
        return next ?? '/products';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/products',
        builder: (context, state) {
          return BlocProvider(
            create: (_) =>
                getIt<ProductListBloc>()..add(const ProductListStarted()),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, auth) {
                return ProductListPage(
                  userName: auth.user?.firstName,
                  onLogout: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                  onProductTap: (product) {
                    context.push('/products/${product.id}');
                  },
                );
              },
            ),
          );
        },
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const EmptyView(
                title: 'Product not found',
                message: 'This link does not point at a product.',
              ),
            );
          }
          return BlocProvider(
            create: (_) =>
                getIt<ProductDetailBloc>()..add(ProductDetailRequested(id)),
            child: ProductDetailPage(productId: id),
          );
        },
      ),
    ],
  );
}
