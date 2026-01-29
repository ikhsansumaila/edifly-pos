import 'dart:ui';

import 'package:flutter/material.dart';

class PosLoginPage extends StatefulWidget {
  const PosLoginPage({super.key});

  @override
  State<PosLoginPage> createState() => _PosLoginPageState();
}

class _PosLoginPageState extends State<PosLoginPage> {
  bool _obscure = true;
  String _selectedOutlet = 'Bella Terra';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_cafe.jpg', fit: BoxFit.cover),

          Container(color: Colors.black.withValues(alpha: 0.35)),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.88, // ⬅️ kunci anti overflow
              ),
              child: SizedBox(
                width: size.width * 0.42,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: _buildScrollableForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👇 Scroll hanya di dalam card
  Widget _buildScrollableForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),

            _label('Alamat Email'),
            _input(hint: 'kasir@acm.com', icon: Icons.email_outlined),

            const SizedBox(height: 10),

            _label('Kata Sandi'),
            _passwordField(),

            const SizedBox(height: 10),

            _label('Outlet'),
            _outletField(),

            const SizedBox(height: 10),

            _label('CAPTCHA'),
            _captchaRow(),

            const SizedBox(height: 18),

            _loginButton(),

            const SizedBox(height: 14),

            _demoInfo(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storefront, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Text(
              'POS Retail 1.0',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22, // ⬅️ dikompres
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return TextField(
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(
        hint: '••••••••',
        icon: Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  Widget _outletField() {
    return DropdownButtonFormField<String>(
      value: _selectedOutlet,
      isDense: true,
      dropdownColor: const Color(0xFF3A2E23),
      style: const TextStyle(color: Colors.white),
      items:
          ['Bella Terra', 'Central Park', 'Mall Taman Anggrek']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _selectedOutlet = v!),
      decoration: _decoration(),
    );
  }

  Widget _captchaRow() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          child: const Text(
            '2873',
            style: TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(hint: 'CAPTCHA'),
          ),
        ),
      ],
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 42, // ⬅️ lebih kecil
      child: ElevatedButton(
        onPressed: () {},
        child: const Text('Masuk', style: TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _demoInfo() {
    return Text(
      'Demo Credentials\n'
      'Admin: admin@acm.com\n'
      'Kasir: kasir@acm.com\n'
      'Password: 12345678',
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10.5),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
      ),
    );
  }

  Widget _input({String? hint, IconData? icon}) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(hint: hint, icon: icon),
    );
  }

  InputDecoration _decoration({String? hint, IconData? icon, Widget? suffix}) {
    return InputDecoration(
      isDense: true, // ⬅️ penting!
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 20) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
