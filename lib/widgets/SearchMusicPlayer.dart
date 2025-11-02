// import 'dart:ui';
// import 'package:flutter/cupertino.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:marquee/marquee.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:musicapp/Strings.dart';
// import 'package:musicapp/art_work_image.dart';
// import 'package:image_input/widget/getImage/getImage.dart';
// import 'package:musicapp/services/Database.dart';
// import 'package:musicapp/services/MiniPlayerService.dart';
// import 'package:musicapp/views/Denemeprovider.dart';
// import 'package:musicapp/widgets/Lists.dart';
// import 'package:provider/provider.dart';
// import 'package:spotify/spotify.dart';
// import 'package:flutter/widgets.dart' as FlutterWidgets;
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// // import 'package:audioplayers/audioplayers.dart';
// import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
// import 'package:just_audio/just_audio.dart' as js;
// import 'package:musicapp/data/Models.dart' as mymodel;

// class SearchMusicPlayer extends StatefulWidget {
//   String songid;
//   Track song;
//   SearchMusicPlayer(this.songid, this.song) {}
//   @override
//   State<SearchMusicPlayer> createState() => _SearchMusicPlayerState();
// }

// class _SearchMusicPlayerState extends State<SearchMusicPlayer> {
//   Color songcolor = Color(0x4561245);
//   String artitsname = "Erkin koray";
//   String songname = "Gaddar";
//   String artistID = "3eVuump9qyK0YCQQo4mKbc?si=39CDthDPTtK1ryqseu44hQ";
//   String musicTrackId = "657FCK2qs1P6DV8caSlWWY";
//   final Database db = Database();

//   Icon favicon = Icon(
//     Icons.favorite_border,
//     color: Colors.green,
//   );
//   // late List<FlutterWidgets.Image> img;
//   var player = js.AudioPlayer();
//   bool isclick = false;
//   Duration? duration;
//   Icon Playicon = Icon(Icons.pause);
//   String? songImage;
//   String? artistImage;
//   @override
//   void dispose() {
//     try {
//       // player.dispose();
//       super.dispose();
//     } catch (e) {}
//   }

//   contIcon() async {
//     final temp = await db.getfavorites();
//     temp.forEach((element) {
//       if (element.songId == widget.songid) {
//         favicon = Icon(
//           Icons.favorite,
//           color: Color.fromARGB(255, 98, 228, 103),
//         );
//       }
//     });
//   }

//   @override
//   void initState() {
//     if (widget.songid != "") musicTrackId = widget.songid;

//     songname = widget.song.name!;
//     artitsname = widget.song.album!.artists!.first.name!;
//     songImage = widget.song.album!.images!.first.url;

//     // artistImage = widget.song.artists!.first.images!.first.url;
//     contIcon();
//     print("song name= ${songname}");
//     print("song ımage= ${songImage}");
//     print("song artist= ${artitsname}");
//     print("song artist= ${artitsname}");
//     db.addLastplaySong(widget.song);
//     final credentials = SpotifyApiCredentials(
//       CustomStrings.clientID,
//       CustomStrings.cliensecret,
//     );
//     final spotify = SpotifyApi(credentials);
//     // if (context.watch<Mini_Player>().songname != "") {
//     spotify.tracks.get(musicTrackId).then((track) async {
//       // songname = track.name!;
//       // artitsname = track.album!.artists!.first.name!;

//       if (songname != null) {
//         String? image = track.album?.images?.first.url ?? "";
//         if (image != null) {
//           // songImage = image;
//         }
//         // print("ilk artist : ${track.artists!.firstOrNull!.images!.first.url}");
//         // artistImage = track.artists?.first.images?.first.url;
//         try {
//           final yt = YoutubeExplode();
//           final video = (await yt.search
//                   .search("${songname} ${track.artists!.first.name}"))
//               .first;
//           final videoID = video.id.value;
//           duration = video.duration;
//           setState(() {});
//           var manifest = await yt.videos.streamsClient.getManifest(videoID);
//           var audioUrl = manifest.audioOnly.first.url;
//           await player.setUrl(audioUrl.toString());
//           await player.play();
//         } catch (e) {}

//         // player.play(UrlSource(audioUrl.toString())).then((value) {
//         //   if (player.state == PlayerState.playing) {}
//         // });
//       }

//       //  await spotify.player.addToQueue(track.id.toString());
//     });
//     // }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // return Scaffold();
//     context.read<Mini_Player>().setPlayer(player);
//     // context.read<Mini_Player>().setDuration(player.duration!);
//     context.read<Mini_Player>().SetSong(widget.song);
//     context.read<activeprovider>().setActive(song: widget.song);

