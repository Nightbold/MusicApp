// services/music_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify/spotify.dart';
import 'dart:async';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Oynatıcının durumlarını temsil eden basit bir enum
enum PlaybackState { playing, paused, stopped, loading, completed }

class MusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  // 2. HIVE KUTUSUNU (NOT DEFTERİNİ) Tanimla
  final Box _urlCacheBox = Hive.box('youtubeUrls');

  final List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isLoadOperationCancelled = false;

// just_audio'nun güçlü çalma listesi yöneticisi.
  ConcatenatingAudioSource? _playlist;

  // Dışarıdan dinlenebilecek veri akışları (Stream'ler).
  final StreamController<PlaybackState> _playbackStateController =
      StreamController.broadcast();
  final StreamController<Track?> _currentTrackController =
      StreamController.broadcast();

  Stream<PlaybackState> get playbackStateStream =>
      _playbackStateController.stream;
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  final StreamController<Duration> _durationController =
      StreamController.broadcast();

  MusicService() {
    _audioPlayer.setLoopMode(LoopMode.all);
    // Oynatıcının kendi durum değişikliklerini dinleyip kendi stream'imize aktarıyoruz.
    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        _playbackStateController.add(PlaybackState.playing);
      } else {
        _playbackStateController.add(PlaybackState.paused);
      }

      // Şarkı bittiğinde 'completed' durumunu yayınlıyoruz.
      if (state.processingState == ProcessingState.completed) {
        _playbackStateController.add(PlaybackState.completed);
        // Otomatik olarak sıradakine geçmesini `just_audio` kendisi halleder.
      }
    });

    // Çalan şarkının indeksi değiştiğinde bunu dinliyoruz.
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _playlist != null) {
        // Çalma listesindeki yeni şarkının meta verisini (tag) alıp yayınlıyoruz.
        final track = (_playlist!.sequence[index].tag as Track);
        _currentTrackController.add(track);
      }
    });
  }
  void cancelOngoingOperations() {
    print("🛑 Yükleme işlemleri iptal ediliyor.");
    _isLoadOperationCancelled = true;
  }

  /// YOUTUBE'DAN SES URL'Sİ BULAN YARDIMCI METOT
  Future<Uri?> _getYoutubeAudioUrl(Track track) async {
    final spotifyId = track.id;

    if (spotifyId == null || spotifyId.isEmpty) {
      print("Geçersiz trackId, önbellekleme yapılamıyor.");
      return null; // ID yoksa işlem yapma
    }
    // --- 1. ADIM: ÖNCE ÖNBELLEĞİ KONTROL ET (Cache Hit) ---
    if (_urlCacheBox.containsKey(spotifyId)) {
      final cachedData = _urlCacheBox.get(spotifyId) as Map?;
      if (cachedData != null) {
        try {
          final String cachedUrl = cachedData['url'];

          // Kayıtlı son kullanma tarihini (saniye olarak) al
          final int expiryTimestamp = cachedData['expires_at_timestamp'];

          // --- 2. ADIM: GEÇERLİLİĞİNİ KONTROL ET ---
          // Şu anki zamanı al (saniye olarak)
          final int currentTimestamp =
              DateTime.now().millisecondsSinceEpoch ~/ 1000;

          // Kayıtlı tarih, şu anki tarihten büyük mü (yani hala gelecekte mi)?
          if (expiryTimestamp > currentTimestamp) {
            print('✅ URL önbellekten (geçerli) bulundu: ${track.name}');
            return Uri.parse(cachedUrl);
          } else {
            print('⚠️ Önbellekteki URL\'nin süresi dolmuş: ${track.name}');
          }
        } catch (e) {
          print("Önbellek verisi bozuk, yeniden çekilecek: $e");
        }
      }
    }
    // --- 2. ADIM: ÖNBELLEKTE YOKSA, YOUTUBE'DAN ARA (Cache Miss) ---
    print('⚠️ URL önbellekte yok, YouTube\'dan aranıyor: ${track.name}');
    try {
      final searchQuery = "${track.name} ${track.artists?.first.name}";
      final video = (await _youtubeExplode.search.search(searchQuery)).first;

      // getManifest metodu doğru şekilde video ID'sini alıyor (video.id.value).
      final manifest = await _youtubeExplode.videos.streams.getManifest(
          video.id.value,
          // You can also pass a list of preferred clients, otherwise the library will handle it:
          ytClients: [
            YoutubeApiClient.ios,
            YoutubeApiClient.androidVr,
          ]);

      // ADIM 1: Önce Stream bilgisini bir değişkene atıyoruz.
      // Önce mp4 formatında en yüksek kaliteli sesi arıyoruz.
      var streamInfo = manifest.audioOnly
          .where((e) => e.container.name == 'mp4')
          .withHighestBitrate();

// ADIM 2: Null olup olmadığını kontrol ediyoruz.
      // Eğer mp4 formatında ses bulunamazsa, format fark etmeksizin ilk bulduğunu alıyoruz.
      streamInfo ??= manifest.audioOnly.withHighestBitrate();
// ADIM 3: Stream bilgisi hala null değilse, URL'sini döndürüyoruz.
      if (streamInfo != null) {
        final url = streamInfo.url;

        DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(
            int.parse(streamInfo.url.queryParameters["expire"].toString()) *
                1000);

// --- 2. ADIM: YENİ BİLGİYİ MAP OLARAK KAYDET ---
        final Map<String, dynamic> dataToCache = {
          'url': url.toString(),
          // Tarihi, saniye cinsinden Unix timestamp'a (int) çevirip kaydediyoruz.
          'expires_at_timestamp': expiresAt.millisecondsSinceEpoch ~/ 1000,
        };

        // --- 3. ADIM: YENİ BULUNAN URL'Yİ ÖNBELLEĞE KAYDET ---
        print('🔗 Yeni URL bulundu ve önbelleğe kaydediliyor: ${track.name}');
        await _urlCacheBox.put(spotifyId, dataToCache);
        print(
            '🔗 Yeni URL bulundu ve son kullanma tarihiyle (timestamp) kaydedildi: ${track.name}');
        return streamInfo.url;
      } else {
        // Bu duruma düşmesi çok nadirdir ama yine de bir güvenlik önlemi.
        print('Şarkı için HİÇBİR ses akışı bulunamadı: ${track.name}');
        return null;
      }
    } catch (e) {
      print('Şarkı için YouTube URL bulunamadı: ${track.name} - Hata: $e');
      return null;
    }
  }

  /// Oynatıcıyı durdurur ve tüm çalma listesini temizler.
  Future<void> stopAndClearQueue() async {
    _isLoadOperationCancelled =
        true; // YENİ EKLENEN SATIR: Herhangi bir yüklemeyi iptal et.
    await _audioPlayer.stop();
    await _playlist?.clear(); // Çalma listesini boşalt

    _playlist = null; // Playlist referansını temizle
    _currentIndex = -1;

    // Durumu dinleyen herkese haber ver
    _currentTrackController.add(null); // Mevcut şarkı artık yok
    _playbackStateController.add(PlaybackState.stopped); // Durum "durduruldu"
    // Oynatıcının mevcut durumunu kontrol ederek gerçekten durduğundan emin olabiliriz (İsteğe bağlı, just_audio genellikle doğru çalışır)
    if (_audioPlayer.playing) {
      // Eğer hala çalıyorsa, tekrar durdurmaya zorla.
      await _audioPlayer.pause();
    }
  }

  /// Verilen bir Track için çalınabilir bir AudioSource oluşturan metot.
  Future<AudioSource?> _createAudioSource(Track track) async {
    if (_isLoadOperationCancelled) return null;
    final audioUrl = await _getYoutubeAudioUrl(track);
    if (audioUrl == null) return null;

    // `tag` özelliği, bu ses kaynağına istediğimiz herhangi bir meta veriyi
    // (bizim durumumuzda tüm Track nesnesini) eklememizi sağlar.
    return AudioSource.uri(
      audioUrl,
      tag: track,
    );
  }

  /// Yeni bir çalma listesi yükler ve belirtilen indeksten çalmaya başlar.
  Future<void> loadPlaylist(List<Track> tracks, {int initialIndex = 0}) async {
    _playbackStateController.add(PlaybackState.loading);
    _isLoadOperationCancelled =
        false; // YENİ EKLENEN SATIR: Yeni işlem başlıyor, bayrağı sıfırla.

    // --- YENİ VE KRİTİK ADIM: ÖNCE HABER VER ---
    // Ağır işe başlamadan önce, çalınacak olan ilk şarkıyı ViewModel'a hemen bildir.
    // Bu, UI'ın anında güncellenmesini sağlar.
    final initialTrack = tracks[initialIndex];
    _currentTrackController.add(initialTrack);
    // `Future.wait` kullanmak yerine, iptali kontrol edebilmek için döngü kullanmak daha güvenli olabilir.
    List<AudioSource> audioSources = [];
    for (var track in tracks) {
      // KONTROL: Her şarkıyı işlemeden önce iptal durumunu kontrol et.
      if (_isLoadOperationCancelled) {
        print("Playlist yüklemesi döngü içinde iptal edildi.");
        _playbackStateController.add(PlaybackState.stopped);
        return;
      }
      final source = await _createAudioSource(track);
      if (source != null) {
        audioSources.add(source);
      }
    }

// YENİ EKLENEN KONTROL BLOĞU
    // Ses kaynakları hazırlanırken kullanıcı işlemi iptal etti mi?
    if (_isLoadOperationCancelled) {
      print("Yükleme işlemi kullanıcı tarafından iptal edildi.");
      _playbackStateController
          .add(PlaybackState.stopped); // Durumu 'durduruldu' yap
      return; // Metoddan çık, oynatıcıya dokunma.
    }
    if (audioSources.isEmpty) {
      print("Çalınabilecek hiçbir şarkı bulunamadı.");
      _playbackStateController.add(PlaybackState.stopped);
      return;
    }

    // Yeni çalma listesini oluştur.
    _playlist = ConcatenatingAudioSource(children: audioSources);

    try {
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: initialIndex);
      play();
    } catch (e) {
      print("Hata: Çalma listesi oynatıcıya yüklenemedi - $e");
      _playbackStateController.add(PlaybackState.stopped);
    }
  }

  Future<void> addAndPlay(List<Track> tracks, {int initialIndex = 0}) async {
    _isLoadOperationCancelled = false;
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = initialIndex;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    _playbackStateController.add(PlaybackState.loading);
    final track = _queue[_currentIndex];
    _currentTrackController.add(track);

    // Gerçek şarkı URL'sini burada bir servisten almanız gerekir.
    // Şimdilik just_audio'nun sahte URL'sini kullanıyorum. Siz kendi YouTube/Spotify URL çözümünüzü entegre etmelisiniz.
    try {
      final source = await _createAudioSource(track);
      // YENİ EKLENEN KONTROL BLOĞU
      // URL çekilirken kullanıcı işlemi iptal etti mi?
      if (_isLoadOperationCancelled) {
        print(
            "Yükleme işlemi (_playCurrent) kullanıcı tarafından iptal edildi.");
        _playbackStateController
            .add(PlaybackState.stopped); // Durumu 'durduruldu' yap
        return; // Metoddan çık, oynatıcıya dokunma.
      }
      // Kaynak null ise hata yönetimi (daha güvenli kod için)
      if (source == null) {
        print("Hata: Şarkı için kaynak oluşturulamadı - ${track.name}");
        _playbackStateController.add(PlaybackState.stopped);
        return;
      }
      await _audioPlayer.setAudioSource(source!);
      play();
    } catch (e) {
      print("Hata: Şarkı yüklenemedi - $e");
      _playbackStateController.add(PlaybackState.stopped);
    }
  }

  /// Mevcut çalma listesinin sonuna yeni şarkılar ekler.
  Future<void> addTracksToQueue(List<Track> tracks) async {
    if (_playlist == null) {
      // Eğer henüz bir liste yoksa, bu yeni bir liste başlatır.
      await loadPlaylist(tracks);
      return;
    }
// `for` döngüsü, her adımda iptal bayrağını kontrol etmemizi sağlayarak
    // `Future.wait`'ten daha güvenli bir yapı sunar.
    List<AudioSource> audioSources = [];
    for (var track in tracks) {
      // 2. KONTROL: Döngünün her başında iptal bayrağını kontrol et.
      if (_isLoadOperationCancelled || _playlist == null) {
        print("Sıraya ekleme işlemi döngü içinde iptal edildi.");
        return;
      }
      final source = await _createAudioSource(track);
      if (source != null) {
        audioSources.add(source);
      }
    }
    // // Gelen her bir şarkı için ses kaynağı oluştur.
    // final audioSources = (await Future.wait(tracks.map(_createAudioSource)))
    //     .where((source) => source != null)
    //     .cast<AudioSource>()
    //     .toList();
    if (_isLoadOperationCancelled || _playlist == null) {
      print("Sıraya ekleme işlemi listeye eklenmeden önce iptal edildi.");
      return;
    }
    // Tüm kontrollerden geçtiyse, artık _playlist'i güvenle kullanabiliriz.
    if (audioSources.isNotEmpty) {
      await _playlist!.addAll(audioSources);
    }
  }

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void seek(Duration position) => _audioPlayer.seek(position);
// `ConcatenatingAudioSource` sayesinde sonraki/önceki şarkıya geçmek çok kolay.
  Future<void> next() async => _audioPlayer.seekToNext();
  Future<void> previous() async => _audioPlayer.seekToPrevious();

  void dispose() {
    _audioPlayer.dispose();
    _youtubeExplode.close();
    _playbackStateController.close();
    _currentTrackController.close();
  }
}
