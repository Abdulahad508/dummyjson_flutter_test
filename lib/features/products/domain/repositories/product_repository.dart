import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Result<ProductPage>> getProducts({
    required int limit,
    required int skip,
  });

  Future<Result<Product>> getProduct(int id);
}
