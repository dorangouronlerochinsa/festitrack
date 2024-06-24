import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'create_event_screen.dart';
import 'map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FestiTrack")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await _signInWithGoogle();
            if (user != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage(user: user)),
              );
            }
          },
          child: Text("Sign in with Google"),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final User user;

  HomePage({required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isEventOngoing = false;
  String? _eventId;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkEventStatus();
    _requestLocationPermission();
  }

  Future<void> _checkEventStatus() async {
    final now = DateTime.now();
    final query = await FirebaseFirestore.instance
        .collection('events')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _isEventOngoing = true;
        _eventId = query.docs.first.id;
      });
    } else {
      setState(() {
        _isEventOngoing = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission.isGranted) {
      setState(() {
        _hasLocationPermission = true;
      });
    } else {
      // Handle the case when permission is not granted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permission is required to use this feature.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Text("Hello username !", style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24
          ),),
        ],
      )),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
                                              //if (_isEventOngoing)
              Column(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    child: _hasLocationPermission
                        ? MapScreen(eventId: _eventId)
                        : Center(child: CircularProgressIndicator()),
                  ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("En cours",style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber
                        ),),
                        SizedBox(height: 4,),
                        Text("eventName",style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600
                        ),),
                        SizedBox(height: 8,)
                      ],
                    ),
                ],
              ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('À venir',style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600
                        ),),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateEventScreen()),
                            ).then((value) {
                              _checkEventStatus();
                            });
                          },
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }
}
