import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataRecoveryService {
  static const String _subjectsKey = 'subjects';
  static const String _lessonsKey = 'lessons';
  static const String _toolsKey = 'tools';

  /// Clear all corrupted data and reset to clean state
  static Future<void> clearCorruptedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Try to validate each data source
      await _validateAndCleanJsonData(prefs, _subjectsKey);
      await _validateAndCleanJsonData(prefs, _lessonsKey);
      await _validateAndCleanJsonData(prefs, _toolsKey);
    } catch (e) {
      print('Error during data recovery: $e');
      // If all else fails, clear everything
      await _clearAllData(prefs);
    }
  }

  static Future<void> _validateAndCleanJsonData(
    SharedPreferences prefs, 
    String key
  ) async {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return;
    
    try {
      // Try to parse the JSON
      json.decode(jsonString);
    } catch (e) {
      // If parsing fails, remove the corrupted data
      print('Removing corrupted data for key: $key');
      await prefs.remove(key);
    }
  }

  static Future<void> _clearAllData(SharedPreferences prefs) async {
    await prefs.remove(_subjectsKey);
    await prefs.remove(_lessonsKey);
    await prefs.remove(_toolsKey);
    print('All data cleared due to corruption');
  }

  /// Initialize with sample data if needed
  static Future<void> initializeSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have any subjects
    final subjectsJson = prefs.getString(_subjectsKey);
    if (subjectsJson == null) {
      // Add a sample subject to get users started
      final sampleData = [
        {
          'id': 'sample_subject_1',
          'name': 'مبادئ المحاسبة',
          'description': 'موضوع تجريبي للبدء',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ];
      
      await prefs.setString(_subjectsKey, json.encode(sampleData));
      
      // Add a sample lesson
      final sampleLesson = [
        {
          'id': 'sample_lesson_1',
          'subjectId': 'sample_subject_1',
          'title': 'الدرس الأول',
          'content': 'أهلاً بك في دفتر المحاسبة!\n\nيمكنك الآن البدء بالكتابة هنا.\n\nلإضافة أدوات المحاسبة، اضغط على زر + في الأعلى أو استخدم Ctrl+K',
          'tags': ['مقدمة'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ];
      
      await prefs.setString(_lessonsKey, json.encode(sampleLesson));
    }
  }
}