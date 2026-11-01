import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummyjson_flutter_test/features/products/data/datasources/product_remote_data_source.dart';

void main() {
  test('requests a product page with limit and skip', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/products');
          expect(options.queryParameters['limit'], 10);
          expect(options.queryParameters['skip'], 20);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'products': [
                  {
                    'id': 21,
                    'title': 'Page two',
                    'description': 'Item',
                    'category': 'beauty',
                    'price': 5,
                    'discountPercentage': 0,
                    'rating': 4,
                    'stock': 3,
                    'thumbnail': '',
                    'images': <String>[],
                    'availabilityStatus': 'In Stock',
                  },
                ],
                'total': 194,
                'skip': 20,
                'limit': 10,
              },
            ),
          );
        },
      ),
    );

    final page = await ProductRemoteDataSourceImpl(dio)
        .getProducts(limit: 10, skip: 20);

    expect(page.total, 194);
    expect(page.products.single.id, 21);
  });

  test('requests one product by id', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/products/7');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 7,
                'title': 'Detail',
                'description': 'Full description',
                'category': 'groceries',
                'price': 3.5,
                'discountPercentage': 1,
                'rating': 4.5,
                'stock': 8,
                'thumbnail': '',
                'images': <String>[],
                'availabilityStatus': 'In Stock',
              },
            ),
          );
        },
      ),
    );

    final product = await ProductRemoteDataSourceImpl(dio).getProduct(7);

    expect(product.title, 'Detail');
    expect(product.description, 'Full description');
  });
}
