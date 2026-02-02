import 'package:edifly_pos/domains/order/models/order_detail_model.dart';
import 'package:edifly_pos/domains/order/models/order_list_model.dart';
import 'package:edifly_pos/domains/order/order_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderListController extends GetxController {
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final orders = <OrderListItemModel>[].obs;
  final selectedOrder = Rxn<OrderDetailModel>();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  /// Filtered orders based on search query
  List<OrderListItemModel> get filteredOrders {
    if (searchQuery.value.isEmpty) {
      return orders;
    }
    return orders.where((order) {
      final query = searchQuery.value.toLowerCase();
      return order.orderNo.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query);
    }).toList();
  }

  /// Update search query
  void searchOrder(String query) {
    searchQuery.value = query;
  }

  /// Fetch order list from API
  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final result = await OrderService.getOrders();
      orders.value = result;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat daftar pesanan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch order detail by ID
  Future<void> fetchOrderDetail(int orderId) async {
    isLoadingDetail.value = true;
    selectedOrder.value = null;
    try {
      final result = await OrderService.getOrderDetail(orderId);
      selectedOrder.value = result;
    } catch (e) {
      debugPrint('Error fetching order detail: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat detail pesanan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingDetail.value = false;
    }
  }

  /// Delete order by ID
  Future<bool> deleteOrder(int orderId) async {
    try {
      final success = await OrderService.deleteOrder(orderId);
      if (success) {
        // Remove from local list
        orders.removeWhere((o) => o.orderId == orderId);
        Get.snackbar(
          'Sukses',
          'Pesanan berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Gagal menghapus pesanan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting order: $e');
      Get.snackbar(
        'Error',
        'Gagal menghapus pesanan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Clear selected order
  void clearSelectedOrder() {
    selectedOrder.value = null;
  }
}
