// lib/features/products/data/models/product_model.dart
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id, required super.name, required super.category,
    required super.price, required super.stock, required super.unit,
    required super.isActive, required super.updatedAt,
  });

  factory ProductModel.fromDrift(Product row) => ProductModel(
    id: row.id, name: row.name, category: row.category,
    price: row.price, stock: row.stock, unit: row.unit,
    isActive: row.isActive,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  ProductsCompanion toDriftCompanion() => ProductsCompanion.insert(
    name: name, category: category, price: price,
    stock: Value(stock), unit: Value(unit),
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
}

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id, required super.productId, required super.quantity,
    required super.unitPrice, required super.total,
    super.buyerName, required super.saleDate,
  });

  factory SaleModel.fromDrift(Sale row) => SaleModel(
    id: row.id, productId: row.productId,
    quantity: row.quantity, unitPrice: row.unitPrice, total: row.total,
    buyerName: row.buyerName,
    saleDate: DateTime.fromMillisecondsSinceEpoch(row.saleDate),
  );
}
