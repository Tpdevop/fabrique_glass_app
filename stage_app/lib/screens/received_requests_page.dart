// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';

class ReceivedRequestsPage extends StatefulWidget {
  final String userEmail;

  ReceivedRequestsPage({required this.userEmail});

  @override
  _ReceivedRequestsPageState createState() => _ReceivedRequestsPageState();
}

class _ReceivedRequestsPageState extends State<ReceivedRequestsPage> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = MongoDatabase.getRequestsByOwnerEmail(widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الطلبات المستلمة'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _requestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('لم يتم العثور على أي طلب.'));
              } else {
                final requests = snapshot.data!;
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final clientNom = request['ClientNom'] ?? 'غير معروف';
                    final clientPrenom = request['ClientPrenom'] ?? 'غير معروف';
                    final quantite =
                        request['quantite']?.toString() ?? 'غير محدد';
                    final etat = request['etat'] ?? 'غير معروف';

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: ListTile(
                        title: Text(
                          "طلب من: $clientNom $clientPrenom",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          "الكمية: $quantite كجم",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            "الحالة: $etat",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}