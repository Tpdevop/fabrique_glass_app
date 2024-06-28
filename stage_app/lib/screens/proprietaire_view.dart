// proprietaire_view.dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:myapp/data/mongo_database.dart';

class ProprietaireView extends StatelessWidget {
  final int ownerId;
  final Animation<double> animation;
  final Animation<Offset> slideAnimation;
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const ProprietaireView({
    required this.ownerId,
    required this.animation,
    required this.slideAnimation,
    required this.selectedIndex,
    required this.onItemTapped,
    required void Function() onEditQuantity,
  });

  @override
  Widget build(BuildContext context) {
    String status;
    if (selectedIndex == 0) {
      status = 'refusée';
    } else if (selectedIndex == 1) {
      status = 'acceptée';
    } else {
      status = 'attendant';
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoDatabase.getRequestsByOwnerAndStatus(ownerId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune demande trouvée.'));
        } else {
          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: MongoDatabase.getUserById(request['ID_Client']),
                builder: (context, clientSnapshot) {
                  if (clientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (clientSnapshot.hasError) {
                    return Center(
                        child: Text('Erreur: ${clientSnapshot.error}'));
                  } else if (!clientSnapshot.hasData) {
                    return Center(child: Text('Aucun client trouvé.'));
                  } else {
                    final client = clientSnapshot.data!;
                    return SlideTransition(
                      position: slideAnimation,
                      child: FadeTransition(
                        opacity: animation,
                        child: Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 5,
                          shadowColor: Colors.grey.withOpacity(0.5),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الكمية: ${request['quantite']} كغ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'الحالة: ${_translateStatus(request['etat'])}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'العميل: ${client['nom']} ${client['prenom']}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                                Divider(
                                  height: 20,
                                  thickness: 1,
                                  color: Colors.grey[300],
                                ),
                                _buildRequestActions(request, ownerId),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildRequestActions(Map<String, dynamic> request, int ownerId) {
    if (request['etat'] == 'attendant') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green, size: 30),
                onPressed: () {
                  _updateRequestStatus(request, 'acceptée', ownerId);
                },
              ),
              Text(
                'قبول',
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.cancel, color: Colors.red, size: 30),
                onPressed: () {
                  _updateRequestStatus(request, 'refusée', ownerId);
                },
              ),
              Text(
                'رفض',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ),
        ],
      );
    } else if (request['etat'] == 'acceptée') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 30),
          Text(
            'مقبولة',
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      );
    } else if (request['etat'] == 'refusée') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, color: Colors.red, size: 30),
          Text(
            'مرفوضة',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  Future<void> _updateRequestStatus(
      Map<String, dynamic> request, String status, int ownerId) async {
    final requestId = request['_id'] as mongo.ObjectId; // Ensure proper cast
    final quantite = request['quantite'] as int;
    await MongoDatabase.updateRequestStatus(
        requestId, status, quantite, ownerId);
    // Refresh the view
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'attendant':
        return 'قيد الانتظار';
      case 'acceptée':
        return 'مقبولة';
      case 'refusée':
        return 'مرفوضة';
      default:
        return status;
    }
  }
}
