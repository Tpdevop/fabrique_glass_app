import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataManager {
  static const String _keyQuantite = 'quantite';
  static const String _keyDateAjout = 'date_ajout';

  static Future<void> saveQuantite(int quantite) async {
    final prefs = await SharedPreferences.getInstance();
    final dateAjout = DateTime.now().toIso8601String();
    await prefs.setInt(_keyQuantite, quantite);
    await prefs.setString(_keyDateAjout, dateAjout);
  }

  static Future<Map<String, dynamic>> getQuantite() async {
    final prefs = await SharedPreferences.getInstance();
    final quantite = prefs.getInt(_keyQuantite) ?? 0;
    final dateAjout = DateTime.parse(prefs.getString(_keyDateAjout) ?? DateTime.now().toIso8601String());
    return {'quantite': quantite, 'date_ajout': dateAjout};
  }

  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQuantite);
    await prefs.remove(_keyDateAjout);
  }
}
