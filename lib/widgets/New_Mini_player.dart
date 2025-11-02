// widgets/mini_player.dart

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musicapp/main.dart';

import 'package:musicapp/services/music_service.dart'; // MusicService'teki enum için
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/views/music_player_screen.dart';
// import 'package:musicapp/views/MusicPlayerScreen.dart'; // Tam ekran oynatıcı sayfanız
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' as spt;

class MiniPlayer extends StatefulWidget {
  // YENİ: Hangi navigator'a push yapacağını bilmesi için
  final GlobalKey<NavigatorState> currentNavigatorKey;
  const MiniPlayer({
    super.key,
    required this.currentNavigatorKey, // Constructor'a ekle
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  // Sadece gesture (kaydırma) animasyonu ve kontrolü için gerekli state'ler
  double offsetX = 0.0;
  double offsetY = 0.0;
  bool isSliding =
      false; // Tek bir kaydırmada birden fazla işlem olmasını engeller

  @override
  Widget build(BuildContext context) {
    // ViewModel'ı dinleyerek UI için gerekli tüm veriyi alıyoruz.
    final viewModel = context.watch<MiniPlayerViewModel>();
    final track = viewModel.currentTrack;
// Varsayılan renk (eğer baskın renk henüz hesaplanmadıysa veya bulunamadıysa kullanılır)
    const defaultColor = Color.fromARGB(255, 42, 75, 124);
    final textColor = viewModel.textColor;
    // ViewModel'dan gelen baskın rengi al, eğer null ise varsayılan rengi kullan.
    final backgroundColor = viewModel.dominantColor ?? defaultColor;
    // AnimatedContainer ile oyuncu aktif değilken ekranın altından kaybolmasını sağlıyoruz.
    return Visibility(
        visible: viewModel.isActive &&
            track != null &&
            !viewModel.isFullScreenPlayerVisible,
        child: GestureDetector(
          onTap: () => _openFullScreenPlayer(context),
          onVerticalDragUpdate: (details) {
            // Sadece yukarı kaydırmaya tepki ver
            setState(() {
              // Hareketi yavaşlatmak için 0.5 ile çarpmaya devam edebilirsiniz.
              offsetY += details.primaryDelta! * 0.5;
            });

            // YUKARI KAYDIRMA: Tam ekranı aç
            if (!isSliding && offsetY < -50.0) {
              isSliding = true;
              context.read<MiniPlayerViewModel>().showFullScreenPlayer();
              _openFullScreenPlayer(context);
              // navigatorKey.currentState!
              //     .push(MaterialPageRoute(
              //         builder: (context) => const MusicPlayerScreen()))
              //     .then((_) {
              //   // Sayfa kapandığında isSliding'i sıfırla
              //   isSliding = false;
              //   setState(() {
              //     offsetY = 0.0;
              //   });
              // });
              ;
            }
            // YENİ EKLENEN KISIM: AŞAĞI KAYDIRMA: Oynatıcıyı kapat
            else if (!isSliding && offsetY > 50.0) {
              isSliding = true; // Kilidi ayarla

              setState(() {
                offsetY = 0.0;
              });
              // ViewModel üzerinden oynatıcıyı durdur ve temizle komutunu gönder
              context.read<MiniPlayerViewModel>().stopAndClear();
            }
          },
          onVerticalDragEnd: (_) {
            // Kaydırma bitince widget'ı eski pozisyonuna geri getir ve kilidi kaldır.
            setState(() {
              offsetY = 0.0;
              isSliding = false;
            });
          },
          child: Transform.translate(
            offset: Offset(0, offsetY), // Dikey kaydırma animasyonu
            child: Material(
              color: backgroundColor.withOpacity(0.8),
              elevation: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading:
                        Image.network(track?.album?.images?.first.url ?? ''),
                    title: _buildSongTitle(context, track,
                        textColor), // Şarkı adını ayrı bir widget'a taşıdık
                    subtitle: Text(
                      track?.artists?.first.name ?? 'Bilinmeyen Sanatçı',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                      maxLines: 1,
                    ),
                    trailing: _buildPlayPauseButton(viewModel, textColor),
                  ),
                  _buildProgressBar(viewModel, textColor),
                ],
              ),
            ),
          ),
        ));

