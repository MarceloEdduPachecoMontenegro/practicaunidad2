# MercadoFresh · Código base — Tema B

**SIS048 – Desarrollo de Software II · Evaluación Práctica de la Unidad II · Semestre 2026-II**
Universidad Andina del Cusco · Ciclo VII

Proyecto Flutter de un puesto de mercado (inventario y ventas con descuento de stock) que se
entrega **con errores intencionales y métodos sin implementar**. No es una aplicación terminada:
es el punto de partida de la evaluación de 60 minutos.

> **Regla de oro:** el archivo `test/mercadofresh_test.dart` está completo y **no se modifica**.
> Si se altera, se anula el criterio de pruebas de la rúbrica.

---

## Requisitos

| Herramienta | Versión verificada |
|---|---|
| Flutter | 3.41.1 (stable) |
| Dart | 3.11.0 |
| drift | 2.34.4 |
| flutter_riverpod | 2.6.1 |
| get_it | 7.7.0 |
| dartz | 0.10.1 |

Las versiones quedan fijadas en `pubspec.lock`, que se incluye para que el proyecto resuelva
igual en cualquier máquina del laboratorio.

## Puesta en marcha

```bash
flutter pub get
dart run build_runner build          # genera lib/core/database/app_database.g.dart
flutter analyze
flutter test test/mercadofresh_test.dart -v
```

El ZIP **no incluye** `app_database.g.dart` a propósito: debe generarse después de corregir el
esquema.

## Qué está incompleto

| Archivo | Estado |
|---|---|
| `lib/core/database/app_database.dart` | 8 marcadores `// ❌ ERROR N`: **7 reales y 1 falso positivo** (ERROR 1) |
| `lib/features/products/domain/entities/product_entity.dart` | `// TODO A` a `// TODO F`: reglas de negocio |
| `lib/features/products/data/repositories/product_repository_impl.dart` | `// TODO F` a `// TODO H`: validaciones, `Either`, venta y descuento de stock |
| `lib/core/di/injection_container.dart` | `// TODO N`: registro de `SaleRepository` |
| `lib/features/products/presentation/controllers/products_controller.dart` | `// TODO I` a `// TODO M`: providers y controllers |
| `lib/features/products/presentation/pages/products_page.dart` | `// TODO O` y `// TODO P`: filtro y registro de venta |
| `lib/features/products/presentation/pages/sales_page.dart` | `// TODO Q`: total del día |

Las pantallas y los diálogos están completos: son andamiaje de interfaz, no forman parte del
ejercicio.

## Resultado esperado

```text
00:00 +22: All tests passed!
```

## Entrega

`ApellidoNombre_TemaB_SIS048_2026-II.zip`, con `lib/`, `test/` y `pubspec.yaml`. Sin `build/` ni
`.dart_tool/`.

## Integridad del ejercicio

`CHECKSUMS.txt` contiene el SHA-256 del archivo de pruebas y del `pubspec.yaml`. Si el hash del
test no coincide con el entregado, el docente aplica el criterio transversal correspondiente.
