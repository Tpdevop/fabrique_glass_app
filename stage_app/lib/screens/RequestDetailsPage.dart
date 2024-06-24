// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';

class RequestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> request;

  RequestDetailsPage({required this.request});

  @override
  Widget build(BuildContext context) {
    final clientNom = request['ClientNom'] ?? 'Inconnu';
    final clientPrenom = request['ClientPrenom'] ?? 'Inconnu';
    final quantite = request['quantite'] ?? 'Non spécifiée';
    final etat = request['etat'] ?? 'Inconnu';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de la demande',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(Icons.person, 'Nom du client', clientNom),
              _buildDetailCard(
                  Icons.person_outline, 'Prénom du client', clientPrenom),
              _buildDetailCard(
                  Icons.shopping_bag, 'Quantité demandée', '$quantite kg'),
              _buildDetailCard(Icons.info, 'État', etat),
              SizedBox(height: 30),
              if (etat == 'attendant') ...[
                _buildActionButton(
                    context, 'Accepter', Colors.green, 'acceptée', request),
                SizedBox(height: 10),
                _buildActionButton(
                    context, 'Refuser', Colors.red, 'refusée', request),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, Color color,
      String status, Map<String, dynamic> request) {
    return ElevatedButton(
      onPressed: () => _updateRequestStatus(context, status, request),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status == 'acceptée' ? Icons.check_circle : Icons.cancel,
              size: 24),
          SizedBox(width: 10),
          Text(text),
        ],
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black45,
        elevation: 10,
      ),
    );
  }

  Future<void> _updateRequestStatus(
      BuildContext context, String status, Map<String, dynamic> request) async {
    bool success = false;
    int quantite = status == 'acceptée' ? request['quantite'] : 0;
    final snackBar = SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Mise à jour en cours...'),
        ],
      ),
      duration: Duration(minutes: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    success = await MongoDatabase.updateRequestStatus(
        request['_id'], status, quantite, request['ID_Proprietaire']);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Demande $status.' : 'Erreur lors de la mise à jour.',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }
}
