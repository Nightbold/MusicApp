import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotify/spotify.dart';

class User {
  String userId;
  List<Playlist> playlists;
  List<FavoriteSongs> favoriteItems;
  User(
      {required this.userId,
      required this.playlists,
      required this.favoriteItems});

  // Map<String, dynamic> toMap() {
  //   return {
  //     'userId': userId,
  //     'playlists': playlists.map((playlist) => playlist.toMap()).toList(),
  //   };
  // }
  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    QuerySnapshot querySnapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    var pllist = PlaylistList(playlists: []);
    return User(
      userId: data?['userId'],
      playlists: pllist.fromFireStore(querySnapshot),
      favoriteItems: data?['favoriteItems'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (playlists != null) "playlists": playlists,
      if (favoriteItems != null) "favoriteItems": favoriteItems,
    };
  }
}

class PlaylistList {
  List playlists;

  PlaylistList({required this.playlists});

  List<Playlist> fromFireStore(QuerySnapshot snapshots) {
    List<DocumentSnapshot<Map<String, dynamic>>> playlistDocs =
        snapshots.docs.cast<DocumentSnapshot<Map<String, dynamic>>>();
    List<Playlist> playlists =
        playlistDocs.map((doc) => Playlist.fromFirestore(doc)).toList();
    return playlists;
  }
}

class Playlist {
  String playlistId; // Artık final ve constructor'da required
  String playlistName;
  List<Song> songs;
  String? firstSongImage;

  // setfirstSongImage metoduna gerek yok, doğrudan atanabilir veya constructor'da verilebilir.

  Playlist({
    required this.playlistId, // ID artık zorunlu
    required this.playlistName,
    required this.songs,
    this.firstSongImage,
  });

  // Map'ten Playlist nesnesi oluşturan factory constructor (ViewModel bunu kullanabilir)
  factory Playlist.fromMap(String id, Map<String, dynamic> data) {
    // songs listesini Map'ten Song nesnelerine çevir
    var songsData = data['songs'] as List<dynamic>? ?? [];
    List<Song> songObjects = songsData
        .map((songMap) => Song.fromMap(songMap as Map<String, dynamic>))
        .toList();

    return Playlist(
      playlistId: id, // ID'yi parametreden al
      playlistName: data['playlistName'] ?? 'İsimsiz Liste',
      songs: songObjects,
      firstSongImage: data['firstSongImage'] as String?,
    );
  }

  // Firestore Snapshot'ından Playlist nesnesi oluşturan factory constructor
  // Bu, Database servisi içinde kullanılabilir
  factory Playlist.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data =
        snapshot.data() ?? {}; // Boş Map döndürerek null hatalarını önle

    // songs listesini Map'ten Song nesnelerine çevir
    var songsData = data['songs'] as List<dynamic>? ?? [];
    List<Song> songObjects = songsData
        .map((songMap) => Song.fromMap(songMap as Map<String, dynamic>))
        .toList();

    return Playlist(
      playlistId: snapshot.id, // ID'yi snapshot'tan al
      playlistName: data['playlistName'] ?? 'İsimsiz Liste',
      songs: songObjects,
      firstSongImage: data['firstSongImage'] as String?,
    );
  }

  // Firestore'a yazmak için Map'e çeviren metot
  Map<String, dynamic> toFirestore() {
    return {
      // playlistId'yi DOKÜMAN ID'si olarak kullanacağımız için buraya yazmaya GEREK YOK.
      // İstersen yedek olarak yazabilirsin: 'playlistId': playlistId,
      'playlistName': playlistName,
      // songs listesini Map listesine çevir
      'songs': songs
          .map((song) => song.toFirestore())
          .toList(), // Song modelinde toFirestore olduğunu varsayıyorum
      'firstSongImage': firstSongImage, // null ise Firestore'dan silinir
    };
  }
}

// class Playlist {
//   String playlistId;
//   String playlistName;
//   List<Song> songs;
//   String? firstSongImage;

//   setfirstSongImage(String image) {
//     firstSongImage = image;
//   }

//   Playlist(
//       {required this.playlistId,
//       required this.playlistName,
//       required this.songs,
//       this.firstSongImage});

//   Map<String, dynamic> toMap() {
//     return {
//       'playlistId': playlistId,
//       'playlistName': playlistName,
//       'songs': songs.map((song) => song.toMap()).toList(),
//     };
//   }

//   factory Playlist.fromFirestore(
//     DocumentSnapshot<Map<String, dynamic>> snapshot,
//   ) {
//     final data = snapshot.data();
//     return Playlist(
//       playlistId: data?['playlistId'],
//       playlistName: data?['playlistName'],
//       songs: data?['songs'],
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       if (playlistId != null) "playlistId": playlistId,
//       if (playlistName != null) "playlistName": playlistName,
//       if (songs != null) "songs": songs,
//       "firstSongImage": firstSongImage
//     };
//   }
// }

class FavoriteSongs {
  List<Song> songs;
  FavoriteSongs({required this.songs});

  // Map<String, dynamic> toMap() {
  //   return {
  //     'itemId': itemId,
  //     'itemName': itemName,
  //     'itemType': itemType,
  //   };
  // }

  factory FavoriteSongs.fromFirestore(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    List<DocumentSnapshot<Map<String, dynamic>>> songlistdocs =
        snapshot.docs.cast<DocumentSnapshot<Map<String, dynamic>>>();
    // final data = snapshot.data();

    List<Song> songlists =
        songlistdocs.map((doc) => Song.fromFirestore(doc)).toList();
    return FavoriteSongs(songs: songlists);
  }

  // Map<String, dynamic> toFirestore() {
  //   return {
  //     if (itemId != null) "itemId": itemId,
  //     if (itemName != null) "itemName": itemName,
  //     if (itemType != null) "itemType": itemType,
  //   };
  // }
}

class Song {
  String songId;
  String songName;
  String songImage;
  String songArtist;
  String songArtistID;

  Song({
    required this.songId,
    required this.songName,
    required this.songImage,
    required this.songArtist,
    required this.songArtistID,
  });
  // withoutInfo constructor
  Song.withoutInfo()
      : songId = '',
        songName = '',
        songImage = '',
        songArtist = '',
        songArtistID = '';

  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'songName': songName,
      'songImage': songImage,
      'songArtist': songArtist,
      'songArtistID': songArtistID,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      songId: map['songId'] ?? '',
      songName: map['songName'] ?? 'Bilinmeyen Şarkı',
      songArtist: map['songArtist'] ?? 'Bilinmeyen Sanatçı',
      songImage: map['songImage'] ?? '',
      songArtistID: map['songArtistID'],
    );
  }
  factory Song.fromTrack(Track track) {
    return Song(
      songId: track.id ?? '',
      songName: track.name ?? 'Bilinmeyen Şarkı',
      songArtist: track.artists?.first?.name ?? 'Bilinmeyen Sanatçı',
      songImage: track.album?.images?.first?.url ?? '',
      songArtistID: track.artists?.first?.id ?? '',
    );
  }
  factory Song.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return Song(
      songId: data?['songId'],
      songName: data?['songName'],
      songArtist: data?['songArtist'],
      songArtistID: data?.containsKey('songArtistID') == true
          ? data!['songArtistID']
          : "null",
      songImage: data?['songImage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (songId != null) "songId": songId,
      if (songName != null) "songName": songName,
      if (songImage != null) "songImage": songImage,
      if (songArtist != null) "songArtist": songArtist,
      if (songArtistID != null) "songArtistID": songArtist,
      if (songImage != null) "songImage": songImage,
    };
  }
}
