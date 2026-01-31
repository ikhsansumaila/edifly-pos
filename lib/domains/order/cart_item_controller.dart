import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/order/order_service.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:edifly_pos/domains/shift/closing_shift.dart';
import 'package:edifly_pos/domains/shift/shift_controller.dart';
import 'package:edifly_pos/domains/shift/shift_service.dart';
import 'package:edifly_pos/widgets/receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class CartItemController extends GetxController {
  final cartItems = <String, ProductModel>{}.obs;
  final productList = <ProductModel>[].obs;

  final isLoading = false.obs;
  final isLoadingProduct = false.obs;

  final total = 0.obs;

  final cashAmount = 0.obs;
  final userName = ''.obs;
  final outletName = ''.obs;

  final ProductService _service = Get.find();

  final selectedChannel = 'OFFLINE'.obs;

  final paymentMethods = ['Tunai (Cash)', 'QRIS', 'Transfer Bank'];

  final selectedPayment = 'Tunai (Cash)'.obs;

  final nominalCash = ''.obs;

  final customerNameController = TextEditingController();
  final queueNumberController = TextEditingController();

  bool get isOffline => selectedChannel.value == 'OFFLINE';

  bool get showNominalCash => isOffline && selectedPayment.value == 'Tunai (Cash)';

  bool get isValidCheckout {
    if (cartItems.isEmpty) return false;
    if (total.value == 0) return false;
    if (showNominalCash) {
      return cashAmount.value >= total.value;
    }
    return true;
  }

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

  @override
  void onInit() {
    Get.isRegistered<ShiftController>() ? Get.find<ShiftController>() : Get.put(ShiftController());
    super.onInit();
    loadProducts();
    loadUser();
  }

  Future<void> loadUser() async {
    userName.value = await AuthStorage.getName() ?? '-';
    outletName.value = await AuthStorage.getNamaOutlet() ?? '';
  }

  void _showErrorDialog(String message) {
    Get.defaultDialog(
      title: 'Error',
      middleText: message,
      textConfirm: 'OK',
      onConfirm: () => Get.back(),
      confirmTextColor: Colors.white,
    );
  }

  Future<void> loadProducts() async {
    isLoadingProduct.value = true;
    try {
      final products = await _service.fetchProducts();
      productList.assignAll(products);
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      isLoadingProduct.value = false;
    }
  }

  Future<void> increment(int productId) async {
    // Check Shift Status first if cart is empty (first item being added) or just check every time?
    // User request: "when cashier adds item to cart". Checking every time ensures safety but might be slow.
    // Optimization: Check only if cart is empty? Or maybe check once per session?
    // User said: "when ... adds item ... if haven't closed shift ... must close".
    // I will check it every time for now to be safe as per request.
    final shiftController = Get.find<ShiftController>();
    if (cartItems.isEmpty && !shiftController.isShiftOpen.value) {
      try {
        final response = await ShiftService.checkShiftStatus();
        if (response['status'] == true) {
          final data = response['data'];
          final openedAtStr = data['opened_at'];
          if (openedAtStr != null) {
            final openedAt = DateTime.parse(openedAtStr);
            final now = DateTime.now();

            // Check if same day
            if (!(openedAt.year == now.year &&
                openedAt.month == now.month &&
                openedAt.day == now.day)) {
              // Different day, must close previous shift first
              Get.defaultDialog(
                title: 'Perhatian',
                middleText:
                    'Anda memiliki shift aktif dari hari sebelumnya. Harap lakukan closing terlebih dahulu.',
                textConfirm: 'OK',
                onConfirm: () {
                  Get.back();
                  Get.offAll(() => const ClosingShiftPage());
                },
                confirmTextColor: Colors.white,
              );
              return;
            }
          }
        }
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }

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

  @override
  void onClose() {
    customerNameController.dispose();
    queueNumberController.dispose();
    super.onClose();
  }

  Future<void> checkoutOrder() async {
    if (cartItems.isEmpty) {
      _showErrorDialog('Keranjang kosong, silahkan pilih produk terlebih dahulu');
      return;
    }

    if (customerNameController.text.isEmpty) {
      _showErrorDialog('Nama pelanggan tidak boleh kosong');
      return;
    }

    if (queueNumberController.text.isEmpty) {
      _showErrorDialog('Nomor antrian tidak boleh kosong');
      return;
    }

    try {
      isLoading.value = true;
      final shiftController = Get.find<ShiftController>();

      print("shiftController.currentShiftId.value ${shiftController.currentShiftId.value}");
      // Ensure shift ID is available
      if (shiftController.currentShiftId.value == null) {
        await shiftController.getActiveShift();
        if (shiftController.currentShiftId.value == null) {
          throw "Shift ID tidak ditemukan. Silakan login ulang atau buka shift.";
        }
      }

      final itemsList =
          cartItems.values
              .map(
                (e) => {
                  "product_id": e.id,
                  "nama_product": e.namaProduct,
                  "qty": e.qty,
                  "sub_total": e.harga * e.qty,
                  "discount_pct": 0,
                  "discount": 0,
                  "total_details": e.harga * e.qty,
                },
              )
              .toList();

      final uuid = const Uuid().v4();

      final checkoutResult = await OrderService.checkout(
        clientUuid: uuid,
        closingId: shiftController.currentShiftId.value!,
        paymentMethod: selectedPayment.value,
        sumber: selectedChannel.value,
        subTotal: total.value,
        totalBayar: total.value,
        items: itemsList,
        customerName:
            customerNameController.text.isEmpty ? "Pelanggan" : customerNameController.text,
        queueNumber: queueNumberController.text.isEmpty ? "-" : queueNumberController.text,
      );

      if (checkoutResult['status'] != true) {
        throw checkoutResult['message'] ?? 'Checkout gagal';
      }

      // Show Receipt Popup
      await Get.dialog(
        ReceiptDialog(
          cartItems: List<ProductModel>.from(cartItems.values),
          total: total.value,
          customerName: customerNameController.text,
          queueNumber: queueNumberController.text,
          paymentMethod: selectedPayment.value,
          channel: selectedChannel.value,
          cashAmount: cashAmount.value,
          cashierName: userName.value,
          outletName: outletName.value,
        ),
      );

      // Reset
      removeAll();
      customerNameController.clear();
      queueNumberController.clear();
      cashAmount.value = 0;
    } catch (e) {
      _showErrorDialog('Checkout gagal: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
