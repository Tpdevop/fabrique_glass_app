// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = MongoDatabase.getAllUsers();
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
              'خذ ماتحب', // Take what you love in Arabic
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Aucun utilisateur trouvé.'));
                  } else {
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          title: Text(user['email']),
                          subtitle: Text(user['pwd']),
                        );
                      },
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
