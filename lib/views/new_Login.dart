// views/LoginPage.dart

import 'package:flutter/material.dart';
import 'package:musicapp/viewmodels/auth_view_model.dart';
import 'package:musicapp/views/new_signup.dart'; // Kayıt ol sayfası
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    // ViewModel'dan 'read' ile metodu çağır, UI'ı yeniden çizme
    context.read<AuthViewModel>().signIn(
          _emailController.text.trim(), // Boşlukları temizle
          _passwordController.text.trim(),
          // Eski kodun context istiyordu
        );
  }

  @override
  Widget build(BuildContext context) {
    // Hata mesajlarını ve yüklenme durumunu 'watch' ile dinle
    final authStatus = context.watch<AuthViewModel>().status;
    final errorMessage = context.watch<AuthViewModel>().errorMessage;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Email ve Şifre TextField'ları aynı)
            TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-posta')),
            SizedBox(height: 16.0),
            TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Şifre'),
                obscureText: true),
            SizedBox(height: 16.0),

            // Hata mesajı alanı
            if (errorMessage != null &&
                authStatus == AuthStatus.unauthenticated)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),

            // Giriş Butonu
            ElevatedButton(
              // Yüklenme durumunda butonu devre dışı bırak
              onPressed: authStatus == AuthStatus.loading ? null : _signIn,
              child: authStatus == AuthStatus.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Giriş Yap"),
            ),

            // Kayıt ol sayfasına yönlendirme
            TextButton(
              onPressed: authStatus == AuthStatus.loading
                  ? null
                  : () {
                      // Manuel push(userlog()) YERİNE sadece kayıt sayfasına git
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
              child: const Text("Hesabın yok mu? Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}
