import 'package:flutter/material.dart';
import 'package:musicapp/services/Spottify.dart';
import 'package:spotify/spotify.dart';

enum ViewState { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final Spottify _spotifyService = Spottify();

  List<Album> _newReleases = [];
  List<Category> _categories = [];
  ViewState _state = ViewState.idle;

// UI'ın erişeceği getter'lar
  List<Album> get newReleases => _newReleases;
  List<Category> get categories => _categories;
  ViewState get state => _state;

  HomeViewModel() {
    // ViewModel oluşturulduğunda verileri çek
    fetchHomePageData();
  }
  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners(); // Değişiklikleri dinleyen widget'ları uyar
  }

  Future<void> fetchHomePageData() async {
    _setState(ViewState.loading);
    try {
      // Future.wait ile iki isteği aynı anda atarak zaman kazan
      final results = await Future.wait([
        _spotifyService.getNewReleases(),
        _spotifyService.getCategories(),
      ]);

      // 1. Gelen dinamik listeyi 'List' olarak al.
      final newReleasesData = results[0] as List;
      // 2. Her bir elemanı 'AlbumSimple'a çevirerek yeni bir liste oluştur.
      _newReleases = newReleasesData
          .map((item) => Album.fromJson(item as Map<String, dynamic>))
          .toList();
      // "Hindi" kategorisini filtrele
      // Aynı işlemi kategoriler için de yapalım
      final categoriesData = results[1] as List;
      var allCategories = categoriesData
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();

      _categories = allCategories.where((cat) => cat.name != "Hindi").toList();
      _setState(ViewState.success);
    } catch (e) {
      print("Hata oluştu: $e");
      _setState(ViewState.error);
    }
  }
}
