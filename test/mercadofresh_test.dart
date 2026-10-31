  // test/mercadofresh_test.dart
//
// ✅ TESTS PROVISTOS COMPLETOS — El estudiante NO debe modificar este archivo.
//    Solo debe ejecutarlos. Si fallan, hay errores en la implementación.
//
//  Para ejecutar:
//    flutter test test/mercadofresh_test.dart -v
//
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadofresh/core/database/app_database.dart';
import 'package:mercadofresh/features/products/domain/entities/product_entity.dart';
import 'package:mercadofresh/features/products/presentation/controllers/products_controller.dart';

ProductEntity _product({
  int id = 1, String name = 'Tomate', String category = 'VERDURAS',
  double price = 2.50, double stock = 10.0, String unit = 'kg',
  bool isActive = true,
}) => ProductEntity(
  id: id, name: name, category: category, price: price,
  stock: stock, unit: unit, isActive: isActive,
  updatedAt: DateTime(2024, 5, 1),
);

SaleEntity _sale({double total = 25.0}) => SaleEntity(
  id: 1, productId: 1, quantity: 10, unitPrice: 2.5, total: total,
  saleDate: DateTime.now(),
);

void main() {

  // ═══════════════════════════════════════════════════════
  // GRUPO 1 — ProductEntity: reglas de negocio
  // ═══════════════════════════════════════════════════════
  group('ProductEntity — reglas de negocio', () {

    test('isLowStock: stock=3 → true', () {
      expect(_product(stock: 3.0).isLowStock, isTrue);
    });

    test('isLowStock: stock=10 → false', () {
      expect(_product(stock: 10.0).isLowStock, isFalse);
    });

    test('isLowStock: stock exactamente 5 → true (límite)', () {
      expect(_product(stock: 5.0).isLowStock, isTrue);
    });

    test('stockLabel: "10.0 kg"', () {
      expect(_product(stock: 10.0, unit: 'kg').stockLabel, equals('10.0 kg'));
    });

    test('formattedPrice: "S/ 2.50"', () {
      expect(_product(price: 2.50).formattedPrice, equals('S/ 2.50'));
    });

    test('categoryDisplay: VERDURAS → "🥦 VERDURAS"', () {
      expect(_product(category: 'VERDURAS').categoryDisplay, equals('🥦 VERDURAS'));
    });

    test('categoryDisplay: FRUTAS → "🍎 FRUTAS"', () {
      expect(_product(category: 'FRUTAS').categoryDisplay, equals('🍎 FRUTAS'));
    });

    test('categoryDisplay: CARNES → "🥩 CARNES"', () {
      expect(_product(category: 'CARNES').categoryDisplay, equals('🥩 CARNES'));
    });

    test('categoryDisplay: categoría desconocida → "📦 OTRO"', () {
      expect(_product(category: 'OTRO').categoryDisplay, equals('📦 OTRO'));
    });
  });

  // ═══════════════════════════════════════════════════════
  // GRUPO 2 — SaleEntity: reglas de negocio
  // ═══════════════════════════════════════════════════════
  group('SaleEntity — reglas de negocio', () {

    test('isLargeSale: total=150 → true', () {
      expect(_sale(total: 150.0).isLargeSale, isTrue);
    });

    test('isLargeSale: total=50 → false', () {
      expect(_sale(total: 50.0).isLargeSale, isFalse);
    });

    test('formattedTotal: "S/ 25.00"', () {
      expect(_sale(total: 25.0).formattedTotal, equals('S/ 25.00'));
    });
  });

  // ═══════════════════════════════════════════════════════
  // GRUPO 3 — Drift in-memory: ProductsDao CRUD
  // ═══════════════════════════════════════════════════════
  group('ProductsDao — CRUD con BD en memoria', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() async => await db.close());

    test('INSERT + GET: insertar producto y recuperarlo', () async {
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Lechuga', category: 'VERDURAS', price: 1.50,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final all = await db.productsDao.getAllProducts();
      expect(all.length, 1);
      expect(all.first.name, 'Lechuga');
    });

    test('UPDATE: cambiar precio del producto', () async {
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Papa', category: 'VERDURAS', price: 1.00,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final p = (await db.productsDao.getAllProducts()).first;
      await db.productsDao.updateProduct(p.id,
          ProductsCompanion(price: const Value(1.80)));
      final after = await db.productsDao.getAllProducts();
      expect(after.first.price, closeTo(1.80, 0.001));
    });

    test('DELETE: eliminar producto', () async {
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Cilantro', category: 'VERDURAS', price: 0.50,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final p = (await db.productsDao.getAllProducts()).first;
      await db.productsDao.deleteProduct(p.id);
      expect(await db.productsDao.getAllProducts(), isEmpty);
    });

    test('getByCategory: filtra correctamente por FRUTAS', () async {
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Mango', category: 'FRUTAS', price: 1.5,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Cebolla', category: 'VERDURAS', price: 0.8,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final frutas = await db.productsDao.getByCategory('FRUTAS');
      expect(frutas.length, 1);
      expect(frutas.first.name, 'Mango');
    });

    test('decrementStock: no permite stock negativo', () async {
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Zanahoria', category: 'VERDURAS', price: 1.0,
        stock: const Value(3.0),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final p = (await db.productsDao.getAllProducts()).first;
      // Intentar decrementar más de lo disponible debe lanzar StockFailure o similar
      expect(
        () => db.productsDao.decrementStock(p.id, 10.0),
        throwsA(anything), // el estudiante debe manejar esto
      );
    });
  });

  // ═══════════════════════════════════════════════════════
  // GRUPO 4 — Drift in-memory: SalesDao
  // ═══════════════════════════════════════════════════════
  group('SalesDao — ventas con BD en memoria', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() async => await db.close());

    test('INSERT venta y recuperar del stream', () async {
      await db.salesDao.insertSale(SalesCompanion.insert(
        productId: 1, quantity: 2.0, unitPrice: 3.0, total: 6.0,
        saleDate: DateTime.now().millisecondsSinceEpoch,
      ));
      final sales = await db.salesDao.watchAllSales().first;
      expect(sales.length, 1);
      expect(sales.first.total, closeTo(6.0, 0.001));
    });

    test('getTotalRevenue: suma correctamente todas las ventas', () async {
      await db.salesDao.insertSale(SalesCompanion.insert(
        productId: 1, quantity: 1, unitPrice: 10, total: 10,
        saleDate: DateTime.now().millisecondsSinceEpoch,
      ));
      await db.salesDao.insertSale(SalesCompanion.insert(
        productId: 2, quantity: 2, unitPrice: 5, total: 10,
        saleDate: DateTime.now().millisecondsSinceEpoch,
      ));
      final revenue = await db.salesDao.getTotalRevenue();
      expect(revenue, closeTo(20.0, 0.001)); // ← falla si ERROR 8 no fue corregido
    });
  });

  // ═══════════════════════════════════════════════════════
  // GRUPO 5 — Riverpod: selectedCategoryProvider
  // ═══════════════════════════════════════════════════════
  group('selectedCategoryProvider', () {
    test('valor inicial es null', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(selectedCategoryProvider), isNull);
    });

    test('actualizar a FRUTAS', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(selectedCategoryProvider.notifier).state = 'FRUTAS';
      expect(c.read(selectedCategoryProvider), 'FRUTAS');
    });

    test('limpiar filtro a null', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(selectedCategoryProvider.notifier).state = 'CARNES';
      c.read(selectedCategoryProvider.notifier).state = null;
      expect(c.read(selectedCategoryProvider), isNull);
    });
  });
}
