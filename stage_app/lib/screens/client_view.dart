// client_view.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';
import 'package:myapp/screens/factory_card.dart';
import 'package:myapp/screens/factory_details_page.dart';

class ClientView extends StatelessWidget {
  final int clientId;
  final Animation<double> animation;
  final Animation<Offset> slideAnimation;

  const ClientView({
    required this.clientId,
    required this.animation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مرحبًا بك',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[700]),
        ),
        SizedBox(height: 16),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: MongoDatabase.getAllFactories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Aucune fabrique trouvée.'));
              } else {
                final factories = snapshot.data!;
                return ListView.builder(
                  itemCount: factories.length,
                  itemBuilder: (context, index) {
                    final factory = factories[index];
                    return FactoryCard(
                      factory: factory,
                      animation: animation,
                      slideAnimation: slideAnimation,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FactoryDetailsPage(
                              factoryId: factory['ID_Proprietaire'],
                              clientId: clientId,
                            ),
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
      ],
    );
  }
}
