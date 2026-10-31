import 'package:equatable/equatable.dart';

/// Entidad pura de dominio que representa un producto del inventario
class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String category;
  final double price;
  final double stock;
  final String unit;
  final bool isActive;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.unit,
    required this.isActive,
    required this.updatedAt,
  });

  // TODO A: ProductEntity.isLowStock
  /// Devuelve true si el stock es menor o igual a 5.0 (límite incluido)
  bool get isLowStock => stock <= 5.0;

  // TODO B: ProductEntity.stockLabel
  /// Retorna la etiqueta formateada del stock con su unidad (ej. "10.0 kg")
  String get stockLabel => '$stock $unit';

  // TODO C: ProductEntity.formattedPrice
  /// Retorna el precio formateado en Soles con 2 decimales (ej. "S/ 2.50")
  String get formattedPrice => 'S/ ${price.toStringAsFixed(2)}';

  // TODO D: ProductEntity.categoryDisplay
  /// Retorna el nombre de la categoría en formato amigable con su emoji
  String get categoryDisplay {
    switch (category.toUpperCase()) {
      case 'VERDURAS':
        return '🥦 VERDURAS';
      case 'FRUTAS':
        return '🍎 FRUTAS';
      case 'CARNES':
        return '🥩 CARNES';
      default:
        return '📦 $category';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        price,
        stock,
        unit,
        isActive,
        updatedAt,
      ];
}

/// Entidad pura de dominio que representa una venta realizada
class SaleEntity extends Equatable {
  final int id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? buyerName;
  final DateTime saleDate;

  const SaleEntity({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.buyerName,
    required this.saleDate,
  });

  // TODO E: SaleEntity.isLargeSale
  /// Devuelve true si el monto total de la venta supera los 100.0 Soles
  bool get isLargeSale => total > 100.0;

  // TODO F: SaleEntity.formattedTotal
  /// Retorna el total formateado en Soles con 2 decimales (ej. "S/ 120.50")
  String get formattedTotal => 'S/ ${total.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
        id,
        productId,
        quantity,
        unitPrice,
        total,
        buyerName,
        saleDate,
      ];
}