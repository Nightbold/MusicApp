// views/playlist_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flt;
import 'package:musicapp/services/Spottify.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  // Playlist detaylarını ve şarkılarını tutacak Future
  Future<Playlist>? _playlistDetailsFuture;
  bool _isDataFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      final spotifyService = context.read<Spottify>();
      // Spotify paketi genellikle playlist detayları ile şarkıları birlikte getirir.
      _playlistDetailsFuture =
          spotifyService.getPlaylistById(widget.playlistId);
      _isDataFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Playlist>(
        future: _playlistDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Çalma listesi yüklenemedi."));
          }

          final playlistDetails = snapshot.data!;
          // Playlist'ten şarkıları alalım (null kontrolü önemli)
          // Spotify API bazen tam Track nesnesi yerine TrackSimple döndürebilir,
          // veya Paging nesnesi içinde olabilir. Bu kısmı API cevabına göre ayarlamak gerekebilir.
          // Şimdilik doğrudan Track listesi döndürdüğünü varsayalım.
          final List<Track> tracks = playlistDetails.tracks?.itemsNative
                  // Önce item'ın Map olduğundan ve içinde 'track' anahtarının olduğundan emin ol
                  ?.where((item) => item is Map && item['track'] != null)
                  // Her item'dan 'track' Map'ini al
                  .map((item) {
                    try {
                      // 'track' Map'ini Track nesnesine çevir
                      return Track.fromJson(
                          item['track'] as Map<String, dynamic>);
                    } catch (e) {
                      print(
                          "Playlist track parse hatası: $e - Data: ${item['track']}");
                      return null; // Hata durumunda null döndür
                    }
                  })
                  // Null olmayan ve başarılı parse edilenleri filtrele
                  .whereType<Track>()
                  // Sonucu listeye çevir
                  .toList() ??
              [];

          final imageUrl = playlistDetails.images?.isNotEmpty ?? false
              ? playlistDetails.images!.first.url
              : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                title: Text(playlistDetails.name ?? 'Çalma Listesi'),
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null
                      ? flt.Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox())
                      : Container(color: Colors.grey.shade800),
                ),
              ),
              // Playlist Açıklaması (varsa)
              if (playlistDetails.description?.isNotEmpty ?? false)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(playlistDetails.description!),
                  ),
                ),
              // Şarkı Listesi
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    // Bazen playlist içindeki track'lerin albüm bilgisi eksik olabilir, kontrol edelim.
                    final trackImageUrl =
                        track.album?.images?.isNotEmpty ?? false
                            ? track.album!.images!.first.url
                            : null;
                    return ListTile(
                      leading: trackImageUrl != null
                          ? flt.Image.network(trackImageUrl,
                              width: 40, height: 40, fit: BoxFit.cover)
                          : const Icon(Icons.music_note),
                      title: Text(track.name ?? ''),
                      subtitle: Text(
                          track.artists?.map((a) => a.name).join(', ') ?? ''),
                      onTap: () {
                        // Tıklanan şarkıdan başlayarak playlist'i çal
                        // playTracks metodu List<Track> bekliyor, elimizdeki de o tipte.
                        context.read<MiniPlayerViewModel>().playTracks(
                              tracks,
                              initialIndex: index,
                            );
                      },
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
              // MiniPlayer için altta boşluk bırak
              SliverToBoxAdapter(
                child: Consumer<MiniPlayerViewModel>(
                  builder: (context, playerViewModel, _) {
                    return SizedBox(
                        height: playerViewModel.isActive ? 75.0 : 0.0);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