//     return Scaffold(
//       appBar: AppBar(
//         // backgroundColor: Color.fromRGBO(0, 0, 0, 0),
//         leading: IconButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             icon: Icon(Icons.arrow_back_sharp)),
//       ),
//       // backgroundColor: Colors.black87,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 26),
//           child: Column(
//             children: [
//               SizedBox(
//                 height: 16,
//               ),
//               Row(
//                 crossAxisAlignment: FlutterWidgets.CrossAxisAlignment.start,
//                 mainAxisAlignment:
//                     FlutterWidgets.MainAxisAlignment.spaceBetween,
//                 children: [
//                   Icon(
//                     FontAwesomeIcons.ellipsisVertical,
//                     color: Colors.transparent,
//                   ),
//                   Column(
//                     mainAxisSize: FlutterWidgets.MainAxisSize.min,
//                     children: [
//                       Text("Çalıyor"),
//                       SizedBox(
//                         height: 6,
//                       ),
//                       Row(
//                         mainAxisSize: FlutterWidgets.MainAxisSize.min,
//                         children: [
//                           // CircleAvatar(
//                           //   backgroundColor: Colors.white,
//                           //   // backgroundImage: artistImage != null
//                           //   //     ? NetworkImage(artistImage!)
//                           //   //     : null,
//                           //   radius: 10,
//                           // ),
//                           // SizedBox(
//                           //   width: 6,
//                           // ),
//                           Text(songname),
//                         ],
//                       )
//                     ],
//                   ),
//                   IconButton(
//                       onPressed: () {
//                         showModalBottomSheet(
//                           context: context,
//                           builder: (context) => Container(
//                             // Alt sayfanın içeriği
//                             padding: EdgeInsets.all(20),
//                             child: Column(
//                               children: [
//                                 ListTile(
//                                   leading: SizedBox(
//                                       child: FlutterWidgets.Image.network(
//                                           songImage.toString())),
//                                   title: Text(songname.toString()),
//                                   subtitle: Text(artitsname.toString()),
//                                 ),
//                                 Divider(),
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                             builder: (context) =>
//                                                 addplaylistPage(
//                                                   song: widget.song,
//                                                 )));
//                                   },
//                                   child: ListTile(
//                                     leading: Icon(Icons.add_box_sharp),
//                                     title: Text("Şarkıyı favoriye ekle"),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                       icon: Icon(FontAwesomeIcons.ellipsisVertical))
//                 ],
//               ),
//               Expanded(
//                   flex: 2,
//                   child: Center(
//                     child: ArtWorkImage(
//                       image: songImage.toString(),
//                     ),
//                   )),
//               Expanded(
//                   child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment:
//                         FlutterWidgets.MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           songname.length > 30
//                               ? SizedBox(
//                                   width: 300,
//                                   height: 30,
//                                   child: Marquee(
//                                     velocity: 20,
//                                     blankSpace: 50,
//                                     text: songname + " ",
//                                     style: TextStyle(
//                                         fontSize: 20,
//                                         color: Colors.white,
//                                         fontWeight:
//                                             FlutterWidgets.FontWeight.bold),
//                                   ),
//                                 )
//                               : Text(
//                                   songname,
//                                   style: TextStyle(
//                                       fontSize: 20,
//                                       color: Colors.white,
//                                       fontWeight:
//                                           FlutterWidgets.FontWeight.bold),
//                                 ),
//                           Text(
//                             artitsname,
//                             style: TextStyle(color: Colors.white60),
//                           ),
//                         ],
//                       ),
//                       IconButton(
//                         icon: favicon,
//                         onPressed: () {
//                           setState(() {
//                             if (favicon.icon == Icons.favorite) {
//                               db.deleteFavorite(widget.song);
//                               favicon = Icon(
//                                 Icons.favorite_border_outlined,
//                                 color: const Color.fromARGB(255, 98, 228, 103),
//                               );
//                             } else {
//                               print("tetiklendi");
//                               db.addFavorite(widget.song);
//                               favicon = Icon(
//                                 Icons.favorite,
//                                 color: Color.fromARGB(255, 98, 228, 103),
//                               );
//                               ;
//                             }
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 16),
//                   StreamBuilder<Duration>(
//                       stream:
//                           context.watch<Mini_Player>().player.positionStream,
//                       builder: (context, snapshot) {
//                         return ProgressBar(
//                           onDragStart: (details) {
//                             setState(() {
//                               var deger = details.timeStamp;
//                               player.seek(deger);
//                             });
//                           },
//                           bufferedBarColor: Colors.white60,
//                           baseBarColor: Colors.white30,
//                           thumbColor: Colors.white,
//                           progressBarColor: Colors.white,
//                           progress: snapshot.data ??
//                               const Duration(
//                                 seconds: 0,
//                               ),
//                           buffered: Duration(minutes: 3, seconds: 30),
//                           total: context.watch<Mini_Player>().maxDuration ??
//                               const Duration(minutes: 4),
//                           onSeek: (duration) {
//                             context.read<Mini_Player>().player.seek(duration);
//                           },
//                         );
//                       }),
//                   SizedBox(
//                     height: 16,
//                   ),
//                   Row(
//                     mainAxisAlignment:
//                         FlutterWidgets.MainAxisAlignment.spaceEvenly,
//                     children: [
//                       IconButton(
//                           onPressed: () {},
//                           icon: Icon(Icons.swap_horiz_outlined)),
//                       IconButton(
//                           onPressed: () {},
//                           icon: Icon(
//                             Icons.skip_previous,
//                             color: Colors.white,
//                             size: 36,
//                           )),
//                       IconButton(
//                         onPressed: () async {
//                           if (player.playing) {
//                             print("oynuyor");
//                             player.pause();
//                             setState(() {
//                               Playicon = Icon(Icons.play_arrow);
//                             });
//                           } else {
//                             print("durmus");
//                             player.play();
//                             Playicon = Icon(Icons.pause);
//                             setState(() {});
//                           }
//                         },
//                         icon: Playicon,
//                       ),
//                       IconButton(
//                           onPressed: () {},
//                           icon: Icon(
//                             Icons.skip_next,
//                             color: Colors.white,
//                             size: 36,
//                           )),
//                       IconButton(
//                           onPressed: () {
//                             // db.listPlaylists();
//                             // db.deletePlaylist(pl);
//                           },
//                           icon: Icon(
//                             Icons.loop,
//                             color: Colors.white,
//                           ))
//                     ],
//                   )
//                 ],
//               ))
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
