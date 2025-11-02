// lib/services/isolate_helpers.dart

import 'package:musicapp/Strings.dart'; // Spotify credential'larınızın olduğu dosya
import 'package:spotify/spotify.dart';

/// "SPRINTER" GÖREVİ: Sadece tek bir TrackSimple'ı tam Track nesnesine çevirir.
Future<Track?> fetchSingleTrackInIsolate(TrackSimple simpleTrack) async {
  print("✅ Sprinter Isolate başlatıldı: 1 şarkı işlenecek.");
  try {
    final spotify = SpotifyApi(SpotifyApiCredentials(
      CustomStrings.clientID,
      CustomStrings.cliensecret,
    ));
    // Spotify'ın 'tracks.get()' metodu tek bir şarkı için daha verimlidir.
    final fullTrack = await spotify.tracks.get(simpleTrack.id!);
    print("✅ Sprinter Isolate görevini tamamladı.");
    return fullTrack;
  } catch (e) {
    print("❌ Sprinter Isolate içinde hata oluştu: $e");
    return null;
  }
}

/// Bu fonksiyon bir Isolate içinde çalışmak üzere tasarlanmıştır.
/// Bir List<TrackSimple> alır ve Spotify API'sini kullanarak
/// tam List<Track> nesnelerini döndürür.
Future<List<Track>> fetchFullTracksInIsolate(
    List<TrackSimple> simpleTracks) async {
  print("✅ Isolate başlatıldı: ${simpleTracks.length} şarkı işlenecek.");
  if (simpleTracks.isEmpty) return [];

  try {
    // Isolate'ler hafıza paylaşmadığı için, kendi SpotifyApi nesnesi ni oluşturması gerekir.
    final spotify = SpotifyApi(SpotifyApiCredentials(
      CustomStrings.clientID,
      CustomStrings.cliensecret,
    ));

    final trackIds = simpleTracks.map((ts) => ts.id!).toList();
    final fullTracks = await spotify.tracks.list(trackIds);

    print("✅ Isolate görevini tamamladı.");
    return fullTracks.whereType<Track>().toList();
  } catch (e) {
    print("❌ Isolate içinde hata oluştu: $e");
    return []; // Hata durumunda boş liste döndür.
  }
}
