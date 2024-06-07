// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, avoid_print, constant_identifier_names

import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

const MONGO_URL =
    "mongodb+srv://medleminehaj:22482188@mycluster.j2cqkjb.mongodb.net/myapp?retryWrites=true&w=majority&appName=mycluster";
const COLLECTION_NAME = "Utilisateurs";

class MongoDatabase {
  static Future<mongo.Db> _openDb() async {
    var db = await mongo.Db.create(MONGO_URL);
    await db.open();
    return db;
  }

  static Future<void> closeDb(mongo.Db db) async {
    await db.close();
  }

  static Future<bool> login(String email, String password) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME);
    final user = await collection.findOne(mongo.where.eq('email', email).eq(
        'pwd',
        int.parse(password))); // Assurez-vous que le champ du mot de passe est 'pwd'

    await closeDb(db);
    return user !=
        null; // Renvoie true si l'utilisateur est trouvé, sinon false
  }

  

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME);
    final users = await collection.find().toList();
    await closeDb(db);
    return users;
  }

  static Future<bool> sendVerificationCode(String email) async {
    final db = await _openDb();
    final collection = db.collection(COLLECTION_NAME);
    final user = await collection.findOne(mongo.where.eq('email', email));
      final verificationCode = _generateVerificationCode();

    if (user == null) {
      await collection.insert({'email': email,'verificationCode': verificationCode});
    }

  else {
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
    final collection = db.collection(COLLECTION_NAME);
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
    final collection = db.collection(COLLECTION_NAME);
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
}
