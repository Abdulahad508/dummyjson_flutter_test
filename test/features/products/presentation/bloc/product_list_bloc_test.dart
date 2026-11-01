import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/domain/usecases/product_usecases.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_list_bloc.dart';

import '../../../../support/samples.dart';

class MockGetProducts extends Mock implements GetProducts {}

void main() {
  late MockGetProducts getProducts;

  const firstPage = ProductPage(
    products: [sampleProduct],
    total: 2,
    skip: 0,
    limit: 10,
  );
  const lastPage = ProductPage(
    products: [secondProduct],
    total: 2,
    skip: 1,
    limit: 10,
  );

  setUp(() => getProducts = MockGetProducts());

  ProductListBloc buildBloc() => ProductListBloc(getProducts);

  blocTest<ProductListBloc, ProductListState>(
    'emits loading then the first page',
    build: buildBloc,
    setUp: () {
      when(
        () => getProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        ),
      ).thenAnswer((_) async => const Success(firstPage));
    },
    act: (bloc) => bloc.add(const ProductListStarted()),
    expect: () => [
      const ProductListState(status: ProductListStatus.loading),
      const ProductListState(
        status: ProductListStatus.success,
        products: [sampleProduct],
        total: 2,
      ),
    ],
    verify: (_) {
      verify(() => getProducts(limit: 10, skip: 0)).called(1);
    },
  );

  blocTest<ProductListBloc, ProductListState>(
    'shows a full-screen failure when the first page fails',
    build: buildBloc,
    setUp: () {
      when(
        () => getProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        ),
      ).thenAnswer(
        (_) async =>
            const ResultFailure(ServerFailure('Could not load products.')),
      );
    },
    act: (bloc) => bloc.add(const ProductListStarted()),
    expect: () => [
      const ProductListState(status: ProductListStatus.loading),
      const ProductListState(
        status: ProductListStatus.failure,
        errorMessage: 'Could not load products.',
      ),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'appends the next page until the total is reached',
    build: buildBloc,
    seed: () => const ProductListState(
      status: ProductListStatus.success,
      products: [sampleProduct],
      total: 2,
    ),
    setUp: () {
      when(
        () => getProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        ),
      ).thenAnswer((_) async => const Success(lastPage));
    },
    act: (bloc) => bloc.add(const ProductListLoadMoreRequested()),
    expect: () => [
      const ProductListState(
        status: ProductListStatus.success,
        products: [sampleProduct],
        total: 2,
        isLoadingMore: true,
      ),
      const ProductListState(
        status: ProductListStatus.success,
        products: [sampleProduct, secondProduct],
        total: 2,
        hasReachedMax: true,
      ),
    ],
    verify: (_) {
      verify(() => getProducts(limit: 10, skip: 1)).called(1);
    },
  );

  blocTest<ProductListBloc, ProductListState>(
    'does not request another page when everything is loaded',
    build: buildBloc,
    seed: () => const ProductListState(
      status: ProductListStatus.success,
      products: [sampleProduct],
      total: 1,
      hasReachedMax: true,
    ),
    act: (bloc) => bloc.add(const ProductListLoadMoreRequested()),
    expect: () => const <ProductListState>[],
    verify: (_) {
      verifyNever(
        () => getProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        ),
      );
    },
  );

  blocTest<ProductListBloc, ProductListState>(
    'keeps the current products when loading another page fails',
    build: buildBloc,
    seed: () => const ProductListState(
      status: ProductListStatus.success,
      products: [sampleProduct],
      total: 2,
    ),
    setUp: () {
      when(
        () => getProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        ),
      ).thenAnswer((_) async => const ResultFailure(NetworkFailure()));
    },
    act: (bloc) => bloc.add(const ProductListLoadMoreRequested()),
    expect: () => [
      const ProductListState(
        status: ProductListStatus.success,
        products: [sampleProduct],
        total: 2,
        isLoadingMore: true,
      ),
      const ProductListState(
        status: ProductListStatus.success,
        products: [sampleProduct],
        total: 2,
        errorMessage: 'Check your internet connection and try again.',
      ),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'refresh replaces the list and keeps it visible while loading',
    build: buildBloc,
    seed: () => const ProductListState(
      status: ProductListStatus.success,
      products: [sampleProduct],
      total: 1,
      hasReachedMax: true,
    ),
    setUp: () {
      when(
        () => getProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          ProductPage(products: [secondProduct], total: 1, skip: 0, limit: 10),
        ),
      );
    },
    act: (bloc) => bloc.add(const ProductListRefreshed()),
    expect: () => [
      const ProductListState(
        status: ProductListStatus.success,
        products: [sampleProduct],
        total: 1,
        hasReachedMax: true,
        isRefreshing: true,
      ),
      const ProductListState(
        status: ProductListStatus.success,
        products: [secondProduct],
        total: 1,
        hasReachedMax: true,
      ),
    ],
  );
}
