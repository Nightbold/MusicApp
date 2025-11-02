// views/PLpage.dart

import 'package:flutter/material.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/viewmodels/playlist_detail_view_model.dart'; // Yeni import
import 'package:provider/provider.dart';
import 'package:musicapp/data/Models.dart';
import 'package:musicapp/services/new_database.dart'; // Servis importları
import 'package:musicapp/services/auth.dart';

// StatefulWidget yerine StatelessWidget (veya ConsumerWidget eğer Riverpod kullanıyorsan)
class PLpage extends StatelessWidget {
  // Sayfaya artık tüm Playlist nesnesi yerine sadece ID ve başlangıç bilgileri yeterli
  final Playlist initialPlaylistData;

  const PLpage({super.key, required this.initialPlaylistData});

  @override
  Widget build(BuildContext context) {
    // Bu sayfaya özel PlaylistDetailViewModel'ı oluşturup sağlıyoruz.
    return ChangeNotifierProvider(
      create: (context) => PlaylistDetailViewModel(
        context.read<Database>(),
        context.read<UserControl>(),
        initialPlaylistData.playlistId, // ID'yi ViewModel'a ver
      ),
      child: Scaffold(
        // AppBar ve Body'yi Consumer ile sarmalayarak ViewModel'a erişelim
        body: Consumer<PlaylistDetailViewModel>(
          builder: (context, viewModel, _) {
            final songsStream = viewModel.songsStream;
            final imageUrl =
                initialPlaylistData.firstSongImage; // Başlangıç resmini kullan

            return StreamBuilder<List<Song>>(
              stream: songsStream,
              builder: (context, snapshot) {
                // CustomScrollView ve SliverAppBar playlist başlığı için
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      title: Text(initialPlaylistData
                          .playlistName), // Başlangıç ismini kullan
                      flexibleSpace: FlexibleSpaceBar(
                        background: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey.shade800))
                            : Container(color: Colors.grey.shade800),
                      ),
                    ),

                    // Yüklenme veya Hata durumları için Sliver
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData)
                      const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()))
                    else if (snapshot.hasError)
                      SliverFillRemaining(
                          child: Center(child: Text("Şarkılar yüklenemedi.")))
                    // Veri yoksa (boş liste) Sliver
                    else if (!snapshot.hasData || snapshot.data!.isEmpty)
                      const SliverFillRemaining(
                          child:
                              Center(child: Text("Bu listede hiç şarkı yok.")))
                    // Veri varsa Şarkı Listesi Sliver'ı
                    else
                      _buildSongListSliver(context, snapshot.data!, viewModel),

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
            );
          },
        ),
      ),
    );
  }

  // Şarkı listesini oluşturan SliverList widget'ını döndüren yardımcı metot
  Widget _buildSongListSliver(BuildContext context, List<Song> songs,
      PlaylistDetailViewModel viewModel) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = songs[index];
          return Dismissible(
            // Kaydırarak silme
            key: Key(song.songId),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              viewModel.removeSongFromPlaylist(song.songId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("${song.songName} listeden kaldırıldı.")),
              );
            },
            background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                child: Icon(Icons.delete)),
            child: ListTile(
              leading: Image.network(
                song.songImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.music_note, size: 50),
              ),
              title: Text(song.songName, maxLines: 1),
              subtitle: Text(song.songArtist, maxLines: 1),
              onTap: () {
                // Tüm playlist şarkılarını çal, bu şarkıdan başla
                context.read<MiniPlayerViewModel>().playSongModels(
                      songs,
                      initialIndex: index,
                    );
              },
            ),
          );
        },
        childCount: songs.length,
      ),
    );
  }
}
