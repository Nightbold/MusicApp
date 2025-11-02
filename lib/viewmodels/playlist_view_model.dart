// viewmodels/playlist_view_model.dart

// ... (importlar)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicapp/data/Models.dart';
import 'package:musicapp/services/auth.dart';
import 'package:musicapp/services/new_database.dart';

class PlaylistViewModel extends ChangeNotifier {
  final Database _databaseService;
  final UserControl _userControl;
  Stream<List<Playlist>>? _playlistsStreamForUI;

  PlaylistViewModel(this._databaseService, this._userControl) {
    _loadPlaylists();
    _runInitialImageCheck();
  }

  Stream<List<Playlist>>? get playlistsStream => _playlistsStreamForUI;
  Future<List<Playlist>> getPlaylistsOnce() async {
    final userId = _userControl.getUSerId();
    if (userId == null) return []; // Kullanıcı yoksa boş liste

    try {
      // Stream'den '.first' almak yerine, doğrudan .get() ile bir kerelik çekelim.
      final snapshot = await _databaseService
          .getUserPlaylistsCollection(); // Database servisine .get() metodu ekleyeceğiz

      final playlists = snapshot.docs
          .map((doc) {
            try {
              return Playlist.fromMap(
                  doc.id, doc.data() as Map<String, dynamic>);
            } catch (e) {
              print(
                  "ViewModel: Playlist parse hatası (getOnce): doc.id=${doc.id}, Hata: $e");
              return null;
            }
          })
          .whereType<Playlist>()
          .toList();

      // Resim kontrolünü burada da yapabiliriz, çünkü bu tek seferlik bir işlem.
      // Kullanıcı dialog'u beklerken resimler ayarlanmış olur.
      await _checkImagesIfNeeded(playlists);

      // Güncellenmiş veriyi (resimlerle birlikte) tekrar çekmek daha garanti olabilir,
      // ama şimdilik bu listeyi döndürelim.
      // VEYA daha iyisi: _checkImagesIfNeeded'den sonra listeyi tekrar çek:
      // if (didUpdate) { ... tekrar çek ... }

      return playlists;
    } catch (e) {
      print("getPlaylistsOnce hatası: $e");
      return []; // Hata durumunda boş liste
    }
  }

  void _loadPlaylists() {
    final userId = _userControl.getUSerId();
    if (userId != null) {
      final firestoreStream = _databaseService.getUserPlaylistsStream();

      // UI için stream'i oluştur (YAN ETKİSİZ!)
      // Bu stream sadece Firestore verisini Playlist nesnelerine çevirir.
      _playlistsStreamForUI = firestoreStream.map((snapshot) {
        print("UI Stream Map çalıştı."); // Debug için
        return snapshot.docs
            .map((doc) {
              try {
                return Playlist.fromMap(doc.id, doc.data());
              } catch (e) {
                print(
                    "ViewModel: Playlist parse hatası: doc.id=${doc.id}, Hata: $e");
                return null;
              }
            })
            .whereType<Playlist>()
            .toList();

        // _checkImagesIfNeeded'i BURADAN KALDIRDIK!
      });

      // Ayrı dinleyiciye de (şimdilik) gerek yok.
      // _firestoreSubscription?.cancel();
      // _firestoreSubscription = firestoreStream.listen((snapshot) { ... });
    } else {
      _playlistsStreamForUI = Stream.value([]);
    }
  }

// YENİ METOT: VM ilk yüklendiğinde bir kerelik resim kontrolü yapar.
  Future<void> _runInitialImageCheck() async {
    final userId = _userControl.getUSerId();
    if (userId == null) return;

    try {
      // Stream'den bir kereliğine veriyi al (get() ile)
      final snapshot = await _databaseService.getUserPlaylistsStream().first;
      final playlists = snapshot.docs
          .map((doc) {
            try {
              return Playlist.fromMap(doc.id, doc.data());
            } catch (e) {
              return null;
            }
          })
          .whereType<Playlist>()
          .toList();

      // Kontrolü sadece bu bir kerelik veri üzerinde yap.
      await _checkImagesIfNeeded(playlists);
      print("İlk resim kontrolü tamamlandı.");
    } catch (e) {
      print("İlk resim kontrolü sırasında hata: $e");
    }
  }

  // Sadece resmi olmayanları kontrol eden metot
  Future<void> _checkImagesIfNeeded(List<Playlist> playlists) async {
    bool didUpdate = false;
    for (var playlist in playlists) {
      if (playlist.firstSongImage == null || playlist.firstSongImage!.isEmpty) {
        await _databaseService
            .controlAndSetPlaylistImageById(playlist.playlistId)
            .catchError((e) => print("Resim kontrol hatası (arka plan): $e"));
        didUpdate = true;
      }
    }
    if (didUpdate) {
      print("Resim kontrolü yapıldı ve güncelleme(ler) tetiklendi.");
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _databaseService.deletePlaylistById(playlistId);
    } catch (e) {/*...*/}
  }

  // Yeni playlist ekleme metodu
  Future<void> createPlaylist(String name) async {
    final trimmedName = name.trim(); // Başındaki/sonundaki boşlukları temizle
    if (name.trim().isEmpty) return; // Boş isim kontrolü
    try {
      await _databaseService.addPlaylist(trimmedName);
      print("Playlist oluşturuldu: $trimmedName");
      // Stream otomatik güncelleyeceği için notifyListeners'a gerek yok.
    } catch (e) {
      print("ViewModel: Playlist oluşturma hatası: $e");
      // Kullanıcıya hata gösterilebilir.
    }
  }

  Future<Map<Playlist, bool>> getPlaylistsWithSongStatus(String songId) async {
    final userId = _userControl.getUSerId();
    if (userId == null) return {}; // Boş map

    try {
      final snapshot = await _databaseService.getUserPlaylistsCollection();

      final Map<Playlist, bool> resultMap = {};

      if (snapshot.docs.isEmpty) {
        return {}; // Hiç playlist yoksa boş map döndür
      }

      // Her playlist için "şarkı içinde mi?" kontrolünü paralel olarak yap
      await Future.wait(snapshot.docs.map((doc) async {
        try {
          final playlist =
              Playlist.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          // Database servisindeki yeni metodu çağır
          final isAdded = await _databaseService.isSongInPlaylist(
              playlist.playlistId, songId);
          resultMap[playlist] = isAdded; // Sonucu map'e ekle
        } catch (e) {
          print("Playlist parse/check hatası (getPlaylistsWithSongStatus): $e");
        }
      }));

      // Resim kontrolünü de yapalım (bu zaten vardı, kalsın)
      await _checkImagesIfNeeded(resultMap.keys.toList());

      return resultMap;
    } catch (e) {
      print("getPlaylistsWithSongStatus hatası: $e");
      return {}; // Hata durumunda boş map
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  // ... (dispose)
}
