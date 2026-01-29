import 'package:get/get.dart';

import 'product_model.dart';

class ProductService extends GetxService {
  Future<List<ProductModel>> fetchProducts({required String token}) async {
    List<ProductModel> listProducts = [
      ProductModel(
        id: 1,
        namaProduct: 'Beef Cheesy Mayo',
        categoryName: 'Beef',
        harga: 40000,
        fotoUrl: 'https://picsum.photos/200',
      ),
      ProductModel(
        id: 2,
        namaProduct: 'Beef Garlic Butter',
        categoryName: 'Beef',
        harga: 41000,
        fotoUrl: 'https://picsum.photos/200',
      ),
      ProductModel(
        id: 3,
        namaProduct: 'Beef Honey Spicy',
        categoryName: 'Beef',
        harga: 42000,
        fotoUrl: 'https://picsum.photos/200',
      ),
      ProductModel(
        id: 4,
        namaProduct: 'Beef Sambal Matah',
        categoryName: 'Beef',
        harga: 43000,
        fotoUrl: 'https://picsum.photos/200',
      ),
      ProductModel(
        id: 5,
        namaProduct: 'Beef Sesame Sauce',
        categoryName: 'Beef',
        harga: 44000,
        fotoUrl: 'https://picsum.photos/200',
      ),
      ProductModel(
        id: 6,
        namaProduct: 'Beef Smoky Mayo',
        categoryName: 'Beef',
        harga: 45000,
        fotoUrl: 'https://picsum.photos/200',
      ),
    ];

    return listProducts;
  }
}
  //   print("token $token");
  //   final url = Uri.parse('$API_BASE_URL/products');

  //   final response = await http.get(
  //     url,
  //     headers: {'Accept': 'application/json'},
  //     // headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  //   );

  //   if (response.statusCode == 200) {
  //     final json = jsonDecode(response.body);

  //     if (json['status'] == true) {
  //       return (json['data'] as List).map((e) => ProductModel.fromJson(e)).toList();
  //     } else {
  //       throw Exception('Failed to load products');
  //     }
  //   } else {
  //     throw Exception('Error ${response.statusCode}: ${response.body}');
  //   }
  // }
// }
