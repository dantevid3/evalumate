// lib/services/auth.dart

import 'package:evalumate/models/currentuser.dart'; // Your CurrentUser model
// Your DatabaseService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //create user obj based on firebase user
  CurrentUser? _userFromFirebaseUser(User? user){
    return user != null ? CurrentUser(uid: user.uid) : null;
  }

  //auth change user stream
  Stream<CurrentUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  //sign in anon
  Future signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      //print(e.toString());
      return null;
    }
  }

  //sign in email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  //register with email and password
  Future<CurrentUser?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a Firestore document for the user in the 'profiles' collection
        await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set({
          'email': email,
          'userName': '', // Default name, can be updated later
          'bio': '', // Default bio, can be updated later
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //sign out
  Future signOut() async {
    try{
      return await _auth.signOut();
    }catch(e){
      print(e.toString());
      return null;
    }
  }
}