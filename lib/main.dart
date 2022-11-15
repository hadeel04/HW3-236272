import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/auth_repository.dart';
import 'package:hello_me/LoginScreen.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthRepository>(
      create: (_) => AuthRepository.instance(),
      child: Consumer<AuthRepository>(
        builder: (context, _login, _) =>
            MaterialApp(
              title: 'Startup Name Generator',
              theme: ThemeData(
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  )
              ),
              // home: LoginScreen(),
              initialRoute: '/',
              routes: {
                '/': (context) => RandomWords(),
                '/login': (context) => LoginScreen(),
              },
            ),
      ),
    );
  }
}


class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);
  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  late AuthRepository firebaseUser;
  SnappingSheetController snappingSheetController = SnappingSheetController();
  bool isDragable = true;

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          // final deleteSnackBar = SnackBar(
          //     content: Text('Deletion  is  not  implemented yet'));
          final firebaseUser =Provider.of<AuthRepository>(context);
          var toShowFavorites = _saved;
          if(firebaseUser.isAuthenticated){
            toShowFavorites = _saved.union(firebaseUser.getData());
          }
          final tiles = toShowFavorites.map(
                (pair) {
              return Dismissible(
                key: ValueKey<WordPair>(pair),
                onDismissed: (DismissDirection direction) {
                  setState(() {
                    // toShowFavorites.remove(pair);
                    _saved.remove(pair);
                    if(firebaseUser.user != null) {
                      firebaseUser.removePairFromUserData(pair);
                    }
                  });
                },
                confirmDismiss: (DismissDirection direction) async {
                  // ScaffoldMessenger.of(context).showSnackBar(deleteSnackBar);
                  String word = pair.asPascalCase;
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Delete Confirmation"),
                        content: Text("Are you sure you want to delete "
                            " $word from your saved suggestions?"),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Yes")
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("No"),
                          ),
                        ],
                      );
                    },
                  );
                },

                child:
                ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                ),
                background: Container(
                  color: Colors.deepPurple,
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.white),
                      Text('Delete Suggestion',
                        style: TextStyle(color: Colors.white, fontSize: 18.0),),
                      // Text(data)
                    ],

                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.deepPurple,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Icon(Icons.delete, color: Colors.white),
                      Text('Delete Suggestion',
                        style: TextStyle(color: Colors.white, fontSize: 18.0),),
                      // Text(data)
                    ],
                  ),
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    firebaseUser = Provider.of<AuthRepository>(context);
    var icon = Icons.login;
    var onPressedFunc = _loginScreen;
    if (firebaseUser.isAuthenticated) {
      icon = Icons.exit_to_app;
      onPressedFunc = _pushLogout;
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Startup Name Generator'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: _pushSaved,
              tooltip: 'Saved Suggestions',
            ),
            IconButton(
              icon: Icon(icon),
              onPressed: onPressedFunc,
              tooltip: 'Login Page',
            ),
          ],
        ),
        body: GestureDetector(
            child: SnappingSheet(
              lockOverflowDrag: true,
              controller: snappingSheetController,
              snappingPositions: const [
                SnappingPosition.pixels(
                    positionPixels: 150,
                    snappingCurve: Curves.bounceOut,
                    snappingDuration: Duration(milliseconds: 1)),
                SnappingPosition.factor(
                    positionFactor: 0.8,
                    snappingCurve: Curves.easeInBack,
                    snappingDuration: Duration(milliseconds: 1)),
              ],
              child: _buildSuggestions(),
              sheetBelow: firebaseUser.isAuthenticated
                  ? SnappingSheetContent(
                draggable: true,
                child: Container(
                  color: Colors.white,
                  child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Column(children: [
                          Row(children: <Widget>[
                            Expanded(
                              child: Container(
                                color: Colors.grey,
                                child: Row(
                                  children: <Widget>[
                                    Text(" Welcome back, " +
                                        firebaseUser.getUserEmail()
                                            .toString(),
                                      style: const TextStyle(fontSize: 18.0),
                                      // textAlign: TextAlign.center,
                                    ),
                                    const Spacer(),
                                    const IconButton(
                                      // padding: EdgeInsets.only(left: 75),
                                      // alignment: AlignmentDirectional.centerEnd,
                                      icon: Icon(Icons.keyboard_arrow_up),
                                      onPressed: null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                          Row(children: <Widget>[
                            FutureBuilder(
                              future: firebaseUser.getImageUrl(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                return Container(
                                  padding: const EdgeInsets.all(5),
                                  child: CircleAvatar(
                                    radius: 40.0,
                                    backgroundImage: (snapshot.data == null)
                                        ? null
                                        : NetworkImage(snapshot.data!),
                                  ),
                                );
                              },
                            ),
                            Column(children: [
                              Text(firebaseUser.getUserEmail().toString(),
                                  style: const TextStyle(fontSize: 18)
                              ),
                              MaterialButton(
                                child: Container(
                                  color: Colors.blue,
                                  padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 20.0,
                                      bottom: 3.0,
                                      top: 3.0
                                  ),
                                  child: const Text('Change Avatar',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ),
                                onPressed: () async {
                                  FilePickerResult? picked =
                                  await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'png',
                                      'jpg',
                                      'gif',
                                      'bmp',
                                      'jpeg',
                                      'webp'
                                    ],
                                  );
                                  if (picked != null) {
                                    File file = File(picked.files.single.path!);
                                    firebaseUser.uploadNewImage(file);
                                  }else{
                                    const noSelectedImage = SnackBar(
                                        content: Text('No  image  selected'));
                                    ScaffoldMessenger.of(context).
                                    showSnackBar(noSelectedImage);
                                  }
                                },
                              ),
                            ],
                            ),
                          ],

                          ),

                        ]
                        ),
                      ]
                  ),
                ),
                //heightBehavior: SnappingSheetHeight.fit(),
              )
                  : null,
            ),
            onTap: () => {
              setState(() {
                if (isDragable == false) {
                  isDragable = true;
                  snappingSheetController.snapToPosition(
                      const SnappingPosition.factor(
                        positionFactor: 0.230,
                      )
                  );
                } else {
                  isDragable = false;
                  snappingSheetController.snapToPosition(
                      const SnappingPosition.factor(
                        positionFactor: 0.07,
                      )
                  );
                }
              })
            })
    );
  }


  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return const Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index], index);
        }
    );
  }

  Widget _buildRow(WordPair pair, index) {
    final alreadySaved = _saved.contains(pair);
    final alreadySavedInUserData = (firebaseUser.isAuthenticated)
        && (firebaseUser.getData().contains(pair));
    final isSaved = alreadySaved || alreadySavedInUserData;
    if(alreadySaved && !alreadySavedInUserData){
      if(firebaseUser.user != null) {
        firebaseUser.addPairToUserData(pair, pair.first, pair.second);
      }
    }
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        isSaved ? Icons.star : Icons.star_border,
        color: isSaved ? Colors.deepPurple : null,
        semanticLabel: isSaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (isSaved) {
            _saved.remove(pair);
            if(firebaseUser.user != null) {
              firebaseUser.removePairFromUserData(pair);
            }
          } else {
            _saved.add(pair);
            if(firebaseUser.isAuthenticated) {
              firebaseUser.addPairToUserData(pair, pair.first, pair.second);
            }
          }
        });
      },
    );
  }

  void _pushLogout() async{
    final signout_snackBar = SnackBar(
        content: Text('Successfully logged out'));
    _saved.clear();
    await firebaseUser.signOut();
    ScaffoldMessenger.of(context).showSnackBar(signout_snackBar);
  }

  void _loginScreen() {
    Navigator.pushNamed(context, '/login');
  }


}

