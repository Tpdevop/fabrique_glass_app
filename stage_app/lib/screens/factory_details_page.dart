// factory_details_page.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';

class FactoryDetailsPage extends StatefulWidget {
  final int factoryId;
  final int clientId;

  FactoryDetailsPage({required this.factoryId, required this.clientId});

  @override
  _FactoryDetailsPageState createState() => _FactoryDetailsPageState();
}

class _FactoryDetailsPageState extends State<FactoryDetailsPage> {
  late Future<Map<String, dynamic>> _factoryFuture;
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _factoryFuture = MongoDatabase.getFactoryById(widget.factoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la fabrique'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _factoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('Aucune donnée trouvée.'));
            } else {
              final factory = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nom: ${factory['nom']}', style: TextStyle(fontSize: 20)),
                  Text('Emplacement: ${factory['location']}', style: TextStyle(fontSize: 18)),
                  Text('Description: ${factory['description']}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantité de glace',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Retrieve the entered quantity
                      int quantity = int.tryParse(_quantityController.text) ?? 0;
                      if (quantity > 0 && quantity < factory['quantite']) {
                        await MongoDatabase.sendRequest(
                          widget.clientId,
                          int.parse(factory['ID_Proprietaire']),
                          quantity,
                        );
                        // Add email notification logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Demande envoyée avec succès!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Veuillez entrer une quantité valide.')),
                        );
                      }
                    },
                    child: Text('Envoyer la demande'),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
