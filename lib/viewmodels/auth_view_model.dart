// viewmodels/auth_view_model.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/services/auth.dart'; // UserControl servisin
import 'package:musicapp/services/new_database.dart'; // Database servisin (yeni kullanıcı kaydı için)

// Kimlik doğrulama durumlarını netleştirmek için bir enum
enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthViewModel extends ChangeNotifier {
  final UserControl _authService;
  final Database _databaseService; // Belki addUser metodu burada çağrılıyordur
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _user;
  User? get user => _user;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _authStateSubscription;

  AuthViewModel(this._authService, this._databaseService) {
    // Auth state dinleyicisini başlat
    _authStateSubscription =
        _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
    // İlk durumu manuel olarak kontrol et
    _onAuthStateChanged(_firebaseAuth.currentUser);
  }

  // Auth durumu değiştiğinde tetiklenir
  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  // Giriş yapma metodu
  Future<void> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      // UserControl servisindeki login metodunu çağır
      await _authService.login(mail: email, pass: password);
      // Başarılıysa, _onAuthStateChanged dinleyicisi durumu 'authenticated' yapacak.
    } on FirebaseAuthException catch (e) {
      // Hata tipini belirle
      _errorMessage = _translateFirebaseAuthError(e); // Hatayı Türkçeye çevir
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      // Diğer genel hatalar
      _errorMessage = "Bilinmeyen bir hata oluştu.";
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Kayıt olma metodu
  Future<void> signUp(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      // Eski kodun _database.addUser çağırıyordu, ama _usercont.createUser daha mantıklı.
      // Biz UserControl'dekini (authService) kullanalım.
      await _authService.createUser(mail: email, pass: password);
      // Başarılıysa, _onAuthStateChanged dinleyicisi durumu 'authenticated' yapacak.
      // NOT: _authService.createUser'in, Database'e yeni kullanıcı kaydını da yapması gerekir.
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateFirebaseAuthError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Bilinmeyen bir hata oluştu.";
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Çıkış yapma metodu
  Future<void> signOut() async {
    await _authService.signOut();
    // Dinleyici durumu 'unauthenticated' yapacak.
  }

  Future<void> deleteUser() async {
    await _authService.deleteUser();
    // Dinleyici durumu 'unauthenticated' yapacak.
  }

  String _translateFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz.';
      case 'invalid-email':
        return 'Geçersiz e-posta formatı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter olmalı).';
      // ... diğer hata kodları
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Dinleyiciyi kapat
    super.dispose();
  }
}
