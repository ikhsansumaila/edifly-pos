import 'package:flutter/material.dart';

/// Class model untuk item menu agar tiap menu punya aksi unik
class TopBarMenuModel {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  TopBarMenuModel({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });
}

class TopBar extends StatelessWidget {
  final List<TopBarMenuModel> menus;
  final TextEditingController? searchController;
  final String userName;

  const TopBar({
    super.key,
    required this.menus, // List menu dikirim dari luar
    this.searchController,
    this.userName = 'Kasir Bella Terra',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFE6ECEC),
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          /// SEARCH SECTION
          Expanded(
            flex: 3,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk / pesanan...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconColor: Colors.grey,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// MENU NAV (Dinamis berdasarkan List)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: menus.map((menu) => _buildItem(menu)).toList()),
            ),
          ),

          const SizedBox(width: 12),

          /// USER INFO
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(TopBarMenuModel menu) {
    return InkWell(
      onTap: menu.onTap, // Menggunakan fungsi unik tiap menu
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(menu.icon, size: 22, color: menu.isActive ? Colors.black : Colors.black45),
            const SizedBox(height: 4),
            Text(
              menu.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: menu.isActive ? FontWeight.bold : FontWeight.normal,
                color: menu.isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
