// views/PLaylistpage.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/viewmodels/playlist_view_model.dart';
import 'package:musicapp/views/PLpage.dart';
import 'package:musicapp/views/Favoritespage.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/data/Models.dart' as mymodel;

class PLaylistpage extends StatelessWidget {
  const PLaylistpage({super.key});

  // Yeni playlist ekleme dialog'unu gösteren yardımcı metot
  void _showAddPlaylistDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final viewModel = context.read<PlaylistViewModel>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Yeni Çalma Listesi"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Liste Adı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // İptal
            child: const Text("İPTAL"),
          ),
          TextButton(
            onPressed: () {
              // ViewModel üzerinden playlist oluşturma işlemini çağır
              viewModel.createPlaylist(nameController.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text("OLUŞTUR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel'dan playlist stream'ini al ('watch' ile dinliyoruz)
    final viewModel = context.watch<PlaylistViewModel>();
    final playlistsStream = viewModel.playlistsStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kitaplığın"),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.plus),
            onPressed: () => _showAddPlaylistDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<mymodel.Playlist>>(
        stream: playlistsStream,
        builder: (context, snapshot) {
          // Yüklenme durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Hata durumu
          if (snapshot.hasError) {
            print("Playlist Stream Hatası: ${snapshot.error}");
            return const Center(
                child: Text("Listeler yüklenirken bir hata oluştu."));
          }
          // Veri yoksa (stream başladı ama henüz veri gelmedi veya boş)
          if (!snapshot.hasData) {
            return const Center(child: Text("Henüz çalma listen yok."));
          }

          final playlists = snapshot.data ?? [];

          return ListView(
            children: [
              // 1. Favoriler ListTile'ı
              ListTile(
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.white]),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(FontAwesomeIcons.solidHeart,
                      color: Colors.white),
                ),
                title: const Text("Beğenilen Şarkılar"),
                onTap: () {
                  // Favoriler sayfasına git
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const Favoritespage()));
                },
              ),

              const Divider(), // Ayraç

              // 2. Kullanıcının Playlist'leri (Dinamik)

              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("Henüz çalma listen yok.")),
                )
              else
                ...playlists
                    .map((playlist) => Dismissible(
                          key: Key(playlist.playlistId),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            context
                                .read<PlaylistViewModel>()
                                .deletePlaylist(playlist.playlistId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "${playlist.playlistName} silindi.")),
                            );
                          },
                          background: Container(
                              /* ... delete background ... */ color: Colors.red,
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete)),
                          child: ListTile(
                            leading: playlist.firstSongImage != null &&
                                    playlist.firstSongImage!.isNotEmpty
                                ? Image.network(playlist.firstSongImage!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.music_note, size: 50))
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.music_note)),
                            title: Text(playlist.playlistName),
                            onTap: () {
                              // Playlist detay sayfasına git (PLpage)
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PLpage(initialPlaylistData: playlist),
                                ),
                              );
                            },
                          ),
                        ))
                    .toList(),

              // 3. Yeni Liste Ekle ListTile'ı
              ListTile(
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add),
                ),
                title: const Text("Yeni Çalma Listesi Oluştur"),
                onTap: () => _showAddPlaylistDialog(context),
              ),

              Consumer<MiniPlayerViewModel>(
                  builder: (context, playerViewModel, _) {
                return SizedBox(height: playerViewModel.isActive ? 75.0 : 0.0);
              }),
            ],
          );
        },
      ),
    );
  }
}
