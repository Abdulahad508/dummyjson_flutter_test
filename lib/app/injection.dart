import 'package:get_it/get_it.dart';
import 'package:dummyjson_flutter_test/core/network/api_client.dart';
import 'package:dummyjson_flutter_test/core/network/session_notifier.dart';
import 'package:dummyjson_flutter_test/core/storage/secure_token_storage.dart';
import 'package:dummyjson_flutter_test/core/storage/token_storage.dart';
import 'package:dummyjson_flutter_test/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dummyjson_flutter_test/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/usecases/auth_usecases.dart';
import 'package:dummyjson_flutter_test/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/data/datasources/product_remote_data_source.dart';
import 'package:dummyjson_flutter_test/features/products/data/repositories/product_repository_impl.dart';
import 'package:dummyjson_flutter_test/features/products/domain/repositories/product_repository.dart';
import 'package:dummyjson_flutter_test/features/products/domain/usecases/product_usecases.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_list_bloc.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  if (getIt.isRegistered<SessionNotifier>()) {
    getIt.reset();
  }

  getIt.registerLazySingleton(
    SessionNotifier.new,
    dispose: (notifier) => notifier.dispose(),
  );
  getIt.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());
  getIt.registerLazySingleton(
    () => ApiClient(tokenStorage: getIt(), sessionNotifier: getIt()),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: getIt(), storage: getIt()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => Login(getIt()));
  getIt.registerLazySingleton(() => Logout(getIt()));
  getIt.registerLazySingleton(() => RestoreSession(getIt()));
  getIt.registerLazySingleton(() => GetProducts(getIt()));
  getIt.registerLazySingleton(() => GetProductDetail(getIt()));

  getIt.registerLazySingleton(
    () => AuthBloc(
      login: getIt(),
      logout: getIt(),
      restoreSession: getIt(),
      sessionNotifier: getIt(),
    ),
    dispose: (bloc) => bloc.close(),
  );
  getIt.registerFactory(() => ProductListBloc(getIt()));
  getIt.registerFactory(() => ProductDetailBloc(getIt()));
}
