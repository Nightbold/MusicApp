// services/Database.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:musicapp/data/Models.dart' as mymodel;
import 'package:musicapp/services/auth.dart';
import 'package:spotify/spotify.dart';

class Database {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserControl ucontrol; // Doğrudan kullanabiliriz

  Database(this.ucontrol);
  // Ana koleksiyon referansını al
  CollectionReference _usersCollection() {
    return _firestore.collection("Users");
  }

  // Kullanıcının playlist koleksiyon referansını al
  CollectionReference _playlistsCollection() {
    final userId = ucontrol.getUSerId();
    if (userId == null) throw Exception("Kullanıcı ID'si alınamadı!");
    // Koleksiyon adını 'playlists' yapalım (tutarlılık için)
    return _usersCollection().doc(userId).collection("playlists");
  }

  // --- Playlist Metotları ---

  /// Kullanıcının çalma listelerini dinlemek için stream döndürür.
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPlaylistsStream() {
    // Doğrudan Map<String, dynamic> döndürelim, ViewModel çevirsin.
    return _playlistsCollection().snapshots()
        as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  /// Yeni bir çalma listesi ekler ve eklenen listeyi döndürür.
  Future<mymodel.Playlist> addPlaylist(String playlistName) async {
    try {
      // Yeni doküman referansı oluştur (ID otomatik atanacak)
      final newPlaylistRef = _playlistsCollection().doc();
      final newPlaylist = mymodel.Playlist(
        playlistId: newPlaylistRef.id, // Atanan ID'yi kullan
        playlistName: playlistName,
        songs: [], // Başlangıçta boş
      );
      // Firestore'a yaz
      await newPlaylistRef.set(newPlaylist.toFirestore());
      print("Playlist eklendi: $playlistName (ID: ${newPlaylist.playlistId})");
      return newPlaylist;
    } catch (e) {
      print("Playlist eklenirken hata: $e");
      rethrow;
    }
  }

  /// Playlist'i ID'sine göre siler.
  Future<void> deletePlaylistById(String playlistId) {
    print("Playlist siliniyor (ID'ye göre): $playlistId");
    try {
      return _playlistsCollection().doc(playlistId).delete();
    } catch (e) {
      print("Playlist silinirken hata: $e");
      rethrow;
    }
  }

  /// Playlist'in adını günceller.
  Future<void> updatePlaylistName(String playlistId, String newName) {
    print("Playlist adı güncelleniyor: $playlistId -> $newName");
    try {
      return _playlistsCollection()
          .doc(playlistId)
          .update({'playlistName': newName});
    } catch (e) {
      print("Playlist adı güncellenirken hata: $e");
      rethrow;
    }
  }

  /// Playlist'in ilk şarkı resmini ayarlar veya günceller.
  Future<void> setPlaylistFirstImage(String playlistId, String? imageUrl) {
    print("Playlist resmi ayarlanıyor: $playlistId -> $imageUrl");
    try {
      return _playlistsCollection()
          .doc(playlistId)
          .update({'firstSongImage': imageUrl});
    } catch (e) {
      print("Playlist resmi ayarlanırken hata: $e");
      rethrow;
    }
  }

  ///Kullanıcının playlist'lerini BİR KERELİĞİNE çeker.
  Future<QuerySnapshot<Map<String, dynamic>>>
      getUserPlaylistsCollection() async {
    try {
      return await _playlistsCollection().get()
          as QuerySnapshot<Map<String, dynamic>>;
    } catch (e) {
      print("Playlist'ler (get) alınırken hata: $e");
      rethrow;
    }
  }
  // --- Şarkı Metotları (Playlist İçin) ---

  /// Belirli bir playlist ID'sine ait şarkıların stream'ini döndürür.
  Stream<QuerySnapshot<Map<String, dynamic>>> getSongsStreamForPlaylist(
      String playlistId) {
    return _playlistsCollection()
        .doc(playlistId)
        .collection("songs")
        .snapshots(); // Alt koleksiyon adı: songs
  }

  /// Belirtilen playlist'e bir şarkı ekler.
  Future<void> addSongToPlaylist(String playlistId, Track track) async {
    try {
      // Track'i kendi Song modelimize çevirelim
      final song = mymodel.Song.fromTrack(track);
      // Şarkıyı playlist'in 'songs' alt koleksiyonuna ekle (ID olarak şarkı ID'sini kullan)
      await _playlistsCollection()
          .doc(playlistId)
          .collection("songs")
          .doc(song.songId)
          .set(song.toFirestore());

      // Playlist'in ilk resmini kontrol et/ayarla
      await controlAndSetPlaylistImageById(playlistId);

      print("Şarkı eklendi: ${song.songName} -> Playlist ID: $playlistId");
    } catch (e) {
      print("Playlist'e şarkı eklenirken hata: $e");
      rethrow;
    }
  }

  /// Belirtilen playlist'ten bir şarkıyı siler.
  Future<void> deleteSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _playlistsCollection()
          .doc(playlistId)
          .collection("songs")
          .doc(songId)
          .delete();

      // Playlist'in ilk resmini tekrar kontrol et/ayarla (ilk şarkı silinmiş olabilir)
      await controlAndSetPlaylistImageById(playlistId);

      print("Şarkı silindi: $songId <- Playlist ID: $playlistId");
    } catch (e) {
      print("Playlist'ten şarkı silinirken hata: $e");
      rethrow;
    }
  }

  // --- Playlist Resim Kontrol Metodu ---
  /// Playlist'in ilk şarkı resmini kontrol eder ve gerekirse ayarlar.
  Future<void> controlAndSetPlaylistImageById(String playlistId) async {
    final playlistDocRef = _playlistsCollection().doc(playlistId);
    final playlistSnapshot = await playlistDocRef.get();
    final playlistData = playlistSnapshot.data() as Map<String, dynamic>?;

    // Playlist yoksa veya silinmişse işlemi durdur
    if (playlistData == null) return;

    // --- ESKİ 'IF' KOŞULU KALDIRILDI ---
    // Artık 'firstSongImage' dolu olsa bile kontrol ediyoruz.

    // 1. Olması gereken resmi bul
    final songsCollection = playlistDocRef.collection("songs");
    // (Burada sıralamayı 'eklenme tarihi' gibi bir alana göre yapabilirsin,
    // şimdilik limit(1) ilkini getirecektir)
    final songSnapshot = await songsCollection.limit(1).get();

    String? newFirstImage; // Varsayılan: null (Eğer şarkı kalmadıysa)
    if (songSnapshot.docs.isNotEmpty) {
      // Şarkı Varsa: O şarkının resmini al
      final firstSongData = songSnapshot.docs.first.data();
      newFirstImage = firstSongData['songImage'] as String?;
    }

    // 2. Mevcut resmi al
    final String? currentFirstImage = playlistData['firstSongImage'] as String?;

    // 3. Sadece bir değişiklik varsa (mevcut resim ile olması gereken resim
    //    birbirinden farklıysa) güncelle.
    if (newFirstImage != currentFirstImage) {
      print(
          "Playlist resmi güncelleniyor. Eski: $currentFirstImage, Yeni: $newFirstImage");
      await setPlaylistFirstImage(playlistId, newFirstImage);
    }
  }

  // --- Diğer Metotlar (LastPlayed, Favorites vb.) ---
  // Bunları da benzer şekilde, doğru referansları kullanarak ve
  // try-catch ekleyerek güncelleyebilirsin. Örnek:

  void addLastplaySong(Track track) {
    try {
      final userId = ucontrol.getUSerId();
      if (userId == null) return;
      final userlastcol =
          _usersCollection().doc(userId).collection("LastPlayed");
      final userlastdoc =
          userlastcol.doc(track.id); // Şarkı ID'sini doküman ID yapalım

      DateTime now = DateTime.now();
      Map<String, dynamic> songData = {
        'songArtist': track.artists?.first.name, // Null check
        'songId': track.id,
        'songImage': track.album?.images?.first.url, // Null check
        'songName': track.name,
        'playdate':
            Timestamp.fromDate(now), // Firestore Timestamp kullanmak daha iyi
      };
      userlastdoc.set(songData);
    } catch (e) {
      print("Son çalınan eklenirken hata: $e");
    }
  }

  Future<void> addFavorite(Track track) async {
    try {
      final userId = ucontrol.getUSerId();
      if (userId == null) return;
      final favDocRef =
          _usersCollection().doc(userId).collection("Favorites").doc(track.id);
      final song = mymodel.Song.fromTrack(track);
      await favDocRef.set(song.toFirestore());
    } catch (e) {
      print("Favori eklenirken hata: $e");
    }
  }

  Future<void> deleteFavorite(String trackId) async {
    try {
      final userId = ucontrol.getUSerId();
      if (userId == null) return;
      await _usersCollection()
          .doc(userId)
          .collection("Favorites")
          .doc(trackId)
          .delete();
    } catch (e) {
      print("Favori silinirken hata: $e");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFavoritesStream() {
    final userId = ucontrol.getUSerId();
    if (userId == null) {
      // Return an empty stream of the expected generic type when there's no user.
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _usersCollection().doc(userId).collection("Favorites").snapshots()
        as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  /// Belirli bir şarkının, belirli bir playlist'te olup olmadığını kontrol eder.
  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    // songId'nin boş olup olmadığını kontrol et (önlem)
    if (songId.isEmpty) return false;

    try {
      final doc =
          await _playlistsCollection() // "plm" veya "playlists" koleksiyonun
              .doc(playlistId)
              .collection("songs") // "songs" veya "Songs" alt koleksiyonun
              .doc(songId)
              .get();

      // Doküman varsa true, yoksa false döndür
      return doc.exists;
    } catch (e) {
      print("isSongInPlaylist hatası: $e");
      return false; // Hata durumunda "yok" varsay
    }
  }

  /// Verilen trackId'nin kullanıcının favorilerinde olup olmadığını kontrol eder.
  Future<bool> isFavorite(String trackId) async {
    final userId = ucontrol.getUSerId();
    if (userId == null) {
      print("isFavorite: Kullanıcı ID'si alınamadı.");
      return false; // Kullanıcı yoksa favori olamaz
    }
    if (trackId.isEmpty) {
      print("isFavorite: Geçersiz trackId.");
      return false;
    }

    try {
      // Favoriler koleksiyonundaki ilgili dokümana referans al
      final favDocRef =
          _usersCollection().doc(userId).collection("Favorites").doc(trackId);

      // Dokümanın var olup olmadığını kontrol et
      final docSnapshot = await favDocRef.get();

      // Eğer doküman varsa (exists == true), şarkı favorilerdedir.
      return docSnapshot.exists;
    } catch (e) {
      print("isFavorite kontrolü sırasında hata: $e");
      return false; // Hata durumunda favori değil varsayalım
    }
  }
}
