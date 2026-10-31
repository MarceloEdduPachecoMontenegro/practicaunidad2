// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

import '../../features/products/presentation/pages/products_page.dart';
import '../../features/products/presentation/pages/sales_page.dart';

final appRouter = GoRouter(
  initialLocation: '/products',
  routes: [
    GoRoute(path: '/products', name: 'products', builder: (_, __) => const ProductsPage()),
    GoRoute(path: '/sales',    name: 'sales',    builder: (_, __) => const SalesPage()),
  ],
);
