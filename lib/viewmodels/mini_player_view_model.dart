// viewmodels/mini_player_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/data/Models.dart';
import 'package:musicapp/services/Spottify.dart';
import 'package:musicapp/services/isolate_helpers.dart';
import 'package:musicapp/services/music_service.dart';
import 'package:musicapp/services/new_database.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotify/spotify.dart' hide PlaybackState;

class MiniPlayerViewModel extends ChangeNotifier {
  final MusicService _musicService;
  final Spottify _spottifyService; // Spottify servisini de alıyoruz
  final Database _dbService; // Spottify servisini de alıyoruz
  Color? dominantColor;
  Color textColor = Colors.white; // Varsayılan olarak beyaz
  //fav
  bool _isCurrentTrackFavorite = false;
  bool get isCurrentTrackFavorite => _isCurrentTrackFavorite;
  StreamSubscription? _favoritesSubscription;

  // UI'ın ihtiyacı olan state'ler
  Track? currentTrack;
  PlaybackState playbackState = PlaybackState.stopped;
  Duration totalDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  bool get isActive => currentTrack != null;
  bool _isLoadingRecommendations = false;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  bool _isFullScreenPlayerVisible = false;
  bool get isFullScreenPlayerVisible => _isFullScreenPlayerVisible;
  int _currentLoadId = 0;
  // Stream aboneliklerini tutmak için
  late final StreamSubscription _trackSubscription;
  late final StreamSubscription _stateSubscription;
  late final StreamSubscription _durationSubscription;
  late final StreamSubscription _positionSubscription;

