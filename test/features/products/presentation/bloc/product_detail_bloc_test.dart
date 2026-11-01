import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/usecases/product_usecases.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_detail_bloc.dart';

import '../../../../support/samples.dart';

class MockGetProductDetail extends Mock implements GetProductDetail {}

void main() {
  late MockGetProductDetail getProductDetail;

  setUp(() => getProductDetail = MockGetProductDetail());

  blocTest<ProductDetailBloc, ProductDetailState>(
    'loads a product',
    build: () => ProductDetailBloc(getProductDetail),
    setUp: () {
      when(() => getProductDetail(any()))
          .thenAnswer((_) async => const Success(sampleProduct));
    },
    act: (bloc) => bloc.add(const ProductDetailRequested(1)),
    expect: () => [
      const ProductDetailState(status: ProductDetailStatus.loading),
      const ProductDetailState(
        status: ProductDetailStatus.success,
        product: sampleProduct,
      ),
    ],
  );

  blocTest<ProductDetailBloc, ProductDetailState>(
    'exposes a failure when the product cannot be loaded',
    build: () => ProductDetailBloc(getProductDetail),
    setUp: () {
      when(() => getProductDetail(any())).thenAnswer(
        (_) async => const ResultFailure(ServerFailure('Product not found.')),
      );
    },
    act: (bloc) => bloc.add(const ProductDetailRequested(99)),
    expect: () => [
      const ProductDetailState(status: ProductDetailStatus.loading),
      const ProductDetailState(
        status: ProductDetailStatus.failure,
        errorMessage: 'Product not found.',
      ),
    ],
  );
}
