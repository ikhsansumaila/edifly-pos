import 'package:edifly_pos/core/storage/auth_storage.dart';
import 'package:edifly_pos/domains/order/order_service.dart';
import 'package:edifly_pos/domains/product/product_model.dart';
import 'package:edifly_pos/domains/product/product_service.dart';
import 'package:edifly_pos/domains/shift/shift_controller.dart';
import 'package:edifly_pos/widgets/confirmation_dialog.dart';
import 'package:edifly_pos/widgets/receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class OrderProcessController extends GetxController {
  final orderItems = <String, ProductModel>{}.obs;
  final productList = <ProductModel>[].obs;

  final isLoading = false.obs;
  final isLoadingProduct = false.obs;

  final total = 0.obs;

  final cashAmount = 0.obs;
  final userName = ''.obs;
  final outletName = ''.obs;
  final outletAddress = ''.obs;

  final ProductService _service = Get.find();

  final selectedChannel = 'OFFLINE'.obs;

  final paymentMethods = {'cash': 'Tunai (Cash)', 'qris': 'QRIS', 'transfer': 'Transfer Bank'};

  final selectedPayment = 'cash'.obs;

  final nominalCash = ''.obs;

  final customerNameController = TextEditingController();
  final queueNumberController = TextEditingController();
  final cashAmountController = TextEditingController();

  bool get isOffline => selectedChannel.value == 'OFFLINE';

  bool get showNominalCash => isOffline && selectedPayment.value == 'cash';

  bool get isValidCheckout {
    if (orderItems.isEmpty) return false;
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
      selectedPayment.value = 'transfer';
    } else {
      selectedPayment.value = 'cash';
    }
  }

  final selectedCategory = 'SEMUA'.obs;
  final searchQuery = ''.obs;

  List<String> get categories {
    final cats = productList.map((e) => e.categoryName).toSet().toList();
    cats.sort();
    return ['SEMUA', ...cats];
  }

  List<ProductModel> get filteredProductList {
    List<ProductModel> filtered = productList;

    if (selectedCategory.value != 'SEMUA') {
      filtered = filtered.where((p) => p.categoryName == selectedCategory.value).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where((p) => p.namaProduct.toLowerCase().contains(searchQuery.value.toLowerCase()))
              .toList();
    }

    return filtered;
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  void searchProduct(String query) {
    searchQuery.value = query;
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
    outletAddress.value = await AuthStorage.getAddress() ?? '';
  }

  void _showErrorDialog(String message, {String title = 'Error'}) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: 'OK',
      onConfirm: () => Get.back(),
      confirmTextColor: Colors.white,
      buttonColor: Colors.brown,
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
    String productIdStr = productId.toString();
    if (orderItems[productIdStr] == null) {
      ProductModel item = productList.where((id) => id.id == productId).first;
      item.qty = 1;
      orderItems.addAll({item.id.toString(): item});
      calculateTotal();
      update();
      return;
    }

    int qty = orderItems[productIdStr]!.qty;
    orderItems[productIdStr] = orderItems[productIdStr]!.copyWith(qty: qty + 1);
    calculateTotal();
    update();
  }

  void decrement(int productId) {
    String productIdStr = productId.toString();
    int qty = orderItems[productIdStr]!.qty;
    if (qty == 1) {
      remove(productId);
      return;
    }

    orderItems[productIdStr] = orderItems[productIdStr]!.copyWith(qty: qty - 1);
    calculateTotal();
    update();
  }

  void remove(int productId) {
    orderItems.remove(productId.toString());
    calculateTotal();
    update();
  }

  void removeAll() {
    orderItems.clear();
    total.value = 0;
    update();
  }

  void calculateTotal() {
    total.value = 0;
    for (final item in orderItems.values) {
      double discountedPrice = item.harga * (1 - (item.discount / 100));
      total.value += (discountedPrice * item.qty).toInt();
    }
    // print("total.value ${total.value}");
    update();
  }

  void updateDiscount(int productId, double discount) {
    String productIdStr = productId.toString();
    if (orderItems.containsKey(productIdStr)) {
      orderItems[productIdStr] = orderItems[productIdStr]!.copyWith(discount: discount);
      calculateTotal();
      update();
    }
  }

  @override
  void onClose() {
    customerNameController.dispose();
    queueNumberController.dispose();
    cashAmountController.dispose();
    super.onClose();
  }

  void checkoutOrder() {
    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    if (orderItems.isEmpty) {
      _showErrorDialog('Keranjang kosong, silahkan pilih produk terlebih dahulu', title: '');
      return;
    }

    // if (customerNameController.text.isEmpty) {
    //   _showErrorDialog('Nama pelanggan tidak boleh kosong', title: 'Lengkapi');
    //   return;
    // }

    // if (queueNumberController.text.isEmpty) {
    //   _showErrorDialog('Nomor antrian tidak boleh kosong', title: 'Lengkapi');
    //   return;
    // }

    Get.dialog(
      ConfirmationDialog(
        source: selectedChannel.value,
        total: total.value,
        method: paymentMethods[selectedPayment.value] ?? selectedPayment.value,
        onConfirm: () {
          Get.back();
          _processCheckout();
        },
        onCancel: () {
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _processCheckout() async {
    try {
      isLoading.value = true;
      final shiftController =
          Get.isRegistered<ShiftController>()
              ? Get.find<ShiftController>()
              : Get.put(ShiftController());

      // print("shiftController.currentShiftId.value ${shiftController.currentShiftId.value}");
      // Ensure shift ID is available
      if (shiftController.currentShiftId.value == null) {
        await shiftController.getActiveShift();
        if (shiftController.currentShiftId.value == null) {
          throw "Shift ID tidak ditemukan. Silakan login ulang atau buka shift.";
        }
      }

      final itemsList =
          orderItems.values
              .map(
                (e) => {
                  "product_id": e.id,
                  "nama_product": e.namaProduct,
                  "qty": e.qty,
                  "sub_total": e.harga * e.qty,
                  "discount_pct": e.discount,
                  "discount": (e.harga * e.qty * (e.discount / 100)).toInt(),
                  "total_details": (e.harga * e.qty * (1 - (e.discount / 100))).toInt(),
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

      if (!checkoutResult.status) {
        throw checkoutResult.message;
      }

      debugPrint("Checkout Result: ${checkoutResult.status}");
      debugPrint("Order No: ${checkoutResult.data?.orderNo}");
      debugPrint("Print URL: ${checkoutResult.printUrl}");

      // Show Receipt Popup
      await Get.dialog(
        ReceiptDialog(
          orderItems: List<ProductModel>.from(orderItems.values),
          total: total.value,
          customerName: customerNameController.text,
          queueNumber: queueNumberController.text,
          paymentMethod: paymentMethods[selectedPayment.value] ?? selectedPayment.value,
          channel: selectedChannel.value,
          cashAmount: cashAmount.value,
          cashierName: userName.value,
          outletName: outletName.value,
          outletAddress: outletAddress.value,
          printUrl: checkoutResult.printUrl,
          orderNo: checkoutResult.data?.orderNo,
        ),
      );

      // Reset
      removeAll();
      customerNameController.clear();
      queueNumberController.clear();
      cashAmountController.clear();
      cashAmount.value = 0;
    } catch (e) {
      _showErrorDialog('Checkout gagal: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
