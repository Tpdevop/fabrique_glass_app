// ignore_for_file: prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables

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
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _factoryFuture = MongoDatabase.getFactoryById(widget.factoryId);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _sendRequest(int quantity, Map<String, dynamic> factory) async {
    if (quantity > 0 && quantity <= (factory['quantite'] ?? 0)) {
      await MongoDatabase.sendRequest(
        widget.clientId,
        factory['ID_Proprietaire'] ?? 0, // Ensure it's an int
        quantity,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.green),
              SizedBox(width: 10),
              Text('تم إرسال الطلب بنجاح!'),
            ],
          ),
        ),
      );
      _quantityController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('الرجاء إدخال كمية صالحة.'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildFactoryDetails(Map<String, dynamic> factory) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.factory, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'اسم: ${factory['nom']}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.redAccent, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'الموقع: ${factory['location']}',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontFamily: 'Roboto'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.description, color: Colors.green, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الوصف: ${factory['description']}',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'كمية الجليد',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: ElevatedButton(
                  onPressed: () {
                    int quantity = int.tryParse(_quantityController.text) ?? 0;
                    _sendRequest(quantity, factory);
                  },
                  child: Text('إرسال الطلب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isHovering ? Colors.orange[700] : Colors.orange,
                    textStyle: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    shadowColor: Colors.black,
                    elevation: 8.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل المصنع',
          style: TextStyle(
              color: Colors.white, fontSize: 27.0, fontFamily: 'Roboto'),
        ),
        backgroundColor: Colors.deepPurple[700],
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'images/background.png'), // Ensure you have a background image in assets
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _factoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('لم يتم العثور على بيانات.'));
            } else {
              final factory = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text('Nom: ${factory['nom']}',
                      style: TextStyle(fontSize: 20)),
                  SizedBox(height: 10),
                  Text('Emplacement: ${factory['location']}',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  Text('Description: ${factory['description']}',
                      style: TextStyle(fontSize: 16)),
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
                      int quantity =
                          int.tryParse(_quantityController.text) ?? 0;
                      if (quantity > 0 && quantity <= factory['quantite']) {
                        await MongoDatabase.sendRequest(
                          widget.clientId,
                          factory['ID_Proprietaire'],
                          quantity,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Demande envoyée avec succès!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Veuillez entrer une quantité valide.')),
                        );
                      }
                    },
                    child: Text('Envoyer la demande'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      textStyle: TextStyle(fontWeight: FontWeight.bold),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
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
