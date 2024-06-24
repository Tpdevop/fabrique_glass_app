// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';
import 'package:myapp/screens/RequestDetailsPage.dart';

class ReceivedRequestsPage extends StatefulWidget {
  final int ownerId;

  ReceivedRequestsPage({required this.ownerId});

  @override
  _ReceivedRequestsPageState createState() => _ReceivedRequestsPageState();
}

class _ReceivedRequestsPageState extends State<ReceivedRequestsPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _requestsFuture = MongoDatabase.getRequestsByOwnerEmail(widget.ownerId);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الطلبات المستلمة',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.blue[300]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'خطأ: ${snapshot.error}',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'لم يتم العثور على أي طلب.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                } else {
                  final requests = snapshot.data!;
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final clientNom = request['ClientNom'] ?? 'غير معروف';
                      final clientPrenom =
                          request['ClientPrenom'] ?? 'غير معروف';
                      final quantite =
                          request['quantite']?.toString() ?? 'غير محدد';
                      final etat = request['etat'] ?? 'غير معروف';

                      return FadeTransition(
                        opacity: _controller,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(_controller),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RequestDetailsPage(request: request),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 8,
                              shadowColor: Colors.black45,
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                leading: Icon(Icons.request_page,
                                    size: 40, color: Colors.blueAccent),
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
                                    color: _getStatusColor(etat),
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
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مقبول':
        return Colors.green;
      case 'مرفوض':
        return Colors.red;
      case 'معلق':
      default:
        return Colors.orange;
    }
  }
}
