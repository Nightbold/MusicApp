// views/music_player_screen.dart

import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musicapp/main.dart';
import 'package:musicapp/services/music_service.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/viewmodels/playlist_view_model.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:musicapp/data/Models.dart' as mymodel;
import 'package:spotify/spotify.dart' as spot;

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});
// Playlist'e ekleme dialog'unu gösteren yardımcı metot
  void _showAddToPlaylistDialog(
      BuildContext context, MiniPlayerViewModel playerViewModel) {
    // PlaylistViewModel'dan mevcut listeleri alalım
    final playlistViewModel = context.read<PlaylistViewModel>();
    // Stream yerine Future'ı alıyoruz

    final currentTrack = playerViewModel.currentTrack; // Çalan şarkıyı al
    if (currentTrack == null || currentTrack.id == null) return;
    // ViewModel'dan yeni metodu çağır (songId ile)
    final playlistsFuture =
        playlistViewModel.getPlaylistsWithSongStatus(currentTrack.id!);
    showModalBottomSheet(
      // Daha şık bir görünüm için BottomSheet
      context: context,
      builder: (sheetContext) {
        return FutureBuilder<Map<mymodel.Playlist, bool>>(
          future: playlistsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final playlistsMap = snapshot.data ?? <mymodel.Playlist, bool>{};
            final List<Widget> listChildren = [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Çalma Listesine Ekle", /*...*/
                ),
              ),
              ListTile(
                leading: Icon(
                    Icons.playlist_add) /* ... (Yeni Playlist ikonu) ... */,
                title: const Text("Yeni Çalma Listesi Oluştur"),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCreateNewPlaylistDialog(context, playerViewModel);
                },
              ),
              const Divider(),
            ];
            if (playlistsMap.isEmpty) {
              listChildren.add(
                  const ListTile(title: Text("Oluşturulmuş bir listen yok.")));
            } else {
              // Map'teki her giriş için dinamik ListTile'lar oluştur
              playlistsMap.forEach((playlist, isAdded) {
                listChildren.add(
                  ListTile(
                    leading: playlist.firstSongImage != null &&
                            playlist.firstSongImage!.isNotEmpty
                        ? Image.network(playlist.firstSongImage!,
                            width: 40, height: 40)
                        : const Icon(Icons
                            .music_note) /* ... (playlist resmi veya ikon) ... */,
                    title: Text(playlist.playlistName),

                    // GÖRSEL GERİ BİLDİRİM: 'isAdded' durumuna göre ikonu ayarla
                    trailing: isAdded
                        ? const Icon(Icons.check_circle,
                            color: Colors.green) // EKLİYSE TİK
                        : const Icon(Icons.add), // DEĞİLSE ARTI

                    onTap: () async {
                      Navigator.of(sheetContext).pop(); // Dialog'u hemen kapat

                      try {
                        if (isAdded) {
                          // ZATEN EKLİYSE: Çıkarma işlemini çağır
                          await playerViewModel.removeCurrentTrackFromPlaylist(
                              playlist.playlistId, currentTrack.id!);
                          ScaffoldMessenger.of(navigatorKey.currentContext!)
                              .showSnackBar(SnackBar(
                            content: Text(
                                "${currentTrack.name} -> ${playlist.playlistName} listesinden kaldırıldı."),
                          ));
                        } else {
                          // EKLİ DEĞİLSE: Ekleme işlemini çağır
                          await playerViewModel
                              .addCurrentTrackToPlaylist(playlist.playlistId);
                          ScaffoldMessenger.of(navigatorKey.currentContext!)
                              .showSnackBar(SnackBar(
                            content: Text(
                                "${currentTrack.name} -> ${playlist.playlistName} listesine eklendi."),
                          ));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(navigatorKey.currentContext!)
                            .showSnackBar(SnackBar(
                          content: Text("İşlem başarısız: $e"),
                        ));
                      }
                    },
                  ),
                );
              });
            }

            return ListView(
              shrinkWrap: true,
              children: listChildren,
            );
          },
        );
      },
    );
  }

  void _showCreateNewPlaylistDialog(
      BuildContext context, MiniPlayerViewModel playerViewModel) {
    final TextEditingController nameController = TextEditingController();
    final playlistViewModel = context.read<PlaylistViewModel>();

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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("İPTAL"),
          ),
          TextButton(
            onPressed: () async {
              final String newName = nameController.text.trim();
              if (newName.isEmpty) return; // Boş isim kontrolü

              // 1. ViewModel üzerinden playlist oluştur
              // NOT: createPlaylist'in, oluşturulan Playlist nesnesini döndürmesi
              // için Database servisini güncellemek en iyisi olur.
              // Şimdilik, oluşturduğunu varsayıp ekleyelim:
              await playlistViewModel.createPlaylist(newName);

              // 2. (İdeal senaryo) Yeni playlist'in ID'sini alıp şarkıyı ekle:
              // mymodel.Playlist newPlaylist = await playlistViewModel.createPlaylist(newName);
              // await playerViewModel.addCurrentTrackToPlaylist(newPlaylist.playlistId);

              // (Mevcut senaryo) Kullanıcıya bilgi ver.
              // Şarkıyı eklemek için listeyi tekrar açması gerekecek (şimdilik)
              // VEYA: createPlaylist'ten sonra getPlaylistsOnce'ı tekrar çağırıp son
              // ekleneni bularak ID'sini alabilirsin (karmaşık).

              Navigator.of(dialogContext).pop(); // Dialog'u kapat

              // Kullanıcıya mesaj ver
              ScaffoldMessenger.of(navigatorKey.currentContext!)
                  .showSnackBar(SnackBar(
                content: Text(
                    "'$newName' listesi oluşturuldu. Şarkıyı eklemek için lütfen listeyi tekrar açın."),
              ));
            },
            child: const Text("OLUŞTUR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tüm veriyi ve kontrolü ViewModel'dan alıyoruz.
    final viewModel = context.watch<MiniPlayerViewModel>();
    final track = viewModel.currentTrack;

    // Eğer bir şekilde bu sayfa açıldığında şarkı yoksa, boş bir ekran göster.
    if (track == null) {
      return const Scaffold(
        body: Center(child: Text("Çalınan şarkı yok.")),
      );
    }

    final imageUrl = track.album?.images?.first.url;

    return Scaffold(
      extendBodyBehindAppBar:
          true, // Body'nin AppBar arkasına uzanmasını sağlar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Arka planı şeffaf yapar
        elevation: 0,
        actions: [
          // Favori Butonu
          IconButton(
            icon: Icon(
              viewModel
                      .isCurrentTrackFavorite // ViewModel'daki state'e göre ikon
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: viewModel.isCurrentTrackFavorite
                  ? Colors.green
                  : Colors.white,
            ),
            onPressed: () {
              // Duruma göre ekle veya çıkar
              if (viewModel.isCurrentTrackFavorite) {
                viewModel.removeCurrentTrackFromFavorites();
              } else {
                viewModel.addCurrentTrackToFavorites();
              }
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(track.album?.name ?? ''),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. KATMAN: Bulanıklaştırılmış Arka Plan
          if (imageUrl != null) Image.network(imageUrl, fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // 2. KATMAN: Asıl İçerik
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Albüm Kapağı
                Hero(
                  tag: 'mini-player-artwork', // MiniPlayer'daki ile aynı tag
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(imageUrl ?? ''),
                  ),
                ),
                const Spacer(),

                // Şarkı Bilgileri
                _buildTrackInfo(context, track, viewModel),
                const SizedBox(height: 32),

                // İlerleme Çubuğu
                _buildProgressBar(viewModel),
                const SizedBox(height: 16),

                // Kontrol Butonları
                _buildControls(viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo(
      BuildContext context, spot.Track track, MiniPlayerViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30, // Marquee için sabit yükseklik
                child: track.name!.length > 30
                    ? Marquee(
                        text:
                            "${track.name!}    ", // Boşluk ekleyerek döngüyü güzelleştir
                        velocity: 30.0,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : Text(
                        track.name!,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
              ),
              Text(
                track.artists?.map((a) => a.name).join(', ') ??
                    'Bilinmeyen Sanatçı',
                style: TextStyle(
                    fontSize: 16, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add, color: Colors.white, size: 30),
          onPressed: () => _showAddToPlaylistDialog(context, viewModel),
        ),
      ],
    );
  }

  Widget _buildProgressBar(MiniPlayerViewModel viewModel) {
    return ProgressBar(
      progress: viewModel.currentPosition,
      total: viewModel.totalDuration,
      onSeek: viewModel.seek,
      progressBarColor: Colors.white,
      baseBarColor: Colors.white.withOpacity(0.24),
      bufferedBarColor: Colors.white.withOpacity(0.24),
      thumbColor: Colors.white,
      timeLabelTextStyle: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildControls(MiniPlayerViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle, size: 28),
          onPressed: () {/* Shuffle logic */},
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 40),
          onPressed: viewModel.previous, // Sadece ViewModel'ı çağır
        ),
        _buildPlayPauseButton(viewModel),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 40),
          onPressed: viewModel.next, // Sadece ViewModel'ı çağır
        ),
        IconButton(
          icon: const Icon(Icons.repeat, size: 28),
          onPressed: () {/* Repeat logic */},
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(MiniPlayerViewModel viewModel) {
    // Bu metot MiniPlayer'daki ile birebir aynı mantıkta.
    switch (viewModel.playbackState) {
      case PlaybackState.loading:
        return const CircularProgressIndicator(color: Colors.white);
      case PlaybackState.playing:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.circlePause, size: 60),
          onPressed: viewModel.pause,
        );
      case PlaybackState.paused:
      case PlaybackState.stopped:
      case PlaybackState.completed:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.circlePlay, size: 60),
          onPressed: viewModel.play,
        );
    }
  }
}
