import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/auth/auth_controller.dart';
import 'package:edifly_pos/domains/order/cart_item_controller.dart';
import 'package:edifly_pos/domains/printer/printer_settings_page.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:edifly_pos/domains/shift/closing_shift.dart';
import 'package:edifly_pos/widgets/custom_network_image.dart';
import 'package:edifly_pos/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PosOrderPage extends StatelessWidget {
  const PosOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.put(CartItemController());
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          Obx(() {
            return TopBar(
              userName: cartController.userName.value,
              menus: [
                TopBarMenuModel(
                  label: 'Pesanan',
                  icon: Icons.receipt_long,
                  isActive: true,
                  onTap: () {
                    print("Membuka List Pesanan...");
                    // Jalankan fungsi A
                  },
                ),
                TopBarMenuModel(
                  label: 'Tutup Pesanan',
                  icon: Icons.lock,
                  onTap: () {
                    Get.to(() => const ClosingShiftPage());
                    // Jalankan fungsi B (Contoh: Navigasi ke halaman rekonsiliasi)
                  },
                ),
                TopBarMenuModel(
                  label: 'Printer',
                  icon: Icons.print,
                  onTap: () {
                    Get.to(() => const PrinterSettingsPage());
                  },
                ),
                TopBarMenuModel(
                  label: 'Logout',
                  icon: Icons.exit_to_app,
                  onTap: () {
                    final authController = Get.put(AuthController());
                    authController.logout();
                  },
                ),
              ],
            );
          }),
          // _topBar(),
          Expanded(
            child: Row(
              children: [
                /// LEFT - MENU
                Expanded(flex: 6, child: _menuSection()),

                /// RIGHT - CART
                Expanded(flex: 4, child: _cartSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU SECTION =================
  Widget _menuSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _categoryRow(),
          const SizedBox(height: 16),
          Expanded(child: _menuGrid()),
        ],
      ),
    );
  }

  Widget _categoryRow() {
    final cartController = Get.find<CartItemController>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        return Row(
          children:
              cartController.categories
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => cartController.selectCategory(e),
                        child: Chip(
                          label: Text(e),
                          backgroundColor:
                              cartController.selectedCategory.value == e
                                  ? Colors.brown
                                  : Colors.grey,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        );
      }),
    );
  }

  Widget _menuGrid() {
    final cartController = Get.find<CartItemController>();

    return Obx(() {
      if (cartController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      List<ProductModel> productList = cartController.filteredProductList;
      if (productList.isEmpty) {
        return const Center(child: Text("Tidak ada produk"));
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: productList.length,
        itemBuilder: (_, i) {
          return _menuCard(product: productList[i]);
        },
      );
    });
  }

  Widget _menuCard({required ProductModel product}) {
    final cartController = Get.find<CartItemController>();
    return GestureDetector(
      onTap: () => cartController.increment(product.id),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(child: CustomNetworkImage(imageUrl: product.fotoUrl, fit: BoxFit.cover)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          formatRupiah(product.harga),
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.namaProduct,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(product.categoryName, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CART SECTION =================
  Widget _cartSection() {
    final cartController = Get.find<CartItemController>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🛒 Keranjang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => cartController.removeAll(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text('HAPUS SEMUA', style: TextStyle(color: Colors.red, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// SCROLL AREA
          Expanded(
            child: Obx(() {
              final items = cartController.cartItems.values.toList();

              /// ===== EMPTY STATE =====
              if (items.isEmpty) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 96, color: Colors.black26),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada pesanan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, thickness: 1, color: Colors.black12),
                      const SizedBox(height: 12),

                      /// CHECKOUT FORM
                      _checkoutForm(),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  /// CART ITEMS - Scrollable
                  Expanded(
                    flex: 2,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children:
                          items
                              .map(
                                (e) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: _cartItem(
                                    id: e.id,
                                    title: e.namaProduct,
                                    price: '${formatRupiah(e.harga)} x ${e.qty}',
                                    qty: e.qty,
                                    onAdd: () => cartController.increment(e.id),
                                    onRemove: () => cartController.decrement(e.id),
                                    onDelete: () => cartController.remove(e.id),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: Colors.black12),
                  const SizedBox(height: 12),

                  /// CHECKOUT FORM - Scrollable
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _checkoutForm(),
                    ),
                  ),
                ],
              );
            }),
          ),

          /// CHECKOUT BUTTON - Fixed at bottom
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 12),

          /// Kembalian
          Obx(() {
            final cartController = Get.find<CartItemController>();
            if (!cartController.isOffline ||
                !cartController.showNominalCash ||
                cartController.cartItems.isEmpty) {
              return const SizedBox.shrink();
            }
            final cashInput = cartController.cashAmount.value;
            final total = cartController.total.value;

            // Jika input 0 atau belum diisi, tampilkan Kembalian Rp 0
            if (cashInput == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kembalian',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      formatRupiah(0),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            final selisih = cashInput - total;
            final isKurang = selisih < 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isKurang ? 'Kurang' : 'Kembalian',
                    style: TextStyle(
                      fontSize: 12,
                      color: isKurang ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isKurang ? formatRupiah(selisih.abs()) : formatRupiah(selisih),
                    style: TextStyle(
                      fontSize: 12,
                      color: isKurang ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),

          Obx(() {
            final isValid = cartController.isValidCheckout;
            return SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed:
                    isValid
                        ? () {
                          cartController.checkoutOrder();
                        }
                        : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label:
                    cartController.isLoading.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                        : const Text('CHECK OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? const Color(0xFF5B3A1E) : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: isValid ? 2 : 0,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cartItem({
    required int id,
    required String title,
    required String price,
    required int qty,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required VoidCallback onDelete,
  }) {
    print("cartItem productID $id");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ===== LEFT : TITLE + PRICE =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(price, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),

          const SizedBox(width: 8),

          /// ===== RIGHT : QTY CONTROL =====
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(icon: Icons.remove, onTap: onRemove),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  qty.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              _qtyButton(icon: Icons.add, onTap: onAdd),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _checkoutForm() {
    final cartController = Get.find<CartItemController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ===== NAMA + ANTRIAN (1 ROW) =====
        Row(
          children: [
            /// NAMA PEMESAN
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Pemesan', style: TextStyle(fontSize: 11, color: Colors.black)),
                  const SizedBox(height: 4),
                  _input('atas nama', cartController.customerNameController),
                ],
              ),
            ),

            const SizedBox(width: 8),

            /// NO ANTRIAN
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No. Antrian', style: TextStyle(fontSize: 11, color: Colors.black)),
                  const SizedBox(height: 4),
                  _input('', cartController.queueNumberController),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Divider(height: 1, thickness: 1, color: Colors.black12),
        const SizedBox(height: 12),

        /// CHANNEL
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _badge('OFFLINE', Colors.brown),
            _badge('GO', Colors.lightGreen),
            _badge('GRAB', Colors.green.shade800),
            _badge('SHOPEE', Colors.orange.shade600),
            // _badge('INSTAGRAM', Colors.deepPurple),
            // _badge('WHATSAPP', Colors.lightGreen),
          ],
        ),

        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: Colors.black12),
        const SizedBox(height: 12),

        const Text('Metode Pembayaran', style: TextStyle(fontSize: 11, color: Colors.black)),
        const SizedBox(height: 4),

        Obx(() {
          final controller = Get.find<CartItemController>();

          return DropdownButtonFormField<String>(
            initialValue: controller.selectedPayment.value,
            style: TextStyle(
              color: controller.isOffline ? Colors.black : Colors.grey,
              fontSize: 13,
            ),
            dropdownColor: Colors.white,
            items:
                controller.paymentMethods
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged:
                controller.isOffline
                    ? (val) => controller.selectedPayment.value = val!
                    : null, // 🔥 disable kalau bukan OFFLINE
            iconDisabledColor: Colors.grey, // 👈 warna icon dropdown
            iconEnabledColor: Colors.grey,
            decoration: InputDecoration(
              hintText: controller.selectedPayment.value,
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              isDense: true,
              filled: true,
              fillColor: controller.isOffline ? Colors.white : Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Colors.grey, // warna border ketika enable
                  width: 1.5,
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 4),

        // _input('Tunai / Cash'),
        const SizedBox(height: 12),

        /// SUBTOTAL
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(
                formatRupiah(cartController.total.value),
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: Colors.black12),
        const SizedBox(height: 12),

        /// TOTAL
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Obx(
              () => Text(
                formatRupiah(cartController.total.value),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Obx(
          () =>
              (cartController.isOffline && cartController.showNominalCash)
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'BAYAR (NOMINAL)',
                        style: TextStyle(fontSize: 11, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      RupiahInput(
                        hint: 'Masukkan nominal',
                        onChanged: (val) {
                          print("Nilai int: $val");
                          cartController.cashAmount.value = val;
                        },
                      ),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _input(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  Widget _badge(String label, Color color) {
    final cartController = Get.find<CartItemController>();
    return Obx(() {
      final isSelected = cartController.selectedChannel.value == label;

      return InkWell(
        onTap: () => cartController.selectPaymentChannel(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(150),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) const Icon(Icons.check, size: 14, color: Colors.white),
              if (isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    });
  }
}
