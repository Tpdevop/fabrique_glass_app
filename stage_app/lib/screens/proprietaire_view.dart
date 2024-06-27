// proprietaire_view.dart
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
    required this.onItemTapped, required void Function() onEditQuantity,
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
                  if (clientSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (clientSnapshot.hasError) {
                    return Center(child: Text('Erreur: ${clientSnapshot.error}'));
                  } else if (!clientSnapshot.hasData) {
                    return Center(child: Text('Aucun client trouvé.'));
                  } else {
                    final client = clientSnapshot.data!;
                    return SlideTransition(
                      position: slideAnimation,
                      child: FadeTransition(
                        opacity: animation,
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 5,
                          child: ListTile(
                            title: Text('الكمية: ${request['quantite']} كغ', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الحالة: ${_translateStatus(request['etat'])}'),
                                Text('العميل: ${client['nom']} ${client['prenom']}'),
                              ],
                            ),
                            trailing: _buildRequestActions(request, ownerId),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check_circle, color: Colors.green),
            onPressed: () {
              _updateRequestStatus(request, 'acceptée', ownerId);
            },
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              _updateRequestStatus(request, 'refusée', ownerId);
            },
          ),
        ],
      );
    } else if (request['etat'] == 'acceptée') {
      return Icon(Icons.check_circle, color: Colors.green);
    } else if (request['etat'] == 'refusée') {
      return Icon(Icons.cancel, color: Colors.red);
    } else {
      return Container();
    }
  }

  Future<void> _updateRequestStatus(Map<String, dynamic> request, String status, int ownerId) async {
    final requestId = request['_id'] as mongo.ObjectId; // Ensure proper cast
    final quantite = request['quantite'] as int;
    await MongoDatabase.updateRequestStatus(requestId, status, quantite, ownerId);
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
