// views/artist_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flt;
import 'package:musicapp/services/Spottify.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';

class ArtistDetailPage extends StatefulWidget {
  final String artistId;

  const ArtistDetailPage({super.key, required this.artistId});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  // Verileri ve yükleme durumunu tutacak Future'lar
  Future<Artist>? _artistDetailsFuture;
  Future<List<Track>>? _topTracksFuture;
  bool _isDataFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Veriyi sadece bir kez çek
    if (!_isDataFetched) {
      final spotifyService = context.read<Spottify>();
      _artistDetailsFuture = spotifyService.getArtistById(widget.artistId);
      _topTracksFuture = spotifyService.getArtistTopTracks(widget.artistId);
      _isDataFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ı ve Body'yi FutureBuilder ile sarmalayarak her iki isteği de yönetelim
      body: FutureBuilder<List<Object>>(
        // İki Future'ı birleştirmek için List<Object>
        future: Future.wait([
          _artistDetailsFuture!, // Null olamayacağını varsayıyoruz
          _topTracksFuture!, // Null olamayacağını varsayıyoruz
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.length < 2) {
            return const Center(child: Text("Sanatçı bilgileri yüklenemedi."));
          }

          // Veriler başarıyla geldi, ayıralım
          final artistDetails = snapshot.data![0] as Artist;
          final topTracks = snapshot.data![1] as List<Track>;
          final imageUrl = artistDetails.images?.isNotEmpty ?? false
              ? artistDetails.images!.first.url
              : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                title: Text(artistDetails.name ?? 'Sanatçı'),
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null
                      ? flt.Image.network(imageUrl,
                          fit: BoxFit.cover,
                          // Hata durumunda boş alan
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox())
                      : Container(
                          color: Colors
                              .grey.shade800), // Resim yoksa gri arka plan
                ),
              ),
              // Popüler Şarkılar başlığı
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Popüler Şarkılar",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              // Şarkı Listesi
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = topTracks[index];
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
                      subtitle: Text(track.album?.name ?? ''),
                      onTap: () {
                        // Tıklanan şarkıdan başlayarak popüler şarkılar listesini çal
                        context.read<MiniPlayerViewModel>().playTracks(
                              topTracks,
                              initialIndex: index,
                            );
                      },
                    );
                  },
                  childCount: topTracks.length,
                ),
              ),
              // MiniPlayer için altta boşluk bırak (global padding ile aynı mantık)
              SliverToBoxAdapter(
                child: Consumer<MiniPlayerViewModel>(
                  // Sadece bu kısmı dinlemesi yeterli
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