  MiniPlayerViewModel(
      this._musicService, this._spottifyService, this._dbService) {
    // _musicService.currentTrackStream.listen((track) {
    //   currentTrack = track;
    //   // Yeni bir şarkı geldiğinde, rengi de güncelle.
    //   if (track != null) {
    //     _updateDominantColor(track);
    //     _checkIfFavorite(track.id);
    //   } else {
    //     // Şarkı bitince renkleri varsayılan hale getir
    //     dominantColor = null;
    //     textColor = Colors.white;
    //     _isCurrentTrackFavorite = false;
    //     _favoritesSubscription?.cancel();
    //   }
    //   notifyListeners();
    // });
    // MusicService'ten gelen veri akışlarını dinle
    _trackSubscription = _musicService.currentTrackStream.listen((track) {
      currentTrack = track;
      if (track != null) {
        _updateDominantColor(track);
        _checkIfFavorite(track.id);
        _dbService.addLastplaySong(track!);
      } else {
        // Şarkı bitince renkleri varsayılan hale getir
        dominantColor = null;
        textColor = Colors.white;
        _isCurrentTrackFavorite = false;
        _favoritesSubscription?.cancel();
      }

      notifyListeners();
    });

    _stateSubscription = _musicService.playbackStateStream.listen((state) {
      playbackState = state;
      notifyListeners();
    });

    _durationSubscription = _musicService.durationStream.listen((duration) {
      // just_audio'dan gelen duration null olabilir, bu durumu yönetiyoruz.
      totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _positionSubscription = _musicService.positionStream.listen((position) {
      currentPosition = position;
      notifyListeners();
    });
    _listenToFavorites();
  }

  // Kullanıcı etkileşimlerini doğrudan MusicService'e yönlendir
  void play() => _musicService.play();
  void pause() => _musicService.pause();
  void next() => _musicService.next();
  void previous() => _musicService.previous();
  void seek(Duration position) => _musicService.seek(position);

  //Favorileri dinleyen stream
  void _listenToFavorites() {
    _favoritesSubscription = _dbService.getFavoritesStream().listen((snapshot) {
      if (currentTrack != null) {
        _checkIfFavorite(currentTrack!.id);
      }
    });
  }

  Future<void> _checkIfFavorite(String? trackId) async {
    if (trackId == null) {
      _isCurrentTrackFavorite = false;
      notifyListeners();
      return;
    }

    try {
      bool isFav = await _dbService.isFavorite(trackId);
      if (_isCurrentTrackFavorite != isFav) {
        _isCurrentTrackFavorite = isFav;
        notifyListeners();
      }
    } catch (e) {
      print("favori hata : $e");
      if (_isCurrentTrackFavorite != false) {
        _isCurrentTrackFavorite = false;
        notifyListeners();
      }
    }
  }

  /// Mevcut şarkıyı favorilere ekler.
  Future<void> addCurrentTrackToFavorites() async {
    if (currentTrack == null) return;
    try {
      await _dbService.addFavorite(currentTrack!);
      _isCurrentTrackFavorite =
          true; // State'i manuel güncelle (stream'den de gelecek ama anında tepki için)
      notifyListeners();
    } catch (e) {
      print("Favorilere eklenirken hata: $e");
    }
  }

  /// Mevcut şarkıyı favorilerden çıkarır.
  Future<void> removeCurrentTrackFromFavorites() async {
    if (currentTrack?.id == null) return;
    try {
      await _dbService.deleteFavorite(currentTrack!.id!);
      _isCurrentTrackFavorite = false; // State'i manuel güncelle
      notifyListeners();
    } catch (e) {
      print("Favorilerden çıkarılırken hata: $e");
    }
  }

  /// Mevcut şarkıyı belirtilen playlist'e ekler.
  Future<void> addCurrentTrackToPlaylist(String playlistId) async {
    if (currentTrack == null) return;
    try {
      // Database servisinde addSongToPlaylist String playlistId almalı
      await _dbService.addSongToPlaylist(playlistId, currentTrack!);
      print("Şarkı playlist'e eklendi: ${currentTrack!.name} -> $playlistId");
      // Başarı mesajı gösterilebilir (Snackbar vb.)
    } catch (e) {
      print("Playlist'e eklenirken hata: $e");
      // Hata mesajı gösterilebilir.
    }
  }

  Future<void> removeCurrentTrackFromPlaylist(
      String playlistId, String songId) async {
    await _dbService.deleteSongFromPlaylist(playlistId, songId);
  }

// YENİ EKLENEN METOTLAR: Bu state'i güvenli bir şekilde yönetmek için.
  void showFullScreenPlayer() {
    _isFullScreenPlayerVisible = true;
    notifyListeners();
  }

  void hideFullScreenPlayer() {
    _isFullScreenPlayerVisible = false;
    notifyListeners();
  }

  /// Oynatıcıyı durdurur ve sırayı temizler.
  Future<void> stopAndClear() async {
    // 1. Devam eden tüm MusicService işlemlerini iptal etmesi için haber ver.
    _musicService.cancelOngoingOperations();
    // 2. Mevcut işlem kimliğini geçersiz kıl. Bu, dönen tüm Isolate'lerin
    // sonuçlarının çöpe atılmasını garantiler.
    _currentLoadId++;
    await _musicService.stopAndClearQueue();
    currentTrack = null;
    currentPosition = Duration.zero;
    totalDuration = Duration.zero;
    playbackState = PlaybackState.stopped;
    notifyListeners();
  }

  /// Sadece tek bir şarkıyı veya bir çalma listesini çalmak için kullanılır.
  Future<void> playTracks(List<Track> tracks, {int initialIndex = 0}) async {
    await _musicService.loadPlaylist(tracks, initialIndex: initialIndex);
  }

  // Yeni bir şarkı veya albüm çalmak için
  Future<void> playTrack(Track track) async {
    // Burada isterseniz tüm albümü veya sadece tek bir şarkıyı listeye ekleyebilirsiniz.
    await _musicService.addAndPlay([track]);
  }

  /// ESKİ KODUNUZDAKİ GİBİ: Bir şarkıyı çalar ve ardından önerileri sıraya ekler.
  Future<void> playTrackAndLoadRecommendations(Track track) async {
    // Önce seçilen şarkıyı çalmaya başla (kullanıcı beklemesin)
    await _musicService.loadPlaylist([track]);

    // Arka planda önerileri çekmeye başla
    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      final recommendations = await _spottifyService.getRecommend(
          track.id!, track.artists!.first.id!);

      // Gelen önerileri MusicService'teki sıraya ekle
      // Bu metodun MusicService'e eklenmesi gerekiyor (bkz. Adım 2)
      // await _musicService.addTracksToQueue(recommendations);
    } catch (e) {
      print("Öneriler alınamadı: $e");
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> playAlbumLazily(List<TrackSimple> albumTracks,
      {int initialIndex = 0}) async {
    // --- İPTAL MEKANİZMASI ---
    // Yeni bir işlem başlamadan önce, MusicService'deki tüm eski işlemleri iptal et.
    _musicService.cancelOngoingOperations();
    // Her yeni çalma işlemine benzersiz bir kimlik ata.
    final loadId = ++_currentLoadId;

    // --- AŞAMA 1: ANINDA OYNATMA (SPRINTER ISOLATE İLE) ---
    try {
      // 1. Tıklanan şarkıyı al.
      final tappedTrackSimple = albumTracks[initialIndex];

      // 2. Sprinter Isolate'i çağır ve SADECE bu tek şarkının sonucunu bekle.
      final Track? tappedTrack =
          await compute(fetchSingleTrackInIsolate, tappedTrackSimple);

      // 3. "KILL" MEKANİZMASI: Sprinter dönerken kullanıcı başka bir şeye bastı mı?
      if (loadId != _currentLoadId || tappedTrack == null) {
        print("🗑️ Sprinter'dan gelen eski sonuç iptal edildi.");
        return;
      }

      // 4. SONUÇ BAŞARILI: Hemen çalmaya başla!
      await _musicService.loadPlaylist([tappedTrack]);
      print("🎵 Anında oynatma başarılı!");
    } catch (e) {
      print("❌ Anında oynatma (Sprinter) sırasında hata: $e");
      return; // Hata olursa arka plan işlemine devam etme.
    }

    // --- AŞAMA 2: ARKA PLANDA KUYRUĞU DOLDURMA (MARATONCU ISOLATE İLE) ---
    // İlk şarkı çalmaya başladıktan sonra bu kod çalışır.

    final tracksAfter = albumTracks.sublist(initialIndex + 1);
    final tracksBefore = albumTracks.sublist(0, initialIndex);
    final remainingTracks = [...tracksAfter, ...tracksBefore];

    if (remainingTracks.isEmpty) return; // Yüklenecek başka şarkı yoksa bitir.

    // 2. Maratoncu Isolate'i çağır. Bu sefer sonucunu beklemiyoruz ama bekleyebiliriz de,
    // UI thread'ini zaten bloklamıyor.
    final List<Track> fullRemainingTracks =
        await compute(fetchFullTracksInIsolate, remainingTracks);

    // 3. "KILL" MEKANİZMASI: Maratoncu dönerken kullanıcı başka bir şeye bastı mı?
    if (loadId != _currentLoadId) {
      print("🗑️ Maratoncu'dan gelen eski sonuç iptal edildi.");
      return;
    }

    // 4. Her şey yolundaysa, kalan şarkıları MusicService'teki sıraya ekle.
    if (fullRemainingTracks.isNotEmpty) {
      await _musicService.addTracksToQueue(fullRemainingTracks);
      print(" marathon Albümün geri kalanı sıraya eklendi.");
    }
  }

  void reset() {
    // Bu metodun sorumluluğu artık MusicService'e geçti
  }

  /// List<TrackSimple> alıp, bunları tam Track nesnelerine çevirir ve oynatır.
  Future<void> playTrackSimpleList(List<TrackSimple> trackSimples,
      {int initialIndex = 0}) async {
    // UI'da bir yükleme göstergesi göstermek için state'i güncelleyebiliriz (isteğe bağlı).

    try {
      // Bütün TrackSimple'ları tam Track nesnesine çevirmek için API isteği atıyoruz.
      // `_spottifyService` içinde bu işi yapacak bir yardımcı metot olmalı.
      final fullTracks =
          await _spottifyService.getTracksFromSimple(trackSimples);

      // Artık elimizde List<Track> var, bunu MusicService'e gönderebiliriz.
      await _musicService.loadPlaylist(fullTracks, initialIndex: initialIndex);
    } catch (e) {
      print("TrackSimple'lar tam Track'e çevrilirken hata: $e");
      // Hata durumunda kullanıcıya bilgi verilebilir.
    }
  }

  Future<void> _updateDominantColor(Track track) async {
    final imageUrl = track.album?.images?.first.url;
    if (imageUrl == null) {
      dominantColor = null;
      textColor = Colors.white;
      notifyListeners();
      return;
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100), // Analiz için küçük bir boyut yeterli
      );
      final newDominantColor = paletteGenerator.dominantColor?.color;
      dominantColor = newDominantColor;
      // --- KONTRAST HESAPLAMA ---
      if (newDominantColor != null) {
        // Rengin parlaklığını hesapla (0.0 = siyah, 1.0 = beyaz)
        double luminance = newDominantColor.computeLuminance();

        // Eğer parlaklık 0.5'ten büyükse (yani renk açıksa), yazıyı siyah yap.
        // Değilse (renk koyuysa), yazıyı beyaz yap.
        textColor = luminance > 0.5 ? Colors.black : Colors.white;
      } else {
        // Renk bulunamazsa varsayılan beyaz
        textColor = Colors.white;
      }
      notifyListeners();
    } catch (e) {
      print("Renk paleti oluşturulurken hata: $e");

      dominantColor = null;
      textColor = Colors.white;
      // Hata durumunda varsayılan bir renge dönebiliriz.

      notifyListeners();
    }
  }

  Future<void> playSongModels(List<Song> songs, {int initialIndex = 0}) async {
    _musicService.cancelOngoingOperations();
    final loadId = ++_currentLoadId;

    try {
      // Song ID'lerini al
      final songIds = songs.map((s) => s.songId).toList();
      if (songIds.isEmpty) return;

      // Spottify servisi ile tam Track nesnelerini çek (getTracksByIds gibi bir metot gerekebilir)
      final fullTracks = await _spottifyService.getTracksByIds(songIds);

      if (loadId != _currentLoadId) return; // İptal kontrolü

      // MusicService'e çalma komutunu gönder
      await _musicService.loadPlaylist(fullTracks, initialIndex: initialIndex);
    } catch (e) {
      print("playSongModels hatası: $e");
    }
  }

  @override
  void dispose() {
    // Abonelikleri iptal etmeyi unutmayın!
    _favoritesSubscription?.cancel();
    _trackSubscription.cancel();
    _stateSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }
}
