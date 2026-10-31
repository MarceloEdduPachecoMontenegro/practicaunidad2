// lib/features/products/data/repositories/product_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductsDao _dao;
  ProductRepositoryImpl(this._dao);

  @override
  Stream<List<ProductEntity>> watchAllProducts() =>
      _dao.watchAllProducts().map((r) => r.map(ProductModel.fromDrift).toList());

  @override
  Stream<List<ProductEntity>> watchActiveProducts() =>
      _dao.watchActiveProducts().map((r) => r.map(ProductModel.fromDrift).toList());

  @override
  Future<Either<Failure, ProductEntity>> addProduct({
    required String name,
    required String category,
    required double price,
    required double stock,
    required String unit,
  }) async {
    if (name.trim().isEmpty || price <= 0 || stock < 0) {
      return Left(ValidationFailure('Datos del producto inválidos'));
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final companion = ProductsCompanion(
        name: Value(name.trim()),
        category: Value(category),
        price: Value(price),
        stock: Value(stock),
        unit: Value(unit),
        updatedAt: Value(now),
      );

      final id = await _dao.insertProduct(companion);

      final productRow = Product(
        id: id,
        name: name.trim(),
        category: category,
        price: price,
        stock: stock,
        unit: unit,
        isActive: true,
        updatedAt: now,
      );

      return Right(ProductModel.fromDrift(productRow));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(
    int id, {
    String? name,
    String? category,
    double? price,
    double? stock,
    String? unit,
  }) async {
    try {
      final companion = ProductsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        price: price != null ? Value(price) : const Value.absent(),
        stock: stock != null ? Value(stock) : const Value.absent(),
        unit: unit != null ? Value(unit) : const Value.absent(),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );

      final updated = await _dao.updateProduct(id, companion);
      if (updated) {
        return const Right(null);
      } else {
        return Left(DatabaseFailure('No se encontró el producto para actualizar'));
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      await _dao.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

class SaleRepositoryImpl implements SaleRepository {
  final SalesDao _salesDao;
  final ProductsDao _productsDao;
  SaleRepositoryImpl(this._salesDao, this._productsDao);

  @override
  Stream<List<SaleEntity>> watchAllSales() =>
      _salesDao.watchAllSales().map((r) => r.map(SaleModel.fromDrift).toList());

  @override
  Future<Either<Failure, SaleEntity>> registerSale({
    required int productId,
    required double quantity,
    required double unitPrice,
    String? buyerName,
  }) async {
    try {
      final products = await _productsDao.getAllProducts();
      final productList = products.where((p) => p.id == productId);

      if (productList.isEmpty) {
        return Left(DatabaseFailure('Producto no encontrado'));
      }

      final product = productList.first;
      if (product.stock < quantity) {
        return Left(StockFailure('Stock insuficiente'));
      }

      final total = quantity * unitPrice;
      final saleDate = DateTime.now().millisecondsSinceEpoch;

      final companion = SalesCompanion(
        productId: Value(productId),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
        total: Value(total),
        buyerName: buyerName != null ? Value(buyerName) : const Value.absent(),
        saleDate: Value(saleDate),
      );

      final saleId = await _salesDao.insertSale(companion);
      await _productsDao.decrementStock(productId, quantity);

      final saleRow = Sale(
        id: saleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        total: total,
        buyerName: buyerName,
        saleDate: saleDate,
      );

      return Right(SaleModel.fromDrift(saleRow));
    } on StockFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalRevenue() async {
    try {
      final total = await _salesDao.getTotalRevenue();
      return Right(total);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}