    // AnimatedContainer(
    //   duration: const Duration(milliseconds: 300),
    //   transform: Matrix4.translationValues(0, viewModel.isActive ? 0 : 100, 0),
    //   child: viewModel.isActive && track != null
    //       ? Material(
    //           color: const Color.fromARGB(255, 42, 75, 124),
    //           elevation: 10,
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               GestureDetector(
    //                 // Yukarı kaydırınca tam ekran oynatıcıyı aç
    //                 onTap: () {
    //                   Navigator.of(context).push(
    //                     MaterialPageRoute(
    //                         builder: (context) => Scaffold(
    //                               body: Container(
    //                                 child: Column(
    //                                   children: [
    //                                     Text("sda"),
    //                                     ElevatedButton(
    //                                         onPressed: () {}, child: Text(""))
    //                                   ],
    //                                 ),
    //                               ),
    //                             )),
    //                   );
    //                 },
    //                 child: ListTile(
    //                   leading:
    //                       Image.network(track.album?.images?.first.url ?? ''),
    //                   title: Text(track.name ?? 'Bilinmeyen Şarkı',
    //                       maxLines: 1, overflow: TextOverflow.ellipsis),
    //                   subtitle: Text(
    //                       track.artists?.first.name ?? 'Bilinmeyen Sanatçı',
    //                       maxLines: 1),
    //                   trailing: _buildPlayPauseButton(viewModel),
    //                 ),
    //               ),
    //               _buildProgressBar(viewModel),
    //             ],
    //           ),
    //         )
    //       : const SizedBox
    //           .shrink(), // Aktif değilse veya şarkı yoksa boş widget döndür
    // );
  }

  Future<void> _openFullScreenPlayer(BuildContext context) {
    context.read<MiniPlayerViewModel>().showFullScreenPlayer();
    return navigatorKey.currentState!
        .push(
      // Sayfa geçişini daha yumuşak yapan bir Route
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MusicPlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    )
        .then((value) {
      setState(() {
        isSliding = false;
        offsetY = 0.0;
      });
      context.read<MiniPlayerViewModel>().hideFullScreenPlayer();
    });
  }

// YATAY KAYDIRMA ÖZELLİĞİNE SAHİP ŞARKI ADI WIDGET'I
  Widget _buildSongTitle(
      BuildContext context, spt.Track? track, Color textColor) {
    final viewModel = context
        .read<MiniPlayerViewModel>(); // Metotlar için 'read' kullanıyoruz
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          offsetX += details.primaryDelta!;
        });
      },
      onHorizontalDragEnd: (details) {
        // Belirli bir eşiği geçince işlemi yap
        if (offsetX < -50.0) {
          // Sola kaydırma (Sonraki şarkı)
          viewModel.next();
        } else if (offsetX > 50.0) {
          // Sağa kaydırma (Önceki şarkı)
          viewModel.previous();
        }
        // Animasyonu sıfırla
        setState(() {
          offsetX = 0.0;
        });
      },
      child: Transform.translate(
        offset: Offset(offsetX, 0), // Yatay kaydırma animasyonu
        child: Text(
          track?.name ?? 'Bilinmeyen Şarkı',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Oynat/Durdur butonunu oluşturan yardımcı metod
  Widget _buildPlayPauseButton(MiniPlayerViewModel viewModel, Color iconColor) {
    switch (viewModel.playbackState) {
      case PlaybackState.loading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
        );
      case PlaybackState.playing:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.pause),
          onPressed: viewModel.pause,
          color: iconColor,
        );
      case PlaybackState.paused:
      case PlaybackState.stopped:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.play),
          onPressed: viewModel.play,
          color: iconColor,
        );
      case PlaybackState.completed:
        return Container();
      // TODO: Handle this case.
    }
  }

  // İlerleme çubuğunu oluşturan yardımcı metod
  Widget _buildProgressBar(MiniPlayerViewModel viewModel, Color progressColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 4),
      child: ProgressBar(
        progress: viewModel.currentPosition,
        total: viewModel.totalDuration,
        onSeek: viewModel.seek,
        progressBarColor: progressColor,
        baseBarColor: Colors.white.withOpacity(0.24),
        bufferedBarColor: Colors.white.withOpacity(0.24),
        thumbColor: progressColor,
        barHeight: 3.0,
        thumbRadius: 5.0,
        timeLabelTextStyle: const TextStyle(
            color: Colors.white, fontSize: 0), // Süre etiketini gizle
      ),
    );
  }
}
