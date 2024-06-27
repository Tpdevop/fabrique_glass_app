// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, avoid_print, constant_identifier_names

import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

const MONGO_URL =
    "mongodb+srv://medleminehaj:22482188@mycluster.j2cqkjb.mongodb.net/myapp?retryWrites=true&w=majority&appName=mycluster";
const Utilisateurs_COLLECTION = "Utilisateurs";
const Client_COLLECTION = "Client";
const Demande_COLLECTION = "Demande";
const Proprietaire_COLLECTION = "Proprietaire";

class MongoDatabase {
  static Future<mongo.Db> _openDb() async {
    var db = await mongo.Db.create(MONGO_URL);
    await db.open();
    return db;
  }

  static Future<void> closeDb(mongo.Db db) async {
    await db.close();
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final db = await _openDb();
    final collection = db.collection(Utilisateurs_COLLECTION);
    final user = await collection
        .findOne(mongo.where.eq('email', email).eq('pwd', int.parse(password)));

    await closeDb(db);
    return user;
  }

  static Future<bool> sendVerificationCode(String email) async {
    final db = await _openDb();
    final collection = db.collection(Utilisateurs_COLLECTION);
    final user = await collection.findOne(mongo.where.eq('email', email));
    final verificationCode = _generateVerificationCode();

    if (user == null) {
      await collection
          .insert({'email': email, 'verificationCode': verificationCode});
    } else {
      await collection.update(
        mongo.where.eq('email', email),
        mongo.modify.set('verificationCode', verificationCode),
      );
    }

    await closeDb(db);

    return _sendEmail(email, verificationCode);
  }

  static Future<bool> verifyCodeAndResetPassword(
      String email, String code, String newPassword) async {
    final db = await _openDb();
    final collection = db.collection(Utilisateurs_COLLECTION);
    final user = await collection
        .findOne(mongo.where.eq('email', email).eq('verificationCode', code));

    if (user == null) {
      await closeDb(db);
      return false;
    }

    await collection.update(
      mongo.where.eq('email', email),
      mongo.modify.set('pwd', newPassword).unset('verificationCode'),
    );

    await closeDb(db);
    return true;
  }

