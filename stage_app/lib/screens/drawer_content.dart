// drawer_content.dart
import 'dart:io';
import 'package:flutter/material.dart';

class DrawerContent extends StatelessWidget {
  final Future<Map<String, dynamic>> userFuture;
  final String userEmail;
  final String userPhoto;
  final Future<void> Function() pickImage;
  final VoidCallback logout;

  const DrawerContent({
    required this.userFuture,
    required this.userEmail,
    required this.userPhoto,
    required this.pickImage,
    required this.logout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Aucun utilisateur trouvé.'));
          } else {
            final user = snapshot.data!;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text('${user['nom']} ${user['prenom']}'),
                    accountEmail: Text(userEmail),
                    currentAccountPicture: Stack(
                      children: [
                        Hero(
                          tag: 'userPhoto',
                          child: CircleAvatar(
                            backgroundImage: userPhoto.isNotEmpty
                                ? FileImage(File(userPhoto))
                                : AssetImage('images/person_icon.png'),
                            radius: 40,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: pickImage,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 15,
                              child: Icon(Icons.camera_alt, size: 15, color: Colors.deepPurple[700]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                    onTap: logout,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
