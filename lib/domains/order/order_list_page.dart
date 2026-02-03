import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/services/printer_service.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/auth/auth_controller.dart';
import 'package:edifly_pos/domains/order/models/order_detail_model.dart';
import 'package:edifly_pos/domains/order/models/order_list_model.dart';
import 'package:edifly_pos/domains/order/order_list_controller.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:edifly_pos/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderListController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          /// Top Bar
          TopBar(
            // userName: 'Kasir', // Bisa ambil dari AuthController jika ada
            menus: [
              TopBarMenuModel(
                label: 'Transaksi',
                icon: Icons.shopping_cart_outlined,
                isActive: false,
                onTap: () {
                  Get.back(); // Kembali ke halaman Order (Menu)
                },
              ),
              TopBarMenuModel(
                label: 'Daftar Pesanan',
                icon: Icons.receipt_long,
                isActive: true, // Halaman ini
                onTap: () {
                  // Stay here
                },
              ),
              TopBarMenuModel(
                label: 'Tutup Shift',
                icon: Icons.lock,
                onTap: () {
                  Get.toNamed(Routes.closingShift);
                },
              ),
              TopBarMenuModel(
                label: 'Atur Printer',
                icon: Icons.print,
                onTap: () {
                  Get.toNamed(Routes.printSettings);
                },
              ),
            ],
            onLogout: () {
              final authController = Get.put(AuthController());
              authController.logout();
            },
          ),

          /// Search Bar Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => controller.searchOrder(val),
                    decoration: InputDecoration(
                      hintText: 'Cari No. Order / Nama Customer...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => controller.fetchOrders(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  color: const Color(0xFF5B3A1E),
                ),
              ],
            ),
          ),

          /// Order List Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final displayOrders = controller.filteredOrders;

              if (displayOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'Pesanan tidak ditemukan'
                            : 'Belum ada pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          controller.searchOrder(''); // Clear search
                          controller.fetchOrders();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayOrders.length,
                  itemBuilder: (context, index) {
                    final order = displayOrders[index];
                    return _OrderCard(
                      order: order,
                      onTap: () => _showOrderDetail(context, controller, order),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(
    BuildContext context,
    OrderListController controller,
    OrderListItemModel order,
  ) {
    controller.fetchOrderDetail(order.orderId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailSheet(controller: controller),
    );
  }
}

/// Order Card Widget
class _OrderCard extends StatelessWidget {
  final OrderListItemModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Order Number
                  Text(
                    order.orderNo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B3A1E),
                    ),
                  ),

                  /// Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: order.isCompleted ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Date & Payment
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(order.tglOrder, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Icon(Icons.payment, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    order.pembayaranVia.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// Customer & Source Info
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${order.customerName} (Antrian: ${order.queueNumber})",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.store, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Sumber: ${order.sumber.toUpperCase()}",
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Spacer(),
                        const Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${order.jumlahItem} Item",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// Divider
              Divider(height: 1, color: Colors.grey.shade200),

              const SizedBox(height: 12),

              /// Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(
                    formatRupiah(order.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B3A1E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Order Detail Bottom Sheet
class _OrderDetailSheet extends StatelessWidget {
  final OrderListController controller;

  const _OrderDetailSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Obx(() {
        if (controller.isLoadingDetail.value) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final order = controller.selectedOrder.value;
        if (order == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Gagal memuat detail pesanan')),
          );
        }

        return Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120), // Space for footer
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.orderNo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5B3A1E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.tglOrder,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      order.isCompleted
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        order.isCompleted
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Customer & Source Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 14, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Nama Customer",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${order.customerName} (Antrian: ${order.queueNumber})",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: Colors.grey.shade200),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.store, size: 14, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Sumber Pesanan",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const Spacer(),
                                    Text(
                                      order.sumber.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Payment Method
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.payment, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Metode Pembayaran: ',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                order.pembayaranVia.toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 16),

                        /// Items List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item Pesanan',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.namaProduct,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            Text(
                                              'x${item.qty}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatRupiah(item.totalDetails),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            /// Fixed Footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white, // Background to cover scrolled content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 16),

                    /// Total
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatRupiah(order.total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B3A1E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          /// Delete Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context, order.orderId),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Hapus'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          /// Print Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _printReceipt(order),
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Cetak Struk'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B3A1E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, int orderId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Pesanan'),
            content: const Text('Apakah Anda yakin ingin menghapus pesanan ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  final success = await controller.deleteOrder(orderId);
                  if (success) {
                    Navigator.pop(context); // Close bottom sheet
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _printReceipt(OrderDetailModel order) async {
    final printerService = Get.find<PrinterService>();

    // Convert order items to ProductModel for printer service
    final orderItems =
        order.items.map((item) {
          return ProductModel(
            id: 0,
            namaProduct: item.namaProduct,
            harga: item.totalDetails ~/ item.qty,
            categoryName: '',
            fotoUrl: '',
            qty: item.qty,
            discount: 0,
          );
        }).toList();

    final success = await printerService.printReceipt(
      orderItems: orderItems,
      total: order.total,
      customerName: '',
      queueNumber: '',
      paymentMethod: order.pembayaranVia,
      channel: '',
      printUrl: order.printUrl,
      orderNo: order.orderNo,
    );

    if (success) {
      Get.snackbar(
        'Sukses',
        'Struk berhasil dicetak',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}
