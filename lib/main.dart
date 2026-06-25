import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:musicapp/views/new_home.dart';

import 'package:musicapp/services/Spottify.dart';
import 'package:musicapp/services/auth.dart';
import 'package:musicapp/services/music_service.dart';
import 'package:musicapp/services/new_database.dart';
import 'package:musicapp/viewmodels/auth_view_model.dart';

import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/viewmodels/navigation_view_model.dart';

import 'package:musicapp/views/new_log.dart';
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
import 'package:musicapp/views/New_Albumpage.dart';
import 'package:musicapp/views/PLaylistpage.dart';
import 'package:musicapp/views/SearchPage.dart';

import 'package:musicapp/widgets/New_Mini_player.dart';

import 'package:musicapp/widgets/Theme.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('youtubeUrls');

  runApp(msd());
}

// main.dart

class msd extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
   
    return MultiProvider(
      providers: [
        Provider(create: (_) => Spottify()),
        Provider<MusicService>(
          create: (_) => MusicService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider(create: (_) => UserControl()),
        Provider(create: (ctx) => Database(ctx.read<UserControl>())),
      ],
      child: ChangeNotifierProvider(
       
        create: (context) => AuthViewModel(
          context.read<UserControl>(),
          context.read<Database>(),
        ),
       
        child: Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
          
            return MultiProvider(
              providers: [
            
                ChangeNotifierProvider(create: (_) => NavigationViewModel()),
                ChangeNotifierProvider(
                  create: (context) => MiniPlayerViewModel(
                    context.read<MusicService>(),
                    context.read<Spottify>(),
                    context.read<Database>(),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (context) => PlaylistViewModel(
                    context.read<Database>(),
                    context.read<UserControl>(),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (context) => FavoritesViewModel(
                    context.read<Database>(),
                    context.read<UserControl>(),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (context) => SearchViewModel(
                    context.read<Spottify>(),
                  ),
                ),
                ChangeNotifierProvider(create: (_) => HomeViewModel()),
             
              ],
              child: MaterialApp(
                navigatorKey: navigatorKey,
                theme: MyTheme.themeData,
                debugShowCheckedModeBanner: false,
                title: 'My App',
             
                home: authViewModel.status == AuthStatus.authenticated
                    ? Home(user: authViewModel.user!)
                    : LoginPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  late auth.User user;
  Home({required this.user});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late auth.User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }


  final Map<int, GlobalKey<NavigatorState>> navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
  };

  Widget _buildNavigatorForTab(int index, Widget rootPage) {
    final key = navigatorKeys[index]!;

    return Navigator(
      key: key,
      onGenerateRoute: (routeSettings) {
      
        if (routeSettings.name == '/') {
          return MaterialPageRoute(builder: (context) => rootPage);
        }
      
        if (routeSettings.name == '/album' &&
            routeSettings.arguments is Album) {
          final album = routeSettings.arguments as Album;
          return MaterialPageRoute(
              builder: (context) => AlbumPage(albumSimple: album));
        }

        return MaterialPageRoute(builder: (context) => rootPage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<NavigationViewModel>().selectedIndex;
    final isMiniPlayerActive = context.watch<MiniPlayerViewModel>().isActive;
    const double miniPlayerHeight = 75.0;
    
    final GlobalKey<NavigatorState> currentNavigatorKey =
        navigatorKeys[selectedIndex]!;
    return WillPopScope(
      onWillPop: () async {
      
        final bool canPopNested =
            await currentNavigatorKey.currentState?.maybePop() ?? false;
       
        if (!canPopNested) {
         
          if (selectedIndex != 0) {
            context.read<NavigationViewModel>().setIndex(0);
            return false;
          } else {
           
            return true;
          }
        }
     
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
           
            Padding(
             
              padding: EdgeInsets.only(
                  bottom: isMiniPlayerActive ? miniPlayerHeight : 0.0),
              child: IndexedStack(
                index: selectedIndex,
                children: [
                  _buildNavigatorForTab(0, HomePage()),
                  _buildNavigatorForTab(1, SearchPage(user: _user)),
                  _buildNavigatorForTab(2, PLaylistpage()),
                ],
              ),
            ),

         
            Positioned(
              bottom: 0, 
              left: 0,
              right: 0,
              child: MiniPlayer(currentNavigatorKey: currentNavigatorKey),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
          
            if (selectedIndex == index) {
              navigatorKeys[index]
                  ?.currentState
                  ?.popUntil((route) => route.isFirst);
            }
        
            else {
              context.read<NavigationViewModel>().setIndex(index);
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.list), label: "Library"),
          ],
        ),
      ),
    );
  }
}
