import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  Set<WordPair> userData = <WordPair>{};
  FirebaseStorage _storage = FirebaseStorage.instance;

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      userData = await getAllSavedSuggestions();
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Future<void> addPairToUserData(WordPair pair, String first, String second)async {
    if(_status == Status.Authenticated){
      await _firebaseFirestore.collection('Users').doc(_user!.uid)
          .collection('Saved Suggestions')
          .doc(pair.toString())
          .set({'first': first, 'second': second});
    }
    userData = await getAllSavedSuggestions();
    notifyListeners();
  }

  Future<void> removePairFromUserData(WordPair pair) async {
    if (_status == Status.Authenticated) {
      await _firebaseFirestore.collection('Users')
          .doc(_user!.uid)
          .collection('Saved Suggestions')
          .doc(pair.toString()).delete();
      userData = await getAllSavedSuggestions();
    }
    notifyListeners();
  }

  Future<Set<WordPair>> getAllSavedSuggestions() async {
    Set<WordPair> savedSuggestions = <WordPair>{};
    String first, second;
    await _firebaseFirestore.collection('Users')
        .doc(_user!.uid)
        .collection('Saved Suggestions')
        .get()
        .then((querySnapshot) {
      for (var result in querySnapshot.docs) {
        first = result.data().entries.first.value.toString();
        second = result.data().entries.last.value.toString();
        savedSuggestions.add(WordPair(first, second));
      }
    });
    return Future<Set<WordPair>>.value(savedSuggestions);
  }

  Set<WordPair> getData() {
    return userData;
  }

  String? getUserEmail(){
    return _user!.email;
  }

  Future<String> getImageUrl() async {
    return await _storage.ref('images').child(_user!.uid).getDownloadURL();
  }

  Future<void> uploadNewImage(File file)async {
    await _storage
        .ref('images')
        .child(_user!.uid)
        .putFile(file);
    notifyListeners();
  }

}