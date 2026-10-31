// lib/core/database/app_database.dart / injection_container.dart
import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerSingleton<AppDatabase>(AppDatabase());
  sl.registerSingleton<ProductsDao>(sl<AppDatabase>().productsDao);
  sl.registerSingleton<SalesDao>(sl<AppDatabase>().salesDao);

  sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(sl<ProductsDao>()));
      
  // TODO N: Registro de SaleRepository en el contenedor de dependencias
  sl.registerLazySingleton<SaleRepository>(
      () => SaleRepositoryImpl(sl<SalesDao>(), sl<ProductsDao>()));
}