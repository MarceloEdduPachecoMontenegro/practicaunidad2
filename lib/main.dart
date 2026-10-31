// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const ProviderScope(child: MercadoFreshApp()));
}

class MercadoFreshApp extends StatelessWidget {
  const MercadoFreshApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MercadoFresh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
