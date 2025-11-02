import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireauth;
import 'package:firebase_core/firebase_core.dart';

import 'package:musicapp/data/Models.dart' as model;

class UserControl {
  final _auth = FirebaseAuth.instanceFor(app: Firebase.app());
  final _firestore = FirebaseFirestore.instance;
  late fireauth.User _user;
  Future<UserCredential> createUser({
    required String mail,
    required String pass,
  }) async {
    try {
      final usercr = await _auth.createUserWithEmailAndPassword(
          email: mail, password: pass);

      CollectionReference ref = _firestore.collection("Users");
      _user = usercr.user!;
      await ref.doc(usercr.user!.uid).set(
          model.User(userId: usercr.user!.uid, favoriteItems: [], playlists: [])
              .toFirestore());

      return usercr;
    } on FirebaseAuthException catch (e) {
      print("UserControl createUser Hata: $e");
      rethrow; // Hatayı ViewModel'a fırlat
    }
  }

  String getUSerId() {
    _user = _auth.currentUser!;
    return _user.uid;
  }

  fireauth.User getUser() {
    return _user;
  }

  String getEmail() {
    return _user.email.toString();
  }

  Future<UserCredential> login({
    required String mail,
    required String pass,
  }) async {
    try {
      final usercr =
          await _auth.signInWithEmailAndPassword(email: mail, password: pass);

      return usercr;
    } on FirebaseAuthException catch (e) {
      print("UserControl login Hata: $e");
      rethrow; // Hatayı ViewModel'a fırlat
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {}
  }

  Future<void> deleteUser() async {
    try {
      await _auth.currentUser!.delete();
    } catch (e) {}
  }
}
