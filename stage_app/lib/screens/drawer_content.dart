// drawer_content.dart
// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, prefer_const_literals_to_create_immutables

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
                    accountName: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'الاسم الكامل : ${user['nom']} ${user['prenom']}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    accountEmail: Text(
                      'البريد الإلكتروني : $userEmail',
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    currentAccountPicture: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PhotoViewScreen(
                            userPhoto: userPhoto,
                            pickImage: pickImage,
                          ),
                        ));
                      },
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'userPhoto',
                            child: CircleAvatar(
                              backgroundImage: userPhoto.isNotEmpty
                                  ? FileImage(File(userPhoto))
                                  : AssetImage('images/person_icon.png')
                                      as ImageProvider,
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.deepPurple[700]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
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
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 15,
                                  color: Colors.deepPurple[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.red),
                    ),
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

class PhotoViewScreen extends StatelessWidget {
  final String userPhoto;
  final Future<void> Function() pickImage;

  const PhotoViewScreen({
    required this.userPhoto,
    required this.pickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صورة المستخدم'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'userPhoto',
              child: CircleAvatar(
                backgroundImage: userPhoto.isNotEmpty
                    ? FileImage(File(userPhoto))
                    : AssetImage('images/person_icon.png') as ImageProvider,
                radius: 100,
                backgroundColor: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurple[700]!,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('تغيير الصورة'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                await pickImage();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
