import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:musicapp/Strings.dart';

import 'package:spotify/spotify.dart';
import 'package:http/http.dart' as http;

class Spottify {
  final String clientId = CustomStrings.clientID;
  final String clientSecret = CustomStrings.cliensecret;
  late final accessToken;
  late final SpotifyApi spot;
  Spottify() {
    dolur();
  }
  void dolur() async {
    String clientId = CustomStrings.clientID;
    String clientSecret = CustomStrings.cliensecret;
    spot = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));

    accessToken = await _getAccessToken();
  }

  Future<Album> getAlbumById(String id) async {
    final album = await spot.albums.get(id);
    return album;
  }

  Future<String> _getAccessToken() async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['access_token'];
    } else {
      throw Exception('Failed to get access token');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse(
          'https://api.spotify.com/v1/browse/categories?limit=50&offset=1'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['categories']['items'];
    } else {
      throw Exception('Failed to get categories');
    }
  }

  Future<List<dynamic>> getCategoriesPlaylist(String categoryid) async {
    final response = await http.get(
      Uri.parse(
          'https://api.spotify.com/v1/browse/categories/$categoryid/playlists'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['playlists']['items'];
    } else {
      throw Exception('Failed to get categories');
    }
  }

  Future<Track> bul(String songid) async {
    final String tokenEndpoint = 'https://accounts.spotify.com/api/token';
    final String searchEndpoint = 'https://api.spotify.com/v1/search';
    String clientId = CustomStrings.clientID;
    String clientSecret = CustomStrings.cliensecret;
    // String credentials = '$clientId:$clientSecret';
    final spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));
    final result = await spotify.tracks.get(songid);
    return result;
  }

  Future<List<dynamic>> getPlaylistsByCategory(String categoryId) async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse(
          'https://api.spotify.com/v1/browse/categories/$categoryId/playlists'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['playlists']['items'];
    } else {
      throw Exception('Failed to get playlists');
    }
  }

  Future<AlbumSimple> getalbum(String albumid) async {
    final String tokenEndpoint = 'https://accounts.spotify.com/api/token';
    final String searchEndpoint = 'https://api.spotify.com/v1/search';
    String clientId = CustomStrings.clientID;
    String clientSecret = CustomStrings.cliensecret;

    final spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));
    final trackResult = await spotify.albums.get(albumid);

    return trackResult;
  }

  Future<Track> gettrack(String trackid) async {
    final String tokenEndpoint = 'https://accounts.spotify.com/api/token';
    final String searchEndpoint = 'https://api.spotify.com/v1/search';
    String clientId = CustomStrings.clientID;
    String clientSecret = CustomStrings.cliensecret;

    final spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));
    final trackResult = await spotify.tracks.get(trackid);

    return trackResult;
  }

  Future<List<TrackSimple>> albumtoSongs(Map<dynamic, dynamic> album) async {
    final String tokenEndpoint = 'https://accounts.spotify.com/api/token';
    final String searchEndpoint = 'https://api.spotify.com/v1/search';
    String clientId = CustomStrings.clientID;
    String clientSecret = CustomStrings.cliensecret;
    List<TrackSimple> tracks = [];
    final spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));
    final trackResult = await spotify.albums.get(album["id"]);
    if (trackResult.tracks!.isNotEmpty) {
      trackResult.tracks!.forEach((track) {
        // print(track.name);
        tracks.add(track);
      });
    }

    return tracks;
  }

  Future<dynamic> getAlbum(String albumid) async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/$albumid'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to get playlists');
    }
  }

  Future<dynamic> getTrack(String trackid) async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/tracks/$trackid'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['album'];
    } else {
      throw Exception('Failed to get playlists');
    }
  }

  Future<List<dynamic>> AlbumToSong(Map<dynamic, dynamic> album) async {
    final String tokenEndpoint = 'https://accounts.spotify.com/api/token';
    final String searchEndpoint = 'https://api.spotify.com/v1/search';
    String clientId = CustomStrings.clientID;
    String clientSecret = CustomStrings.cliensecret;
    List<dynamic> tracks = [];
    Spottify sp = Spottify();
    final spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));
    // final trackResult = await spotify.albums.get(album["id"]);
    final trackresult = await getAlbum(album["id"]);
    for (var i = 0; i < trackresult["total_tracks"]; i++) {
      tracks.add(trackresult["tracks"]["items"][i]);
    }

    return tracks;
  }

  Future<List<dynamic>> getTracksByPlaylist(String playlistId) async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final v = jsonResponse["items"];
      return jsonResponse['items'];
    } else {
      throw Exception('Failed to get tracks');
    }
  }

  Future<List<dynamic>> getNewReleases() async {
    int limit = 50, offset = 0;
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse(
          'https://api.spotify.com/v1/browse/new-releases?limit=$limit&offset=$offset'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> albums = jsonResponse['albums']['items'];
      return albums;
    } else {
      throw Exception('Failed to get new releases');
    }
  }

  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/$albumId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to get album details for album ID: $albumId');
    }
  }

  Future<List<dynamic>> getNewSingles() async {
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/browse/new-releases'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> albums = jsonResponse['albums']['items'];
      List<dynamic> singles = [];

      for (var album in albums) {
        final List<dynamic> tracks = album['tracks']['items'];
        for (var track in tracks) {
          if (track['album']['album_type'] == 'single') {
            singles.add(track);
          }
        }
      }

      return singles;
    } else {
      throw Exception('Failed to get new singles');
    }
  }

  var spotify = SpotifyApi(
      SpotifyApiCredentials(CustomStrings.clientID, CustomStrings.cliensecret));
  Future<Widget?> getCategorie() async {
    List categories = await getCategories();
    return ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) =>
            Card(child: Text("${categories.elementAt(index)["name"]} $index")));
  }

  Future<List> getnews() async {
    List categories = await getNewReleases();
    categories.forEach((element) {});
    return categories;
  }

  Future<List> getcats() async {
    List categories = await getCategories();

    return categories;
  }

  Future<List> getcat() async {
    List playlists = [];
    List categories = await getCategories();
    for (var category in categories) {
      if (category["name"] != "Hindi") {
        print("${category['name']}   ${category['id']}");

        // Kategorinin playlistlerini al
        var result = await getCategoriesPlaylist(category["id"]);
        playlists.add(result);
        // Playlistlerdeki parçaları yazdır
        for (var parca in result) {
          print("${category["name"]} playlist name ${parca["name"]}");
        }
      }
    }

    categories.forEach((element) {});
    return playlists;
  }

  Future<void> getArtist(String artistID) async {
    int limit = 50, offset = 0;
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/$artistID'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final dynamic artist = jsonResponse[""];
      print("$artist");
      // showDialog(
      //     context: context,
      //     builder: (builder) => Dialog(
      //           child: Expanded(
      //             child: ListView.builder(
      //                 itemCount: albums.length,
      //                 itemBuilder: (context, index) =>
      //                     Text("${albums[index]["name"]}")),
      //           ),
      //         ));
    } else {
      throw Exception('Failed to get new releases');
    }
  }

  Future<List> getRecommend(String artistid, String trackid) async {
    int limit = 50, offset = 0;
    List recommends = [];
    final accessToken = await _getAccessToken();
    final response = await http.get(
      Uri.parse(
          'https://api.spotify.com/v1/recommendations?market=TR&seed_artists=$artistid&seed_tracks=$trackid'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> albums = jsonResponse['tracks'];
      recommends = albums;
      albums.forEach((element) {
        print("${element["name"]}");
      });
      // showDialog(
      //     context: context,
      //     builder: (builder) => Dialog(
      //           child: Expanded(
      //             child: ListView.builder(
      //                 itemCount: albums.length,
      //                 itemBuilder: (context, index) =>
      //                     Text("${albums[index]["name"]}")),
      //           ),
      //         ));
    } else {
      throw Exception('Failed to get new releases');
    }
    return recommends;
  }

  Future<List<Track>> getTracksFromSimple(
      List<TrackSimple> simpleTracks) async {
    if (simpleTracks.isEmpty) return [];

    // Her bir TrackSimple'ın ID'sini alıyoruz.
    final trackIds = simpleTracks.map((ts) => ts.id!).toList();

    // Spotify paketinin 'tracks.list' metodu ile tek bir istekte birden fazla şarkıyı çekiyoruz.
    // Bu, her şarkı için ayrı ayrı istek atmaktan çok daha verimlidir.
    final fullTracks = await spot.tracks.list(trackIds);

    // Gelen null olmayan track'leri bir listeye çevirip döndürüyoruz.
    return fullTracks.where((track) => track != null).cast<Track>().toList();
  }

  /// Belirtilen sorgu ve tipe göre Spotify'da arama yapar.
  Future<List<dynamic>> search(String query, SearchType searchType) async {
    if (query.isEmpty) {
      return [];
    }

    List<dynamic> searchResults = [];
    try {
      // API'den ilk 20 sonucu al
      final result = await spot.search
          .get(query, market: Market.TR, types: [searchType]).first(20);

      result.forEach((pages) {
        if (pages.items != null) {
          pages.items!.forEach((item) {
            // Null olmayan ve geçerli tiplerdeki sonuçları ekle
            if ((searchType == SearchType.track &&
                    item is Track &&
                    item.album?.images?.isNotEmpty == true) ||
                (searchType == SearchType.artist && item is Artist) ||
                (searchType == SearchType.playlist && item is PlaylistSimple)) {
              searchResults.add(item);
            }
          });
        }
      });
      return searchResults;
    } catch (e) {
      print("Spotify arama API hatası: $e");
      // Hata durumunda boş liste veya hata fırlatma tercih edilebilir.
      // Şimdilik boş liste döndürelim.
      return [];
    }
  }

  /// Verilen ID'ye sahip çalma listesinin detaylarını ve şarkılarını getirir.
  Future<Playlist> getPlaylistById(String playlistId) async {
    try {
      // .get() metodu genellikle hem playlist bilgisini hem de içindeki şarkıları (bir kısmını) getirir.
      final playlist = await spot.playlists.get(playlistId);
      if (playlist == null) {
        throw Exception("Çalma listesi bulunamadı.");
      }

      // TODO: Eğer API sadece ilk 100 şarkıyı getiriyorsa ve daha fazlası varsa,
      // burada `playlist.tracks.all()` gibi bir metotla tüm şarkıları çekmek gerekebilir.
      // Şimdilik gelen ilk sayfayı kullanıyoruz.

      return playlist;
    } catch (e) {
      print("Çalma listesi detayı alınırken hata: $e");
      rethrow;
    }
  }

  /// Verilen ID'ye sahip sanatçının detaylarını getirir.
  Future<Artist> getArtistById(String artistId) async {
    try {
      final artist = await spot.artists.get(artistId);
      if (artist == null) {
        throw Exception("Sanatçı bulunamadı.");
      }
      return artist;
    } catch (e) {
      print("Sanatçı detayı alınırken hata: $e");
      rethrow; // Hatayı yukarıya fırlat ki FutureBuilder yakalasın
    }
  }

  /// Verilen ID'ye sahip sanatçının popüler şarkılarını (Türkiye pazarı için) getirir.
  Future<List<Track>> getArtistTopTracks(String artistId) async {
    try {
      // Market.TR ülkeye göre popüler şarkıları getirir.
      final tracks = await spot.artists.topTracks(artistId, Market.TR);
      return tracks.toList();
    } catch (e) {
      print("Sanatçı popüler şarkıları alınırken hata: $e");
      rethrow;
    }
  }

  /// Verilen ID'ye sahip sanatçının popüler şarkılarını (Türkiye pazarı için) getirir.
  Future<List<PlaylistSimple>> getPlaylistsByCategoryId(String categoryId,
      {int limit = 20, int offset = 0}) async {
    try {
      // Doğrudan spotify.playlists.getByCategoryId metodunu kullanıyoruz.
      final playlistsPage = await spot.playlists
          .getByCategoryId(
            categoryId,
            country: Market.TR, // Türkiye pazarı için
          )
          .getPage(limit, offset); // Belirtilen sayfa limit/offset ile

      if (playlistsPage?.items == null) {
        return [];
      }

      // Gelen sonuçları PlaylistSimple listesine çevir
      return playlistsPage.items!.whereType<PlaylistSimple>().toList();
    } catch (e) {
      print("Kategoriye göre playlist alınırken hata: $e");
      // Spotify API bazen kategori bulunamayınca hata verebilir, boş liste döndürelim.
      return [];
    }
  }

  Future<Track> find(String songid) async {
    final result = await spot.tracks.get(songid);
    return result;
  }

  Future<List<Track>> getTracksByIds(List<String> trackIds) async {
    if (trackIds.isEmpty) return [];
    try {
      final tracks = await spot.tracks.list(trackIds);
      return tracks.whereType<Track>().toList();
    } catch (e) {
      print("getTracksByIds hatası: $e");
      return [];
    }
  }
  // Future<List<Track>> getArtistAlbums(String artistId) async {
  //   try {
  //     // Market.TR ülkeye göre popüler şarkıları getirir.
  //     final tracks = await spot.artists
  //         .albums(artistId, country: Market.TR, includeGroups: []);
  //     return tracks.toList();
  //   } catch (e) {
  //     print("Sanatçı popüler şarkıları alınırken hata: $e");
  //     rethrow;
  //   }
  // }
}