  static String _generateVerificationCode() {
    final random = Random();
    const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final codeLength = 6;

    return List.generate(codeLength,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();
  }

  static Future<bool> _sendEmail(String email, String code) async {
    final smtpServer = SmtpServer('smtp.gmail.com',
        username: 'produitslocauxmauritaniens@gmail.com',
        password: 'oeuf ypbm elis fwqc');

    final message = Message()
      ..from = Address('produitslocauxmauritaniens@gmail.com', 'Elemine')
      ..recipients.add(email)
      ..subject = 'Code de vérification'
      ..text = 'Votre code de vérification est: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      print('Message not sent. $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    final db = await _openDb();
    final userCollection = db.collection(Utilisateurs_COLLECTION);
    final clientCollection = db.collection(Client_COLLECTION);
    final proprietaireCollection =
        db.collection(Proprietaire_COLLECTION); // Add this line

    final user = await userCollection.findOne(mongo.where.eq('email', email));
    if (user == null) {
      await closeDb(db);
      return {};
    }

    final clientId = user['ID_Client'];
    final proprietaireId = user['ID_Proprietaire']; // Add this line

    if (clientId != null) {
      final client =
          await clientCollection.findOne(mongo.where.eq('ID_Client', clientId));
      await closeDb(db);
      return {...user, ...?client};
    } else if (proprietaireId != null) {
      // Add this condition
      final proprietaire = await proprietaireCollection
          .findOne(mongo.where.eq('ID_Proprietaire', proprietaireId));
      await closeDb(db);
      return {...user, ...?proprietaire};
    }

    await closeDb(db);
    return user;
  }

  static Future<Map<String, dynamic>> getFactoryById(int factoryId) async {
    final db = await _openDb();
    final collection = db.collection(Proprietaire_COLLECTION);
    final user =
        await collection.findOne(mongo.where.eq('ID_Proprietaire', factoryId));
    return user ?? {};
  }

  static Future<List<Map<String, dynamic>>> getAllFactories() async {
    final db = await _openDb();
    final collection = db.collection(Proprietaire_COLLECTION);
    final factories = await collection.find().toList();
    return factories;
  }

  static Future<Future<bool>> sendRequest(
      int idClient, int idProprietaire, int quantite) async {
    final db = await _openDb();
    final collection = db.collection(Demande_COLLECTION);
    await collection.insert({
      'ID_Client': idClient,
      'ID_Proprietaire': idProprietaire,
      'quantite': quantite,
      'etat': 'attendant',
    });
    return _sendAnswer(idClient, idProprietaire, quantite);
  }

  static Future<bool> _sendAnswer(
      int idClient, int idProprietaire, int quantite) async {
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: 'produitslocauxmauritaniens@gmail.com',
      password: 'uypk biho htjc lsyz',
      ignoreBadCertificate: true,
    );

    final db = await _openDb();
    final collection1 = db.collection(Client_COLLECTION);
    final collection2 = db.collection(Proprietaire_COLLECTION);
    final client =
        await collection1.findOne(mongo.where.eq('ID_Client', idClient));
    final proprietaire = await collection2
        .findOne(mongo.where.eq('ID_Proprietaire', idProprietaire));

    if (client == null || proprietaire == null) {
      print('Client or Proprietaire not found.');
      return false;
    }

    String nomCl = client['nom'];
    String prenomCl = client['prenom'];

    final message = Message()
      ..from = Address('produitslocauxmauritaniens@gmail.com', 'ice app')
      ..recipients.add(proprietaire['email'])
      ..subject = 'Message de demande de glace'
      ..text =
          "L'utilisateur $nomCl $prenomCl a fait une demande d'une quantité de $quantite kg de glace de votre fabrique.";

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      print('Message not sent. ${e.toString()}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  static Future<int?> getProprietaireParEmail(String email) async {
    final db = await _openDb();
    final collection2 = db.collection(Proprietaire_COLLECTION);

    // Supprimer les espaces supplémentaires autour de l'email
    email = email.trim();

    final proprietaire =
        await collection2.findOne(mongo.where.eq('email', email));

    if (proprietaire != null) {
      print('Propriétaire trouvé: $proprietaire');
      return proprietaire['ID_Proprietaire'];
    } else {
      print('Aucun propriétaire trouvé pour cet email: $email');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getRequestsByOwnerEmail(
      int id) async {
    final db = await _openDb();
    final collection1 = db.collection(Demande_COLLECTION);

    final requests =
        await collection1.find(mongo.where.eq('ID_Proprietaire', id)).toList();
    return requests;
  }

  static Future<bool> updateRequestStatus(mongo.ObjectId requestId,
      String status, int quantite, int idProprietaire) async {
    final db = await _openDb();
    final collection = db.collection(Demande_COLLECTION);
    final factoryCollection = db.collection(Proprietaire_COLLECTION);

    // Update the request status
    await collection.updateOne(
      mongo.where.id(requestId),
      mongo.modify.set('etat', status),
    );

    // If the status is accepted, update the quantity in the factory
    if (status == 'acceptée') {
      final factory = await factoryCollection
          .findOne(mongo.where.eq('ID_Proprietaire', idProprietaire));
      if (factory != null) {
        int currentQuantite = factory['quantite'] ?? 0;
        int newQuantite = currentQuantite - quantite;

        if (newQuantite < 0) {
          print('Not enough quantity available.');
          return false;
        }

        await factoryCollection.updateOne(
          mongo.where.eq('ID_Proprietaire', idProprietaire),
          mongo.modify.set('quantite', newQuantite),
        );
      }
    }

    return true;
  }

  static Future<List<Map<String, dynamic>>> getRequestsByOwnerAndStatus(
      int id, String status) async {
    final db = await _openDb();
    final collection1 = db.collection(Demande_COLLECTION);

    final requests = await collection1
        .find(mongo.where.eq('ID_Proprietaire', id).eq('etat', status))
        .toList();
    return requests;
  }

  static Future<Map<String, dynamic>> getUserById(int id) async {
    final db = await _openDb();
    final userCollection = db.collection(Client_COLLECTION);
    final user = await userCollection.findOne(mongo.where.eq('ID_Client', id));
    await closeDb(db);
    return user ?? {};
  }

  static Future<void> updateOwnerQuantity(String email, int newQuantity) async {
    var db = await mongo.Db.create(MONGO_URL);
    await db.open();
    var collection = db.collection(Proprietaire_COLLECTION);

    await collection.update(
      mongo.where.eq('email', email),
      mongo.modify.set('quantite', newQuantity),
    );

    await db.close();
  }
}
