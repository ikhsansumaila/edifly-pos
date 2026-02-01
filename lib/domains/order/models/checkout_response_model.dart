class CheckoutResponseModel {
  final bool status;
  final String message;
  final CheckoutData? data;
  final String? rootPrintUrl;

  CheckoutResponseModel({
    required this.status,
    required this.message,
    this.data,
    this.rootPrintUrl,
  });

  factory CheckoutResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckoutResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CheckoutData.fromJson(json['data']) : null,
      rootPrintUrl: json['print_url'],
    );
  }

  String? get printUrl => data?.printUrl ?? rootPrintUrl;
}

class CheckoutData {
  final String? orderNo;
  final String? printUrl;
  final int? id;
  final int? totalBayar;

  CheckoutData({this.orderNo, this.printUrl, this.id, this.totalBayar});

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      orderNo: json['order_no'],
      printUrl: json['print_url'],
      id: json['id'],
      totalBayar: json['total_bayar'],
    );
  }
}
