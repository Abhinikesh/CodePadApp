import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:codepad_app/models/paste.dart';
import 'package:codepad_app/supabase_client.dart';

class PasteService {
  static const String _cacheKey = 'cached_pastes';

  static Future<List<Paste>> getPastes() async {
    try {
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        return await loadLocalCache();
      }
      final response = await supabase
          .from('Codepad')
          .select()
          .order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      final List<Paste> fetched = data
          .map((json) => Paste.fromJson(json as Map<String, dynamic>))
          .toList();
      await saveLocalCache(fetched);
      return fetched;
    } catch (_) {
      return await loadLocalCache();
    }
  }

  static Future<void> saveLocalCache(List<Paste> pastes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list =
        pastes.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_cacheKey, list);
  }

  static Future<List<Paste>> loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? list = prefs.getStringList(_cacheKey);
    if (list == null) return [];
    final loaded = list
        .map((item) => Paste.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return loaded;
  }

  static Future<bool> isTitleDuplicate(String title, {String? excludeId}) async {
    final list = await loadLocalCache();
    return list.any((p) =>
        p.title.trim().toLowerCase() == title.trim().toLowerCase() &&
        p.id != excludeId);
  }

  static Future<bool> createPaste(Paste paste) async {
    final isDuplicate = await isTitleDuplicate(paste.title);
    if (isDuplicate) {
      Fluttertoast.showToast(
        msg: "Title already exists",
        backgroundColor: const Color(0xFFFF5F56),
        textColor: Colors.white,
      );
      return false;
    }
    final currentList = await loadLocalCache();
    currentList.insert(0, paste);
    await saveLocalCache(currentList);
    try {
      if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        await supabase.from('Codepad').insert(paste.toJson());
      }
    } catch (_) {
      Fluttertoast.showToast(
        msg: "Saved offline",
        backgroundColor: const Color(0xFF2A2A40),
        textColor: Colors.white,
      );
    }
    return true;
  }

  static Future<bool> updatePaste(Paste paste) async {
    final isDuplicate = await isTitleDuplicate(paste.title, excludeId: paste.id);
    if (isDuplicate) {
      Fluttertoast.showToast(
        msg: "Title already exists",
        backgroundColor: const Color(0xFFFF5F56),
        textColor: Colors.white,
      );
      return false;
    }
    final currentList = await loadLocalCache();
    final index = currentList.indexWhere((p) => p.id == paste.id);
    if (index != -1) {
      currentList[index] = paste;
      await saveLocalCache(currentList);
    }
    try {
      if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        await supabase.from('Codepad').update(paste.toJson()).eq('id', paste.id);
      }
    } catch (_) {
      Fluttertoast.showToast(
        msg: "Updated offline",
        backgroundColor: const Color(0xFF2A2A40),
        textColor: Colors.white,
      );
    }
    return true;
  }

  static Future<bool> deletePaste(String id) async {
    final currentList = await loadLocalCache();
    currentList.removeWhere((p) => p.id == id);
    await saveLocalCache(currentList);
    try {
      if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        await supabase.from('Codepad').delete().eq('id', id);
      }
    } catch (_) {
      Fluttertoast.showToast(
        msg: "Deleted offline",
        backgroundColor: const Color(0xFF2A2A40),
        textColor: Colors.white,
      );
    }
    return true;
  }
}
