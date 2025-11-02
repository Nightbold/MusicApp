// viewmodels/favorites_view_model.dart

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:musicapp/services/new_database.dart';
import 'package:musicapp/services/auth.dart';
import 'package:musicapp/data/Models.dart' as mymodel; // Senin Song modelin

class FavoritesViewModel extends ChangeNotifier {
  final Database _databaseService;
  final UserControl _userControl;

  Stream<List<mymodel.Song>>? _favoritesStream;

  FavoritesViewModel(this._databaseService, this._userControl) {
    _loadFavorites();
  }

  Stream<List<mymodel.Song>>? get favoritesStream => _favoritesStream;

  void _loadFavorites() {
    final userId = _userControl.getUSerId();
    if (userId != null) {
      // Database servisindeki favori stream'ini al (getFavoritesStream)
      _favoritesStream = _databaseService.getFavoritesStream().map((snapshot) {
        // Gelen QuerySnapshot'ı List<mymodel.Song>'a çevir
        return snapshot.docs
            .map((doc) {
              try {
                // Senin Song modelindeki fromMap veya benzeri bir metodu kullan
                return mymodel.Song.fromMap(doc.data());
              } catch (e) {
                print("Favori şarkı parse hatası: doc.id=${doc.id}, Hata: $e");
                return null;
              }
            })
            .whereType<mymodel.Song>()
            .toList(); // null olmayanları al
      });
    } else {
      _favoritesStream = Stream.value([]); // Kullanıcı yoksa boş liste
    }
  }

  /// Belirtilen şarkıyı favorilerden çıkarır.
  Future<void> removeFavorite(String trackId) async {
    try {
      // Database servisindeki metodu çağır
      await _databaseService.deleteFavorite(trackId);
      print("ViewModel: Favori silindi: $trackId");
      // Stream otomatik güncelleyecektir.
    } catch (e) {
      print("ViewModel: Favori silinirken hata: $e");
      // Hata mesajı gösterilebilir.
    }
  }
}
