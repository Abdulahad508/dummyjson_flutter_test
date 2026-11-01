import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/domain/usecases/product_usecases.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/pages/product_list_page.dart';

import '../../../../support/samples.dart';

class MockGetProducts extends Mock implements GetProducts {}

void main() {
  late MockGetProducts getProducts;

  setUp(() => getProducts = MockGetProducts());

  Future<void> pumpPage(
    WidgetTester tester, {
    required ProductListBloc bloc,
    ValueChanged<int>? onTap,
    VoidCallback? onLogout,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: ProductListPage(
            userName: 'Emily',
            onLogout: onLogout,
            onProductTap: (product) => onTap?.call(product.id),
          ),
        ),
      ),
    );
  }

  testWidgets('shows an empty state', (tester) async {
    final result = Completer<Result<ProductPage>>();
    when(
      () => getProducts(
        limit: any(named: 'limit'),
        skip: any(named: 'skip'),
      ),
    ).thenAnswer((_) => result.future);
    final bloc = ProductListBloc(getProducts);
    await pumpPage(tester, bloc: bloc);
    bloc.add(const ProductListStarted());
    await tester.pump();

    expect(find.text('Loading products...'), findsOneWidget);

    result.complete(
      const Success(ProductPage(products: [], total: 0, skip: 0, limit: 10)),
    );
    await tester.pump();

    expect(find.text('No products'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows an error and retries', (tester) async {
    final calls = <Completer<Result<ProductPage>>>[];
    when(
      () => getProducts(
        limit: any(named: 'limit'),
        skip: any(named: 'skip'),
      ),
    ).thenAnswer((_) {
      final completer = Completer<Result<ProductPage>>();
      calls.add(completer);
      return completer.future;
    });
    final bloc = ProductListBloc(getProducts);
    await pumpPage(tester, bloc: bloc);
    bloc.add(const ProductListStarted());
    await tester.pump();
    calls.single.complete(
      const ResultFailure(ServerFailure('Could not load products.')),
    );
    await tester.pump();

    expect(find.text('Could not load products.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    calls.last.complete(
      const Success(
        ProductPage(products: [sampleProduct], total: 1, skip: 0, limit: 10),
      ),
    );
    await tester.pump();

    expect(find.text('Essence Mascara'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens a product and logs out', (tester) async {
    final result = Completer<Result<ProductPage>>();
    when(
      () => getProducts(
        limit: any(named: 'limit'),
        skip: any(named: 'skip'),
      ),
    ).thenAnswer((_) => result.future);
    final bloc = ProductListBloc(getProducts);
    var tappedId = 0;
    var loggedOut = false;
    await pumpPage(
      tester,
      bloc: bloc,
      onTap: (id) => tappedId = id,
      onLogout: () => loggedOut = true,
    );
    bloc.add(const ProductListStarted());
    await tester.pump();
    result.complete(
      const Success(
        ProductPage(products: [sampleProduct], total: 1, skip: 0, limit: 10),
      ),
    );
    await tester.pump();

    expect(find.text('Emily'), findsOneWidget);
    await tester.tap(find.text('Essence Mascara'));
    await tester.pump();
    expect(tappedId, 1);

    await tester.tap(find.byKey(const Key('logoutButton')));
    expect(loggedOut, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
