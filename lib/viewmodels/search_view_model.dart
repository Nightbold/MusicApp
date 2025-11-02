// viewmodels/search_view_model.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicapp/services/Spottify.dart';
import 'package:spotify/spotify.dart';

// Arama durumlarını yönetmek için bir enum
enum SearchState { idle, loading, success, error, empty }

class SearchViewModel extends ChangeNotifier {
  final Spottify _spottifyService;

  // --- State'ler ---
  String _query = ''; // Arama metni
  SearchType _selectedType =
      SearchType.track; // Seçili filtre (varsayılan: track)
  SearchState _searchState = SearchState.idle; // Arama durumu
  List<dynamic> _results =
      []; // Arama sonuçları (Track, Artist, PlaylistSimple olabilir)
  String? _errorMessage; // Hata mesajı
  Timer? _debounce; // Debounce için Timer nesnesi
  // --- UI'ın Erişeceği Getter'lar ---
  String get query => _query;
  SearchType get selectedType => _selectedType;
  SearchState get searchState => _searchState;
  List<dynamic> get results => _results;
  String? get errorMessage => _errorMessage;

  // ViewModel oluşturulurken Spottify servisini alır.
  SearchViewModel(this._spottifyService);

  // --- Metotlar ---
  @override
  void dispose() {
    // TODO: implement dispose
    _debounce?.cancel();
    super.dispose();
  }

  /// Arama metnini günceller ve (isteğe bağlı) hemen arama yapabilir.
  /// Debounce (kısa bekleme) eklemek performansı artırabilir.
  void updateQuery(String newQuery) {
    if (_query == newQuery) return; // Değişiklik yoksa bir şey yapma
    _query = newQuery;
    notifyListeners();
// --- DEBOUNCE MANTIĞI ---
    // Eğer çalışan bir timer varsa, onu iptal et.
    _debounce?.cancel();
    // Kullanıcı yazmayı bıraktığında arama yapmak daha iyi olabilir,
    // şimdilik her harfte arama yapmıyoruz, butona basılınca yapacağız.

    // Sorgu boşaldıysa sonuçları temizle
    // Eğer sorgu boş değilse, yeni bir timer başlat.
    if (_query.isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        // 500ms beklendikten sonra otomatik arama yap.
        search();
      });
    } else {
      // Sorgu boşsa sonuçları hemen temizle.
      _results = [];
      _searchState = SearchState.idle;
      notifyListeners();
    }
  }

  /// Seçili arama filtresini günceller ve yeni filtreyle arama yapar.
  void setSelectedType(SearchType newType) {
    if (_selectedType == newType) return; // Değişiklik yoksa bir şey yapma
    _selectedType = newType;
    notifyListeners(); // FilterChip'lerin güncellenmesi için

    // Filtre değiştiğinde otomatik arama yap
    search();
  }

  /// Mevcut sorgu ve filtre ile Spotify'da arama yapar.
  Future<void> search({bool triggeredByButton = false}) async {
// Eğer butona basıldıysa veya Enter yapıldıysa, debounce timer'ını iptal et.
    if (triggeredByButton) {
      _debounce?.cancel();
    }
    if (_query.isEmpty) {
      _results = [];
      _searchState = SearchState.idle;
      notifyListeners();
      return;
    }

    _searchState = SearchState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Spottify servisindeki arama metodunu çağırıyoruz.
      // Bu metodun List<dynamic> döndürdüğünü varsayıyoruz.
      final searchResults =
          await _spottifyService.search(_query, _selectedType);

      if (searchResults.isEmpty) {
        _searchState = SearchState.empty;
      } else {
        _results = searchResults;
        _searchState = SearchState.success;
      }
    } catch (e) {
      print("Arama sırasında hata: $e");
      _errorMessage = "Arama sırasında bir hata oluştu.";
      _searchState = SearchState.error;
    } finally {
      notifyListeners(); // Sonucu veya hatayı UI'a bildir
    }
  }
}
