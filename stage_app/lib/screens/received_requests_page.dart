import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';
import '../screens/RequestDetailsPage.dart'; // Assurez-vous de créer cette page

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
        title: Text('Demandes reçues'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _requestsFuture,
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
                  final clientNom = request['ClientNom'] ?? 'Inconnu';
                  final clientPrenom = request['ClientPrenom'] ?? 'Inconnu';
                  final quantite = request['quantite'] ?? 'Non spécifiée';
                  final etat = request['etat'] ?? 'Inconnu';

                  return ListTile(
                    title: Text("Demande de: $clientNom $clientPrenom"),
                    subtitle: Text("Quantité: $quantite kg"),
                    trailing: Text("Statut: $etat"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestDetailsPage(request: request),
                        ),
                      );
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
