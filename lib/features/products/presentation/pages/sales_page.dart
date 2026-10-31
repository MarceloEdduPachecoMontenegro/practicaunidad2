// lib/features/products/presentation/pages/sales_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/products_controller.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    // TODO Q: Observar totalRevenueProvider para calcular el total dinámico
    final revenueAsync = ref.watch(totalRevenueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ventas del Día', style: TextStyle(fontWeight: FontWeight.bold)),
            // TODO Q: Mostrar "Total: S/ XX.XX" consumiendo totalRevenueProvider
            revenueAsync.when(
              data: (total) => Text(
                'Total: S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
              loading: () => const Text('Calculando total...', style: TextStyle(fontSize: 12)),
              error: (_, __) => const Text('Total: S/ 0.00', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('Sin ventas registradas'),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sales.length,
            itemBuilder: (_, i) {
              final s = sales[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.isLargeSale ? Colors.amber : const Color(0xFF1B5E20),
                    child: const Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text(s.formattedTotal,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('Producto #${s.productId} · ${s.quantity} uds'
                      '${s.buyerName != null ? ' · ${s.buyerName}' : ''}'),
                  trailing: s.isLargeSale
                      ? const Chip(label: Text('Venta grande'),
                          backgroundColor: Color(0xFFFFF9C4))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}