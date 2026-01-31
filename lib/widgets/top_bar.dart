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
  final VoidCallback? onLogout;

  const TopBar({
    super.key,
    required this.menus, // List menu dikirim dari luar
    this.searchController,
    this.userName = '',
    this.onLogout,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// LEFT SPACER
          const Spacer(),

          /// MENU NAV (Dinamis berdasarkan List) - CENTERED
          Row(children: menus.map((menu) => _buildItem(menu)).toList()),

          /// RIGHT SPACER + USER INFO
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout' && onLogout != null) {
                      onLogout!();
                    }
                  },
                  offset: const Offset(0, 40),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Logout', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
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
