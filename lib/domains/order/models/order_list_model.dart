/// Model untuk Order List Item
class OrderListItemModel {
  final int orderId;
  final String orderNo;
  final String tglOrder;
  final int total;
  final String pembayaranVia;
  final int status;
  final String customerName;
  final String queueNumber;
  final String sumber;
  final int jumlahItem;

  OrderListItemModel({
    required this.orderId,
    required this.orderNo,
    required this.tglOrder,
    required this.total,
    required this.pembayaranVia,
    required this.status,
    required this.customerName,
    required this.queueNumber,
    required this.sumber,
    required this.jumlahItem,
  });

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    return OrderListItemModel(
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      orderNo: json['order_no'] ?? '',
      tglOrder: json['tgl_order'] ?? '',
      // Parsing "40000.00" -> 40000
      total: double.tryParse(json['total'].toString())?.toInt() ?? 0,
      pembayaranVia: json['pembayaran_via'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
      customerName: json['customer_name'] ?? '',
      queueNumber: json['queue_number'].toString(),
      sumber: json['sumber'] ?? '',
      jumlahItem: int.tryParse(json['jumlah_item'].toString()) ?? 0,
    );
  }

  /// Status text berdasarkan status code
  String get statusText {
    switch (status) {
      case 1:
        return 'Sinkronisasi Pembayaran';
      case 2:
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  /// Status color berdasarkan status code
  bool get isCompleted => status == 2;
}

/// Model untuk Order Detail Response
class OrderDetailModel {
  final int orderId;
  final String orderNo;
  final String tglOrder;
  final int total;
  final String pembayaranVia;
  final int status;
  final String customerName;
  final String queueNumber;
  final String sumber;
  final List<OrderDetailItem> items;
  final String? printUrl;

  OrderDetailModel({
    required this.orderId,
    required this.orderNo,
    required this.tglOrder,
    required this.total,
    required this.pembayaranVia,
    required this.status,
    required this.customerName,
    required this.queueNumber,
    required this.sumber,
    required this.items,
    this.printUrl,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      orderNo: json['order_no'] ?? '',
      tglOrder: json['tgl_order'] ?? '',
      total: double.tryParse(json['total'].toString())?.toInt() ?? 0,
      pembayaranVia: json['pembayaran_via'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
      customerName: json['customer_name'] ?? '',
      queueNumber: json['queue_number'].toString(),
      sumber: json['sumber'] ?? '',
      items:
          (json['items'] as List<dynamic>?)?.map((e) => OrderDetailItem.fromJson(e)).toList() ?? [],
      printUrl: json['print_url'],
    );
  }

  /// Status text berdasarkan status code
  String get statusText {
    switch (status) {
      case 1:
        return 'Sinkronisasi Pembayaran';
      case 2:
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  bool get isCompleted => status == 2;
}

/// Model untuk Order Detail Item
class OrderDetailItem {
  final String namaProduct;
  final int qty;
  final int totalDetails;

  OrderDetailItem({required this.namaProduct, required this.qty, required this.totalDetails});

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailItem(
      namaProduct: json['nama_product'] ?? '',
      qty: double.tryParse(json['qty'].toString())?.toInt() ?? 0,
      totalDetails: double.tryParse(json['total_details'].toString())?.toInt() ?? 0,
    );
  }
}
