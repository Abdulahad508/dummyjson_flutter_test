import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/domain/repositories/product_repository.dart';

class GetProducts {
  const GetProducts(this._repository);

  final ProductRepository _repository;

  Future<Result<ProductPage>> call({required int limit, required int skip}) {
    return _repository.getProducts(limit: limit, skip: skip);
  }
}

class GetProductDetail {
  const GetProductDetail(this._repository);

  final ProductRepository _repository;

  Future<Result<Product>> call(int id) => _repository.getProduct(id);
}
