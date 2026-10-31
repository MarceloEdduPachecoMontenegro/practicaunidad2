// lib/core/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mercadofresh/core/errors/failures.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────
// TABLA: products  (productos del puesto de mercado)
// ─────────────────────────────────────────────────────
class Products extends Table {
  IntColumn  get id        => integer().autoIncrement()();
  TextColumn get name      => text().withLength(min: 1, max: 150)();
  TextColumn get category  => text()();
  RealColumn get price     => real()();              // precio por unidad
  RealColumn get stock     => real().withDefault(const Constant(0.0))(); // ERROR 1 (FALSO POSITIVO): Se mantiene RealColumn porque el stock admite decimales (kg, litros)
  TextColumn get unit      => text().withDefault(const Constant('kg'))(); // kg, unid, litro
  BoolColumn get isActive  => boolean().withDefault(const Constant(true))();
  IntColumn  get updatedAt => integer().named('updated_at')();
}

// ─────────────────────────────────────────────────────
// TABLA: sales  (ventas realizadas)
// ─────────────────────────────────────────────────────
class Sales extends Table {
  IntColumn  get id        => integer().autoIncrement()();
  IntColumn  get productId => integer().named('product_id').references(Products, #id)(); // ERROR 2: Llave foránea a la tabla Products
  RealColumn get quantity  => real()();
  RealColumn get unitPrice => real().named('unit_price')();
  RealColumn get total     => real()();              // quantity * unitPrice
  TextColumn get buyerName => text().named('buyer_name').nullable()();
  IntColumn  get saleDate  => integer().named('sale_date')();
}

// ─────────────────────────────────────────────────────
// DAO: ProductsDao
// ─────────────────────────────────────────────────────
@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  // ✅ COMPLETO
  Future<List<Product>> getAllProducts() => select(products).get();
  Stream<List<Product>> watchAllProducts() => select(products).watch();

  // ✅ COMPLETO — solo activos
  Stream<List<Product>> watchActiveProducts() =>
      (select(products)..where((p) => p.isActive.equals(true))).watch();

  // ERROR 3: Se corrigió para filtrar por 'category' en lugar de 'name'
  Future<List<Product>> getByCategory(String category) =>
      (select(products)..where((p) => p.category.equals(category))).get();

  // ✅ COMPLETO
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  // ERROR 4: Se implementó la actualización real escribiendo los datos y retornando si hubo cambios
  Future<bool> updateProduct(int id, ProductsCompanion data) async {
    final rows = await (update(products)..where((p) => p.id.equals(id))).write(data);
    return rows > 0;
  }

  // ERROR 5: Se agregó la validación para lanzar StockFailure si el stock es menor a la cantidad solicitada
  Future<void> decrementStock(int productId, double quantity) async {
    final product = await (select(products)
          ..where((p) => p.id.equals(productId)))
        .getSingle();

    if (product.stock < quantity) {
      throw StockFailure('Stock insuficiente para realizar la venta');
    }

    await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(stock: Value(product.stock - quantity)));
  }

  // ERROR 6: Se implementó la eliminación física del registro por id
  Future<int> deleteProduct(int id) {
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }
}

// ─────────────────────────────────────────────────────
// DAO: SalesDao
// ─────────────────────────────────────────────────────
@DriftAccessor(tables: [Sales])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Stream<List<Sale>> watchAllSales() => select(sales).watch();

  Future<List<Sale>> getSalesByProduct(int productId) =>
      (select(sales)..where((s) => s.productId.equals(productId))).get();

  // ERROR 7: Se corrigió para filtrar las ventas cuya fecha sea mayor o igual al inicio del día actual
  Future<List<Sale>> getTodaySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return (select(sales)..where((s) => s.saleDate.isBiggerOrEqualValue(startOfDay))).get();
  }

  // ✅ COMPLETO
  Future<int> insertSale(SalesCompanion sale) =>
      into(sales).insert(sale);

  // ERROR 8: Se implementó el cálculo acumulado sumando el campo total de todas las ventas
  Future<double> getTotalRevenue() async {
    final allSales = await select(sales).get();
    return allSales.fold<double>(0.0, (sum, sale) => sum + sale.total);
  }
}

// ─────────────────────────────────────────────────────
// AppDatabase
// ─────────────────────────────────────────────────────
@DriftDatabase(
  tables: [Products, Sales],
  daos:   [ProductsDao, SalesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement('PRAGMA journal_mode=WAL');
    },
  );

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'mercadofresh.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}