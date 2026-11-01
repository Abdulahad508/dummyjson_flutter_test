import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/domain/usecases/product_usecases.dart';

sealed class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

final class ProductListStarted extends ProductListEvent {
  const ProductListStarted();
}

final class ProductListRefreshed extends ProductListEvent {
  const ProductListRefreshed();
}

final class ProductListLoadMoreRequested extends ProductListEvent {
  const ProductListLoadMoreRequested();
}

enum ProductListStatus { initial, loading, success, failure }

final class ProductListState extends Equatable {
  const ProductListState({
    this.status = ProductListStatus.initial,
    this.products = const [],
    this.total = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final ProductListStatus status;
  final List<Product> products;
  final int total;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? errorMessage;

  ProductListState copyWith({
    ProductListStatus? status,
    List<Product>? products,
    int? total,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductListState(
      status: status ?? this.status,
      products: products ?? this.products,
      total: total ?? this.total,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    total,
    hasReachedMax,
    isLoadingMore,
    isRefreshing,
    errorMessage,
  ];
}

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc(this._getProducts) : super(const ProductListState()) {
    on<ProductListStarted>(_onStarted, transformer: restartable());
    on<ProductListRefreshed>(_onRefreshed, transformer: restartable());
    on<ProductListLoadMoreRequested>(_onLoadMore, transformer: droppable());
  }

  final GetProducts _getProducts;

  static const pageSize = 10;

  /// Bumped by a full reload so an in-flight "load more" cannot overwrite it.
  int _generation = 0;

  Future<void> _onStarted(
    ProductListStarted event,
    Emitter<ProductListState> emit,
  ) {
    return _loadFirstPage(emit, refreshing: false);
  }

  Future<void> _onRefreshed(
    ProductListRefreshed event,
    Emitter<ProductListState> emit,
  ) {
    return _loadFirstPage(emit, refreshing: true);
  }

  Future<void> _loadFirstPage(
    Emitter<ProductListState> emit, {
    required bool refreshing,
  }) async {
    final generation = ++_generation;
    final keepVisible = refreshing && state.products.isNotEmpty;
    if (keepVisible) {
      emit(state.copyWith(isRefreshing: true, clearError: true));
    } else {
      emit(
        state.copyWith(
          status: ProductListStatus.loading,
          isRefreshing: refreshing,
          isLoadingMore: false,
          products: const [],
          hasReachedMax: false,
          clearError: true,
        ),
      );
    }

    final result = await _getProducts(limit: pageSize, skip: 0);
    if (emit.isDone || generation != _generation) {
      return;
    }

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ProductListStatus.success,
            products: value.products,
            total: value.total,
            hasReachedMax: _reachedEnd(
              fetchedCount: value.products.length,
              accumulatedCount: value.products.length,
              total: value.total,
            ),
            isRefreshing: false,
            isLoadingMore: false,
            clearError: true,
          ),
        );
      case ResultFailure(:final failure):
        emit(
          state.copyWith(
            status: state.products.isEmpty
                ? ProductListStatus.failure
                : state.status,
            isRefreshing: false,
            isLoadingMore: false,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onLoadMore(
    ProductListLoadMoreRequested event,
    Emitter<ProductListState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.isRefreshing ||
        state.status != ProductListStatus.success) {
      return;
    }

    final generation = _generation;
    final skip = state.products.length;
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final result = await _getProducts(limit: pageSize, skip: skip);
    if (emit.isDone || generation != _generation) {
      return;
    }

    switch (result) {
      case Success(:final value):
        final merged = [...state.products, ...value.products];
        emit(
          state.copyWith(
            status: ProductListStatus.success,
            products: merged,
            total: value.total,
            hasReachedMax: _reachedEnd(
              fetchedCount: value.products.length,
              accumulatedCount: merged.length,
              total: value.total,
            ),
            isLoadingMore: false,
            clearError: true,
          ),
        );
      case ResultFailure(:final failure):
        emit(
          state.copyWith(isLoadingMore: false, errorMessage: failure.message),
        );
    }
  }

  bool _reachedEnd({
    required int fetchedCount,
    required int accumulatedCount,
    required int total,
  }) {
    return fetchedCount == 0 || accumulatedCount >= total;
  }
}
