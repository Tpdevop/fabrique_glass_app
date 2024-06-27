// factory_card.dart
import 'package:flutter/material.dart';

class FactoryCard extends StatelessWidget {
  final Map<String, dynamic> factory;
  final Animation<double> animation;
  final Animation<Offset> slideAnimation;
  final VoidCallback onTap;

  const FactoryCard({
    required this.factory,
    required this.animation,
    required this.slideAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String nom = factory['nom'];
    String prenom = factory['prenom'];

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
            contentPadding: EdgeInsets.all(15.0),
            leading: FadeTransition(
              opacity: animation,
              child: Icon(Icons.factory, color: Colors.orange, size: 40),
            ),
            title: Text(
              "La fabrique de $nom $prenom",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(factory['location'], style: TextStyle(fontSize: 16)),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
