import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartItemController extends GetxController {
  final cartItems = <String, ProductModel>{}.obs;
  final productList = <ProductModel>[].obs;
  // final RxInt qty = 1.obs;
  final total = 0.obs;

  final cashAmount = 0.obs;
  final userName = ''.obs;

  final ProductService _service = Get.find();

  final selectedChannel = 'OFFLINE'.obs;

  final paymentMethods = ['Tunai (Cash)', 'QRIS', 'Transfer Bank'];

  final selectedPayment = 'Tunai (Cash)'.obs;

  final nominalCash = ''.obs;

  bool get isOffline => selectedChannel.value == 'OFFLINE';

  bool get showNominalCash => isOffline && selectedPayment.value == 'Tunai (Cash)';

  void selectPaymentChannel(String paymentChannel) {
    selectedChannel.value = paymentChannel;

    /// RULE:
    if (paymentChannel != 'OFFLINE') {
      selectedPayment.value = 'Transfer Bank';
    } else {
      selectedPayment.value = 'Tunai (Cash)';
    }
  }

  final selectedCategory = 'SEMUA'.obs;

  List<String> get categories {
    final cats = productList.map((e) => e.categoryName).toSet().toList();
    cats.sort();
    return ['SEMUA', ...cats];
  }

  List<ProductModel> get filteredProductList {
    if (selectedCategory.value == 'SEMUA') {
      return productList;
    }
    return productList.where((p) => p.categoryName == selectedCategory.value).toList();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadUser();
  }

  Future<void> loadUser() async {
    userName.value = await AuthStorage.getName() ?? 'Kasir';
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final products = await _service.fetchProducts();
      productList.assignAll(products);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void increment(int productId) {
    String cartItemId = productId.toString();
    if (cartItems[cartItemId] == null) {
      ProductModel item = productList.where((id) => id.id == productId).first;
      item.qty = 1;
      cartItems.addAll({item.id.toString(): item});
      calculateTotal();
      update();
      return;
    }

    int qty = cartItems[cartItemId]!.qty;
    cartItems[cartItemId] = cartItems[cartItemId]!.copyWith(qty: qty + 1);
    calculateTotal();
    update();
  }

  void decrement(int productId) {
    String cartItemId = productId.toString();
    int qty = cartItems[cartItemId]!.qty;
    if (qty == 1) {
      remove(productId);
      return;
    }

    cartItems[cartItemId] = cartItems[cartItemId]!.copyWith(qty: qty - 1);
    calculateTotal();
    update();
  }

  void remove(int productId) {
    cartItems.remove(productId.toString());
    calculateTotal();
    update();
  }

  void removeAll() {
    cartItems.clear();
    total.value = 0;
    update();
  }

  void calculateTotal() {
    for (final item in cartItems.values) {
      total.value += item.harga * item.qty;
    }
    print("total.value ${total.value}");
    update();
  }
}
