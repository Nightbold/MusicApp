// userlog.dart (veya ilgili dosya)

import 'package:flutter/material.dart';
import 'package:musicapp/main.dart';
import 'package:musicapp/services/new_database.dart';
import 'package:musicapp/services/Spottify.dart';
import 'package:musicapp/services/auth.dart';
import 'package:musicapp/services/music_service.dart';
import 'package:musicapp/viewmodels/favorites_view_model.dart';
import 'package:musicapp/viewmodels/home_view_model.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/viewmodels/navigation_view_model.dart';
import 'package:musicapp/viewmodels/playlist_view_model.dart';
import 'package:musicapp/viewmodels/search_view_model.dart';

import 'package:musicapp/views/new_login.dart';
import 'package:musicapp/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class userlog extends StatelessWidget {
  const userlog({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthViewModel'daki durumu 'watch' ile dinle
    final authStatus = context.watch<AuthViewModel>().status;
    final user = context.watch<AuthViewModel>().user;

    switch (authStatus) {
      case AuthStatus.authenticated:
        // Kullanıcı giriş yapmış, Home'u göster
        return MultiProvider(
            key: ValueKey(user!.uid!),
            providers: [
              // ChangeNotifierProvider(create: (_) => activeprovider()),
              ChangeNotifierProvider(create: (_) => NavigationViewModel()),
              ChangeNotifierProvider(
                  create: (context) => PlaylistViewModel(
                      context.read<Database>(), context.read<UserControl>())),
              ChangeNotifierProvider(
                create: (context) => FavoritesViewModel(
                  context.read<Database>(),
                  context.read<UserControl>(),
                ),
              ),
              ChangeNotifierProvider(
                create: (context) => SearchViewModel(
                  context.read<Spottify>(), // Spottify servisini inject et
                ),
              ),
              ChangeNotifierProvider(
                create: (context) => MiniPlayerViewModel(
                    context.read<MusicService>(),
                    context.read<Spottify>(),
                    context.read<Database>()),
              ),
              ChangeNotifierProvider(create: (_) => HomeViewModel())
            ],
            child: Home(user: user!));
      case AuthStatus.unauthenticated:
        // Kullanıcı giriş yapmamış, LoginPage'i göster
        return LoginPage(); // Eski 'signin' veya 'singup' yerine geçecek ana giriş sayfası
      case AuthStatus.loading:
      case AuthStatus.unknown:
      default:
        // Durum bilinmiyor veya yükleniyor, bekleme ekranı göster
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
