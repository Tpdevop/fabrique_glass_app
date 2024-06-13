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
        title: Text('Détails de la demande'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom du client: $clientNom', style: TextStyle(fontSize: 20)),
            Text('Prénom du client: $clientPrenom',
                style: TextStyle(fontSize: 20)),
            Text('Quantité demandée: $quantite kg',
                style: TextStyle(fontSize: 20)),
            Text('État: $etat', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            if (etat == 'attendant') ...[
              ElevatedButton(
                onPressed: () async {
                  bool success = await MongoDatabase.updateRequestStatus(
                      request['_id'],
                      'acceptée',
                      request['quantite'],
                      request['ID_Proprietaire']);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Demande acceptée. Quantité mise à jour.')),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de la mise à jour.')),
                    );
                  }
                },
                child: Text('Accepter'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool success = await MongoDatabase.updateRequestStatus(
                      request['_id'], 'refusée', 0, request['ID_Proprietaire']);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Demande refusée.')),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de la mise à jour.')),
                    );
                  }
                },
                child: Text('Refuser'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
