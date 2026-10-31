// lib/features/products/presentation/pages/products_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/product_entity.dart';
import '../controllers/products_controller.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  static const _categories = ['VERDURAS', 'FRUTAS', 'CARNES', 'LÁCTEOS', 'GRANOS'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO O: Usar filteredProductsProvider para la vista reactiva con filtros
    final productsAsync = ref.watch(filteredProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('MercadoFresh 🌱', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale),
            tooltip: 'Ventas',
            onPressed: () => context.push('/sales'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de categorías
          Container(
            height: 46,
            color: const Color(0xFFE8F5E9),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                _filterChip('Todos', ref.watch(selectedCategoryProvider) == null,
                    () => ref.read(selectedCategoryProvider.notifier).state = null),
                ..._categories.map((c) => _filterChip(
                    c, ref.watch(selectedCategoryProvider) == c,
                    () => ref.read(selectedCategoryProvider.notifier).state = c)),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.store, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Sin productos. Agrega con el botón +', textAlign: TextAlign.center),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.isLowStock
                              ? Colors.orange
                              : const Color(0xFF1B5E20),
                          child: Text(p.categoryDisplay.split(' ').first,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${p.formattedPrice} / ${p.unit}'),
                          Text(
                            p.stockLabel + (p.isLowStock ? '  ⚠️ Stock bajo' : ''),
                            style: TextStyle(color: p.isLowStock ? Colors.orange : Colors.green),
                          ),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.sell_outlined, color: Colors.blue),
                            tooltip: 'Registrar venta',
                            onPressed: () => _showSaleDialog(context, ref, p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              ref.read(productsControllerProvider.notifier).deleteProduct(p.id);
                            },
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Producto'),
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1B5E20)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : const Color(0xFF1B5E20),
          fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String category = 'VERDURAS', unit = 'kg';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: const Text('Agregar producto'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio (S/) *')),
          TextField(controller: stockCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock *')),
          DropdownButtonFormField<String>(
            initialValue: category,
            items: ['VERDURAS','FRUTAS','CARNES','LÁCTEOS','GRANOS']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => category = v!),
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          DropdownButtonFormField<String>(
            initialValue: unit,
            items: ['kg','unid','litro']
                .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => unit = v!),
            decoration: const InputDecoration(labelText: 'Unidad'),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            try {
              await ref.read(productsControllerProvider.notifier).addProduct(
                name: nameCtrl.text.trim(), category: category,
                price: double.tryParse(priceCtrl.text) ?? 0,
                stock: double.tryParse(stockCtrl.text) ?? 0, unit: unit,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
            }
          }, child: const Text('Agregar')),
        ],
      )),
    );
  }

  void _showSaleDialog(BuildContext context, WidgetRef ref, ProductEntity p) {
    final qtyCtrl   = TextEditingController();
    final buyerCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Vender: ${p.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Stock: ${p.stockLabel}  |  ${p.formattedPrice}/${p.unit}'),
          const SizedBox(height: 8),
          TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad')),
          TextField(controller: buyerCtrl,
              decoration: const InputDecoration(labelText: 'Comprador (opcional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            // TODO P: Implementación de la llamada a registerSale con manejo de errores
            final qty = double.tryParse(qtyCtrl.text) ?? 0;
            final buyer = buyerCtrl.text.trim().isEmpty ? null : buyerCtrl.text.trim();
            try {
              await ref.read(salesControllerProvider.notifier).registerSale(
                    productId: p.id,
                    quantity: qty,
                    unitPrice: p.price,
                    buyer: buyer,
                  );
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            } catch (e) {
              if (dialogCtx.mounted) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }, child: const Text('Registrar')),
        ],
      ),
    );
  }
}