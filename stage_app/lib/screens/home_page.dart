// home_page.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';

class HomePage extends StatefulWidget {
  final String userType;
  final String userEmail;

  HomePage({required this.userType, required this.userEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = MongoDatabase.getUserByEmail(widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الرئيسية'), // Home in Arabic
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Add your menu action here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add your "حاليا" action here
                  },
                  child: Text('حاليا'), // Now in Arabic
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add your "تاريخ" action here
                  },
                  child: Text('تاريخ'), // History in Arabic
                ),
              ],
            ),
            Text(
              'Type d\'utilisateur: ${widget.userType}', // Display the user type
              style: TextStyle(fontSize: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add your "اختيار" action here
                  },
                  child: Text('اختيار'), // Choose in Arabic
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add your "نقل" action here
                  },
                  child: Text('نقل'), // Move in Arabic
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return Center(child: Text('Aucun utilisateur trouvé.'));
                  } else {
                    final user = snapshot.data!;
                    return ListTile(
                      title: Text(user['email']),
                      subtitle: Text(user['pwd'].toString()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
