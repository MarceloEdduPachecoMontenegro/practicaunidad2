// ══════════════════════════════════════════════════════
// lib/features/products/domain/repositories/product_repository.dart  ✅ COMPLETO
// ══════════════════════════════════════════════════════
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Stream<List<ProductEntity>> watchAllProducts();
  Stream<List<ProductEntity>> watchActiveProducts();
  Future<Either<Failure, ProductEntity>> addProduct({
    required String name, required String category,
    required double price, required double stock, required String unit,
  });
  Future<Either<Failure, void>> updateProduct(int id, {
    String? name, String? category, double? price,
    double? stock, String? unit,
  });
  Future<Either<Failure, void>> deleteProduct(int id);
}

abstract class SaleRepository {
  Stream<List<SaleEntity>> watchAllSales();
  Future<Either<Failure, SaleEntity>> registerSale({
    required int productId,
    required double quantity,
    required double unitPrice,
    String? buyerName,
  });
  Future<Either<Failure, double>> getTotalRevenue();
}
