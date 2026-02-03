import 'package:edifly_pos/app/routes/app_routes.dart';
import 'package:edifly_pos/core/config/app_theme_config.dart';
import 'package:edifly_pos/core/utils/currency.dart';
import 'package:edifly_pos/domains/auth/auth_controller.dart';
import 'package:edifly_pos/domains/order/order_process_controller.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:edifly_pos/widgets/custom_network_image.dart';
import 'package:edifly_pos/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PosOrderPage extends StatelessWidget {
  const PosOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProcessController = Get.put(OrderProcessController());
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          Obx(() {
            return TopBar(
              userName: orderProcessController.userName.value,
              menus: [
                TopBarMenuModel(
                  label: 'Transaksi',
                  icon: Icons.shopping_cart_outlined,
                  isActive: true, // Halaman ini (Order Baru)
                  onTap: () {},
                ),
                TopBarMenuModel(
                  label: 'Daftar Pesanan',
                  icon: Icons.receipt_long,
                  isActive: false,
                  onTap: () {
                    Get.toNamed(Routes.orderList);
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
            );
          }),
          // _topBar(),
          Expanded(
            child: Row(
              children: [
                /// LEFT - MENU
                Expanded(flex: 7, child: _menuSection()),

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              _searchBar(),
            ],
          ),
          const SizedBox(height: 8),
          _categoryRow(),
          const SizedBox(height: 16),
          Expanded(child: _menuGrid()),
        ],
      ),
    );
  }

  Widget _searchBar() {
    final orderProcessController = Get.find<OrderProcessController>();
    return Container(
      width: 150,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        onChanged: (val) => orderProcessController.searchProduct(val),
        decoration: InputDecoration(
          hintText: 'Cari menu...',
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
          border: InputBorder.none,
        ),
        style: TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _categoryRow() {
    final orderProcessController = Get.find<OrderProcessController>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        return Row(
          children:
              orderProcessController.categories
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () => orderProcessController.selectCategory(e),
                        child: Chip(
                          label: Text(e),
                          backgroundColor:
                              orderProcessController.selectedCategory.value == e
                                  ? Colors.brown
                                  : Colors.grey,
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
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
    final orderProcessController = Get.find<OrderProcessController>();

    return Obx(() {
      if (orderProcessController.isLoadingProduct.value) {
        return const Center(child: CircularProgressIndicator());
      }
      List<ProductModel> productList = orderProcessController.filteredProductList;
      if (productList.isEmpty) {
        return const Center(child: Text("Tidak ada produk"));
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
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
    return _AnimatedMenuCard(product: product);
  }

  // ================= CART SECTION =================
  Widget _cartSection() {
    final orderProcessController = Get.find<OrderProcessController>();
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
              Text('🛒 Keranjang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => orderProcessController.removeAll(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'HAPUS SEMUA',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// SCROLL AREA - Cart Items + Checkout Form in one scroll
          Expanded(
            child: Obx(() {
              final items = orderProcessController.orderItems.values.toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ===== EMPTY STATE or CART ITEMS =====
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 100),
                      child:
                          items.isEmpty
                              ? Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 96,
                                      color: Colors.black26,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Belum ada pesanan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    items
                                        .map(
                                          (e) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: _cartItem(
                                              title: e.namaProduct,
                                              price: '${formatRupiah(e.harga)} x ${e.qty}',
                                              totalPrice: formatRupiah(
                                                (e.harga * e.qty * (1 - (e.discount / 100)))
                                                    .toInt(),
                                              ),
                                              qty: e.qty,
                                              discount: e.discount,
                                              onDiscountChanged:
                                                  (val) => orderProcessController.updateDiscount(
                                                    e.id,
                                                    val,
                                                  ),
                                              onAdd: () => orderProcessController.increment(e.id),
                                              onRemove:
                                                  () => orderProcessController.decrement(e.id),
                                              onDelete: () => orderProcessController.remove(e.id),
                                            ),
                                          ),
                                        )
                                        .toList(),
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
            }),
          ),

          /// CHECKOUT BUTTON - Fixed at bottom
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 12),

          /// Kembalian
          Obx(() {
            final orderProcessController = Get.find<OrderProcessController>();
            if (!orderProcessController.isOffline ||
                !orderProcessController.showNominalCash ||
                orderProcessController.orderItems.isEmpty) {
              return const SizedBox.shrink();
            }
            final cashInput = orderProcessController.cashAmount.value;
            final total = orderProcessController.total.value;

            // Jika input 0 atau belum diisi, tampilkan Kembalian Rp 0
            if (cashInput == 0) {
              return SizedBox.shrink();
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
            final isValid = orderProcessController.isValidCheckout;
            return SizedBox(
              width: double.infinity,
              height: 35,
              child: ElevatedButton.icon(
                onPressed:
                    isValid
                        ? () {
                          orderProcessController.checkoutOrder();
                        }
                        : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label:
                    orderProcessController.isLoading.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                        : const Text(
                          'CHECK OUT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? AppThemeConfig.primaryColor : Colors.grey.shade400,
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
    required String title,
    required String price,
    required String totalPrice,
    required int qty,
    required double discount,
    required Function(double) onDiscountChanged,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 251, 255, 255),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black12, width: 0.8),
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
                Text(price, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                Text(totalPrice, style: TextStyle(fontSize: 11, color: Colors.black)),
              ],
            ),
          ),

          const SizedBox(width: 8),

          /// ===== RIGHT : QTY CONTROL =====
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Discount Input
              Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 25,
                    child: TextFormField(
                      initialValue: discount == 0 ? '' : discount.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0%',
                        hintStyle: TextStyle(fontSize: 10, color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          // borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      style: const TextStyle(fontSize: 10),
                      onChanged: (val) {
                        final d = double.tryParse(val) ?? 0.0;
                        onDiscountChanged(d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              _qtyButton(icon: Icons.remove, onTap: onRemove),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  qty.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              _qtyButton(icon: Icons.add, onTap: onAdd),
              // const SizedBox(width: 8),
              // GestureDetector(
              //   onTap: onDelete,
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.red,
              //       shape: BoxShape.circle,
              //       border: Border.all(color: Colors.grey.shade400),
              //     ),
              //     child: const Icon(Icons.close, size: 13, color: Colors.white),
              //   ),
              // ),
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
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 247, 247, 247),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Icon(icon, size: 16, color: Colors.black),
      ),
    );
  }

  Widget _checkoutForm() {
    final orderProcessController = Get.find<OrderProcessController>();

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
                  const Text('Nama Pemesan', style: TextStyle(fontSize: 10, color: Colors.black)),
                  const SizedBox(height: 4),
                  _input('atas nama', orderProcessController.customerNameController),
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
                  const Text('No. Antrian', style: TextStyle(fontSize: 10, color: Colors.black)),
                  const SizedBox(height: 4),
                  _input('', orderProcessController.queueNumberController),
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
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge('OFFLINE', Colors.brown),
            _badge('GO', Colors.lightGreen),
            _badge('GRAB', Colors.green.shade800),
            _badge('SHOPEE', Colors.orange.shade600),
            _badge('INSTAGRAM', Colors.deepPurple),
            _badge('WHATSAPP', Colors.lightGreen),
          ],
        ),

        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: Colors.black12),
        const SizedBox(height: 12),

        const Text('Metode Pembayaran', style: TextStyle(fontSize: 10, color: Colors.black)),
        const SizedBox(height: 4),

        Obx(() {
          final controller = Get.find<OrderProcessController>();

          // option ('Tunai / Cash'),
          return DropdownButtonFormField<String>(
            initialValue: controller.selectedPayment.value,
            style: TextStyle(
              color: controller.isOffline ? Colors.black : Colors.grey,
              fontSize: 10,
            ),
            dropdownColor: Colors.white,
            items:
                controller.paymentMethods.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
            onChanged:
                controller.isOffline
                    ? (val) => controller.selectedPayment.value = val!
                    : null, // 🔥 disable kalau bukan OFFLINE
            iconDisabledColor: Colors.grey, // 👈 warna icon dropdown
            iconEnabledColor: Colors.grey,
            decoration: InputDecoration(
              hintText: controller.paymentMethods[controller.selectedPayment.value] ?? '-',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              isDense: true,
              filled: true,
              fillColor: controller.isOffline ? Colors.white : Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Colors.grey.shade400, // warna border ketika enable
                  width: 0.8,
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 12),

        /// SUBTOTAL
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 10, color: Colors.black)),
              Text(
                formatRupiah(orderProcessController.total.value),
                style: const TextStyle(fontSize: 10, color: Colors.black),
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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Obx(
              () => Text(
                formatRupiah(orderProcessController.total.value),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Obx(
          () =>
              (orderProcessController.isOffline && orderProcessController.showNominalCash)
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'BAYAR (NOMINAL)',
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      RupiahInput(
                        fontSize: 10,
                        hint: 'Masukkan nominal',
                        controller: orderProcessController.cashAmountController,
                        onChanged: (val) {
                          // print("Nilai int: $val");
                          orderProcessController.cashAmount.value = val;
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
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Colors.grey.shade400, // warna border ketika enable
            width: 0.8,
          ),
        ),
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _badge(String label, Color color) {
    final orderProcessController = Get.find<OrderProcessController>();
    return Obx(() {
      final isSelected = orderProcessController.selectedChannel.value == label;

      return InkWell(
        onTap: () => orderProcessController.selectPaymentChannel(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(150),
            borderRadius: BorderRadius.circular(8),
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

/// Animated Menu Card with scale animation on tap
class _AnimatedMenuCard extends StatefulWidget {
  final ProductModel product;

  const _AnimatedMenuCard({required this.product});

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    // Bounce: 1.0 -> 1.05 -> 0.97 -> 1.0 (pop effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    // Play bounce animation
    _controller.forward(from: 0);

    // Add to cart
    final orderProcessController = Get.find<OrderProcessController>();
    orderProcessController.increment(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 15),
                  child: Stack(
                    children: [
                      Center(
                        child: CustomNetworkImage(
                          imageUrl: widget.product.fotoUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            formatRupiah(widget.product.harga),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  widget.product.namaProduct,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Text(
                  widget.product.categoryName,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
