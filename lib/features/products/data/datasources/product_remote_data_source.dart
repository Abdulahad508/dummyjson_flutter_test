import 'package:dio/dio.dart';
import 'package:dummyjson_flutter_test/core/network/json_map.dart';
import 'package:dummyjson_flutter_test/features/products/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductPageModel> getProducts({required int limit, required int skip});

  Future<ProductModel> getProduct(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ProductPageModel> getProducts({
    required int limit,
    required int skip,
  }) async {
    final response = await _dio.get<dynamic>(
      '/products',
      queryParameters: <String, dynamic>{'limit': limit, 'skip': skip},
    );
    return ProductPageModel.fromJson(asJsonMap(response.data));
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    final response = await _dio.get<dynamic>('/products/$id');
    return ProductModel.fromJson(asJsonMap(response.data));
  }
}
