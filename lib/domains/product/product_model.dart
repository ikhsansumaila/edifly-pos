class ProductModel {
  final int id;
  final String namaProduct;
  final String categoryName;
  final int harga;
  final String fotoUrl;

  int qty;

  ProductModel({
    required this.id,
    required this.namaProduct,
    required this.categoryName,
    required this.harga,
    required this.fotoUrl,
    this.qty = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      namaProduct: json['nama_product'] ?? '',
      categoryName: json['category_name'] ?? '',
      harga: int.tryParse(json['harga'].toString()) ?? 0,
      fotoUrl: json['foto_url'] ?? '',
      qty: json['qty'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_product': namaProduct,
      'category_name': categoryName,
      'harga': harga,
      'foto_url': fotoUrl,
      'qty': qty,
    };
  }

  /// ✅ copyWith (copy-paste safe)
  ProductModel copyWith({
    int? id,
    String? namaProduct,
    String? categoryName,
    int? harga,
    String? fotoUrl,
    int? qty,
  }) {
    return ProductModel(
      id: id ?? this.id,
      namaProduct: namaProduct ?? this.namaProduct,
      categoryName: categoryName ?? this.categoryName,
      harga: harga ?? this.harga,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      qty: qty ?? this.qty,
    );
  }
}
