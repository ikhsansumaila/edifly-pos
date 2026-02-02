/// Model untuk Order Detail Response
class OrderDetailModel {
  final int orderId;
  final int outletId;
  final int closingId;
  final String clientUuid;
  final String orderNo;
  final String tglOrder;
  final String hash;
  final String qr;
  final int subTotal;
  final int discountPct;
  final int discount;
  final int vat;
  final int total;
  final String pembayaranVia;
  final int status;
  final int jumlahItem;
  final String sumber;
  final String queueNumber;
  final String customerName;
  final String syncStatus;
  final String platform;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final List<OrderDetailItem> items;
  final String? printUrl;

  OrderDetailModel({
    required this.orderId,
    required this.outletId,
    required this.closingId,
    required this.clientUuid,
    required this.orderNo,
    required this.tglOrder,
    required this.hash,
    required this.qr,
    required this.subTotal,
    required this.discountPct,
    required this.discount,
    required this.vat,
    required this.total,
    required this.pembayaranVia,
    required this.status,
    required this.jumlahItem,
    required this.sumber,
    required this.queueNumber,
    required this.customerName,
    required this.syncStatus,
    required this.platform,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.printUrl,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      outletId: int.tryParse(json['outlet_id'].toString()) ?? 0,
      closingId: int.tryParse(json['closing_id'].toString()) ?? 0,
      clientUuid: json['client_uuid'] ?? '',
      orderNo: json['order_no'] ?? '',
      tglOrder: json['tgl_order'] ?? '',
      hash: json['hash'] ?? '',
      qr: json['qr'] ?? '',
      subTotal: double.tryParse(json['sub_total'].toString())?.toInt() ?? 0,
      discountPct: double.tryParse(json['discount_pct'].toString())?.toInt() ?? 0,
      discount: double.tryParse(json['discount'].toString())?.toInt() ?? 0,
      vat: double.tryParse(json['vat'].toString())?.toInt() ?? 0,
      total: double.tryParse(json['total'].toString())?.toInt() ?? 0,
      pembayaranVia: json['pembayaran_via'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
      jumlahItem: int.tryParse(json['jumlah_item'].toString()) ?? 0,
      sumber: json['sumber'] ?? '',
      queueNumber: json['queue_number'].toString(),
      customerName: json['customer_name'] ?? '',
      syncStatus: json['sync_status'].toString(),
      platform: json['platform'] ?? '',
      createdBy: json['created_by'].toString(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
  final int idDetail;
  final int idOrder;
  final int productId;
  final String namaProduct;
  final int qty;
  final int subTotal;
  final int discountPct;
  final int discount;
  final int totalDetails;
  final String isVoid;
  final String? keterangan;

  OrderDetailItem({
    required this.idDetail,
    required this.idOrder,
    required this.productId,
    required this.namaProduct,
    required this.qty,
    required this.subTotal,
    required this.discountPct,
    required this.discount,
    required this.totalDetails,
    required this.isVoid,
    this.keterangan,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailItem(
      idDetail: int.tryParse(json['id_detail'].toString()) ?? 0,
      idOrder: int.tryParse(json['id_order'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      namaProduct: json['nama_product'] ?? '',
      qty: double.tryParse(json['qty'].toString())?.toInt() ?? 0,
      subTotal: double.tryParse(json['sub_total'].toString())?.toInt() ?? 0,
      discountPct: double.tryParse(json['discount_pct'].toString())?.toInt() ?? 0,
      discount: double.tryParse(json['discount'].toString())?.toInt() ?? 0,
      totalDetails: double.tryParse(json['total_details'].toString())?.toInt() ?? 0,
      isVoid: json['is_void'].toString(),
      keterangan: json['keterangan'],
    );
  }
}
