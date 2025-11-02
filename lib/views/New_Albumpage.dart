// views/AlbumPage.dart

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:musicapp/services/Spottify.dart'; // Servisimizi import ediyoruz
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';

class AlbumPage extends StatefulWidget {
  // Artık sadece AlbumSimple nesnesini alıyor.
  final Album albumSimple;

  const AlbumPage({super.key, required this.albumSimple});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  // Sayfanın state'lerini tanımlıyoruz.
  Future<Album>? _albumDetailsFuture;
  bool _isDataFetched = false;
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    // Veri daha önce çekilmediyse bu bloğu çalıştır.
    if (!_isDataFetched) {
      // Artık burada geçerli bir context'imiz var!
      // Provider'dan mevcut Spottify servisini alıyoruz.
      final spotifyService = context.read<Spottify>();

      // Future'ı burada oluşturuyoruz.
      _albumDetailsFuture = spotifyService.getAlbumById(widget.albumSimple.id!);

      // Bayrağı true yaparak bu bloğun bir daha çalışmasını engelliyoruz.
      _isDataFetched = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.albumSimple.images?.first.url;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumSimple.name ?? 'Albüm'),
      ),
      body: FutureBuilder<Album>(
        future: _albumDetailsFuture,
        builder: (context, snapshot) {
          // Veri henüz gelmediyse yükleme animasyonu göster.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hata oluştuysa hata mesajı göster.
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Albüm detayları yüklenemedi."));
          }

          // Veri başarıyla geldiyse UI'ı oluştur.
          final albumDetails = snapshot.data!;
          final tracks = albumDetails.tracks ?? [];

          final trackList = albumDetails.tracks?.toList() ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: Container(),
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null
                      ? flutter.Image.network(imageUrl, fit: BoxFit.cover)
                      : SizedBox(),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // 'Iterable' olan tracks koleksiyonunu '.toList()' ile bir listeye çeviriyoruz.

                    final track = trackList[index];
                    return ListTile(
                      leading: Text("${index + 1}"),
                      title: Text(track.name ?? 'Bilinmeyen Şarkı'),
                      subtitle: Text(
                          track.artists?.map((a) => a.name).join(', ') ?? ''),
                      onTap: () {
                        // DEĞİŞİKLİK BURADA:
                        // Artık 'playTracks' yerine 'playAlbumLazily' metodunu çağırıyoruz.
                        // Bu, ViewModel'a "Önce bu şarkıyı çal, kalanı arkada hallet" komutunu verir.
                        context.read<MiniPlayerViewModel>().playAlbumLazily(
                              trackList,
                              initialIndex: index,
                            );
                      },
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
