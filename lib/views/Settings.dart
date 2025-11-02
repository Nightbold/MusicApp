import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';

import 'package:musicapp/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class settings extends StatefulWidget {
  const settings({super.key});

  @override
  State<settings> createState() => _settingsState();
}

class _settingsState extends State<settings> {
  @override
  Widget build(BuildContext context) {
    final ucontrol = context.read<AuthViewModel>();
    return SafeArea(
      child: Scaffold(
          body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 60),
              child: CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
          ),
          Divider(
            height: 80,
            endIndent: 50,
            indent: 50,
          ),
          Column(
            children: [
              ElevatedButton.icon(
                  onPressed: () async {
                    await ucontrol.signOut();
                    Navigator.pop(context);
                  },
                  icon: FaIcon(FontAwesomeIcons.outdent),
                  label: Text("Çıkış Yap")),
              Gap(50),
              ElevatedButton.icon(
                  onPressed: () async {
                    ucontrol.deleteUser();
                  },
                  icon: FaIcon(FontAwesomeIcons.outdent),
                  label: Text("Hesabı Sil")),
              Gap(50),
              // ElevatedButton.icon(
              //     onPressed: () {},
              //     icon: FaIcon(FontAwesomeIcons.outdent),
              //     label: Text("Çıkış Yap")),
            ],
          ),
        ],
      )),
    );
  }
}
