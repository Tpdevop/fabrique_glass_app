// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, avoid_print, constant_identifier_names

import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

const MONGO_URL =
    "mongodb+srv://medleminehaj:22482188@mycluster.j2cqkjb.mongodb.net/myapp?retryWrites=true&w=majority&appName=mycluster";
const COLLECTION_NAME1 = "Utilisateurs";
const COLLECTION_NAME2 = "Client";
const COLLECTION_NAME3 = "Demande";
const COLLECTION_NAME4 = "Proprietaire";

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
    final collection = db.collection(COLLECTION_NAME1);
    final user = await collection.findOne(mongo.where.eq('email', email).eq(
        'pwd',
        int.parse(
            password))); // Assurez-vous que le champ du mot de passe est 'pwd'

    await closeDb(db);
    return user;
  }

  static Future<bool> sendVerificationCode(String email) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME1);
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
    final collection = db.collection(COLLECTION_NAME1);
    final user = await collection
        .findOne(mongo.where.eq('email', email).eq('verificationCode', code));

    if (user == null) {
      await closeDb(db);
      return false; // Invalid code or email
    }

    await collection.update(
      mongo.where.eq('email', email),
      mongo.modify.set('pwd', newPassword).unset('verificationCode'),
    );

    await closeDb(db);
    return true; // Password reset successfully
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

  static Future<bool> verifyCode(
      String email, String code, String Password) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME1);
    final user = await collection
        .findOne(mongo.where.eq('email', email).eq('verificationCode', code));

    if (user == null) {
      await closeDb(db);
      return false; // Invalid code or email
    }
    await collection.update(
      mongo.where.eq('email', email),
      mongo.modify.set('pwd', Password).unset('verificationCode'),
    );

    await closeDb(db);
    return true; // Password reset successfully
  }

  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME1);
    final user = await collection.findOne(mongo.where.eq('email', email));
    return user ?? {};
  }

  static Future<Map<String, dynamic>> getFactoryById(int factoryId) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME4);
    final user =
        await collection.findOne(mongo.where.eq('ID_Proprietaire', factoryId));
    return user ?? {};
  }

  static Future<List<Map<String, dynamic>>> getAllFactories() async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME4);
    final factories = await collection.find().toList();
    return factories;
  }

  static Future<void> sendRequest(
      int idClient, int idProprietaire, int quantite) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME3);
    await collection.insert({
      'ID_Client': idClient,
      'ID_Proprietaire': idProprietaire,
      'quantite': quantite,
      'etat': 'attendant',
    });
    _sendAnswer(idClient, idProprietaire, quantite);
  }

  static Future<bool> _sendAnswer(
      int idClient, int idProprietaire, int quantite) async {
    final smtpServer = SmtpServer('smtp.gmail.com',
        username: 'produitslocauxmauritaniens@gmail.com',
        password: 'oeuf ypbm elis fwqc');

    final db = await _openDb();
    final collection1 = db.collection('COLLECTION_NAME2');
    final collection2 = db.collection('COLLECTION_NAME4');
    final client =
        await collection1.findOne(mongo.where.eq('ID_Client', idClient));
    final proprietaire = await collection2
        .findOne(mongo.where.eq('ID_Proprietaire', idProprietaire));

    if (client == null || proprietaire == null) {
      print('Client or Proprietaire not found.');
      return false;
    }

    final message = Message()
      ..from = Address('produitslocauxmauritaniens@gmail.com', 'Elemine')
      ..recipients.add(proprietaire['email'])
      ..subject = 'Message de demande de glace'
      ..text =
          "L'utilisateur ${client['nom']} ${client['prenom']} a fait une demande d'une quantité de $quantite kg de glace de votre fabrique.";

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

  static Future<List<Map<String, dynamic>>> getRequestsByOwnerEmail(
      String email) async {
    final db = await _openDb();
    final collection1 = db.collection(COLLECTION_NAME3);
    final collection2 = db.collection(COLLECTION_NAME4);
    final collection3 =
        db.collection(COLLECTION_NAME2); // Collection des clients

    // final proprietaire =
    //     await collection2.findOne(mongo.where.eq('email', email));
    final requests = await collection1
        .find(
            mongo.where.eq('ID_Proprietaire', 1))
        .toList();

    // Ajouter les noms et prénoms des clients à chaque demande
    // for (var request in requests) {
    //   final client = await collection3
    //       .findOne(mongo.where.eq('ID_Client', request['ID_Client']));
    //   request['ClientNom'] = client?['nom'] ?? 'Inconnu';
    //   request['ClientPrenom'] = client?['prenom'] ?? 'Inconnu';
    // }

    return requests;
  }
}
