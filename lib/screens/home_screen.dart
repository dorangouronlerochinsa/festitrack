import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/screens/create_event_screen.dart';
import 'package:festitrack/screens/map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEventOngoing = false;
  String? _eventId;

  @override
  void initState() {
    super.initState();
    _checkEventStatus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          Text(
            "Hello username !",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
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
                      child: MapWidget(eventId: _eventId)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "En cours",
                        style: TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        "eventName",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 8,
                      )
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'À venir',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CreateEventScreen()),
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
