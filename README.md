import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData.dark(),
      home: GhostPortal(),
    ));

class GhostPortal extends StatefulWidget {
  @override
  _GhostPortalState createState() => _GhostPortalState();
}

class _GhostPortalState extends State<GhostPortal> {
  int daysLeft = 7;

  @override
  void initState() {
    super.initState();
    _checkCountdown();
  }

  _checkCountdown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? start = prefs.getString('start_date');
    if (start == null) {
      prefs.setString('start_date', DateTime.now().toString());
    } else {
      int passed = DateTime.now().difference(DateTime.parse(start)).inDays;
      setState(() { daysLeft = 7 - passed; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🌀 GHOST PORTAL", style: TextStyle(color: Colors.purple, fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 40),
            Text("$daysLeft", style: TextStyle(color: Colors.white, fontSize: 100)),
            Text("Days Remaining", style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
