class ProductModel {
  final int id;
  final String namaProduct;
  final String categoryName;
  final String categorySlug;
  final String categoryId;
  final int harga;
  final String fotoUrl;

  int qty;

  ProductModel({
    required this.id,
    required this.namaProduct,
    required this.categoryName,
    required this.categorySlug,
    required this.categoryId,
    required this.harga,
    required this.fotoUrl,
    this.qty = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      namaProduct: json['nama_product'] ?? '',
      categoryName: json['category_name'] ?? '',
      categorySlug: json['category_slug'] ?? '',
      categoryId: json['category_id']?.toString() ?? '',
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
      'category_slug': categorySlug,
      'category_id': categoryId,
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
    String? categorySlug,
    String? categoryId,
    int? harga,
    String? fotoUrl,
    int? qty,
  }) {
    return ProductModel(
      id: id ?? this.id,
      namaProduct: namaProduct ?? this.namaProduct,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryId: categoryId ?? this.categoryId,
      harga: harga ?? this.harga,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      qty: qty ?? this.qty,
    );
  }
}
