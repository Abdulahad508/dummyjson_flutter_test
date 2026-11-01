import 'package:dummyjson_flutter_test/core/network/guard_request.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/data/datasources/product_remote_data_source.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Future<Result<ProductPage>> getProducts({
    required int limit,
    required int skip,
  }) {
    return guardRequest<ProductPage>(() async {
      return _remote.getProducts(limit: limit, skip: skip);
    });
  }

  @override
  Future<Result<Product>> getProduct(int id) {
    return guardRequest<Product>(() async {
      return _remote.getProduct(id);
    });
  }
}
