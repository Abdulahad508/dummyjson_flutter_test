import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/domain/usecases/product_usecases.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

final class ProductDetailRequested extends ProductDetailEvent {
  const ProductDetailRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

enum ProductDetailStatus { initial, loading, success, failure }

final class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.errorMessage,
  });

  final ProductDetailStatus status;
  final Product? product;
  final String? errorMessage;

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, product, errorMessage];
}

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._getProductDetail)
    : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested, transformer: restartable());
  }

  final GetProductDetail _getProductDetail;

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductDetailStatus.loading, clearError: true));
    final result = await _getProductDetail(event.id);
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ProductDetailStatus.success,
            product: value,
            clearError: true,
          ),
        );
      case ResultFailure(:final failure):
        emit(
          state.copyWith(
            status: ProductDetailStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
