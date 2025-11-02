// views/SignUpPage.dart

import 'package:flutter/material.dart';
import 'package:musicapp/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() {
    context.read<AuthViewModel>().signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
    // Başarılı olursa, AuthWrapper bizi otomatik olarak Home'a yönlendirecek.
    // Başarısız olursa, errorMessage bu sayfada görünecek.
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthViewModel>().status;
    final errorMessage = context.watch<AuthViewModel>().errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")), // Geri dönebilmek için
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Email ve Şifre TextField'ları)
            TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-posta')),
            SizedBox(height: 16.0),
            TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Şifre'),
                obscureText: true),
            SizedBox(height: 16.0),

            // Hata mesajı
            if (errorMessage != null &&
                authStatus == AuthStatus.unauthenticated)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),

            // Kayıt Ol Butonu
            ElevatedButton(
              onPressed: authStatus == AuthStatus.loading ? null : _signUp,
              child: authStatus == AuthStatus.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
