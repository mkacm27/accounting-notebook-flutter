import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_models.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();
  
  AppDatabase._();

  // Storage keys
  static const String _subjectsKey = 'subjects';
  static const String _lessonsKey = 'lessons';
  static const String _toolsKey = 'embedded_tools';

  // Get SharedPreferences instance
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Subject operations
  Future<List<Subject>> getAllSubjects() async {
    final prefs = await _prefs;
    final String? subjectsJson = prefs.getString(_subjectsKey);
    
    if (subjectsJson == null) return [];
    
    try {
      final List<dynamic> subjectsList = json.decode(subjectsJson);
      return subjectsList.map((json) => Subject.fromJson(json)).toList();
    } catch (e) {
      // If JSON parsing fails, clear corrupted data and return empty list
      await prefs.remove(_subjectsKey);
      return [];
    }
  }

  Future<Subject?> getSubject(String id) async {
    final subjects = await getAllSubjects();
    try {
      return subjects.firstWhere((subject) => subject.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> insertSubject(Subject subject) async {
    final subjects = await getAllSubjects();
    subjects.add(subject);
    return _saveSubjects(subjects);
  }

  Future<bool> updateSubject(Subject updatedSubject) async {
    final subjects = await getAllSubjects();
    final index = subjects.indexWhere((s) => s.id == updatedSubject.id);
    
    if (index != -1) {
      subjects[index] = updatedSubject;
      return _saveSubjects(subjects);
    }
    return false;
  }

  Future<bool> deleteSubject(String id) async {
    final subjects = await getAllSubjects();
    final initialLength = subjects.length;
    subjects.removeWhere((subject) => subject.id == id);
    
    if (subjects.length != initialLength) {
      // Also delete associated lessons
      final lessons = await getAllLessons();
      lessons.removeWhere((lesson) => lesson.subjectId == id);
      await _saveLessons(lessons);
      
      return _saveSubjects(subjects);
    }
    return false;
  }

  // Lesson operations
  Future<List<Lesson>> getAllLessons() async {
    final prefs = await _prefs;
    final String? lessonsJson = prefs.getString(_lessonsKey);
    
    if (lessonsJson == null) return [];
    
    try {
      final List<dynamic> lessonsList = json.decode(lessonsJson);
      return lessonsList.map((json) => Lesson.fromJson(json)).toList();
    } catch (e) {
      // If JSON parsing fails, clear corrupted data and return empty list
      await prefs.remove(_lessonsKey);
      return [];
    }
  }

  Future<List<Lesson>> getLessonsForSubject(String subjectId) async {
    final lessons = await getAllLessons();
    return lessons.where((lesson) => lesson.subjectId == subjectId).toList();
  }

  Future<Lesson?> getLesson(String id) async {
    final lessons = await getAllLessons();
    try {
      return lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> insertLesson(Lesson lesson) async {
    final lessons = await getAllLessons();
    lessons.add(lesson);
    return _saveLessons(lessons);
  }

  Future<bool> updateLesson(Lesson updatedLesson) async {
    final lessons = await getAllLessons();
    final index = lessons.indexWhere((l) => l.id == updatedLesson.id);
    
    if (index != -1) {
      lessons[index] = updatedLesson;
      return _saveLessons(lessons);
    }
    return false;
  }

  Future<bool> deleteLesson(String id) async {
    final lessons = await getAllLessons();
    final initialLength = lessons.length;
    lessons.removeWhere((lesson) => lesson.id == id);
    
    if (lessons.length != initialLength) {
      // Also delete associated tools
      final tools = await getAllTools();
      tools.removeWhere((tool) => tool.lessonId == id);
      await _saveTools(tools);
      
      return _saveLessons(lessons);
    }
    return false;
  }

  // Embedded tools operations
  Future<List<EmbeddedTool>> getAllTools() async {
    final prefs = await _prefs;
    final String? toolsJson = prefs.getString(_toolsKey);
    
    if (toolsJson == null) return [];
    
    try {
      final List<dynamic> toolsList = json.decode(toolsJson);
      return toolsList.map((json) => EmbeddedTool.fromJson(json)).toList();
    } catch (e) {
      // If JSON parsing fails, clear corrupted data and return empty list
      await prefs.remove(_toolsKey);
      return [];
    }
  }

  Future<List<EmbeddedTool>> getToolsForLesson(String lessonId) async {
    final tools = await getAllTools();
    return tools.where((tool) => tool.lessonId == lessonId).toList();
  }

  Future<bool> insertTool(EmbeddedTool tool) async {
    final tools = await getAllTools();
    tools.add(tool);
    return _saveTools(tools);
  }

  Future<bool> updateTool(EmbeddedTool updatedTool) async {
    final tools = await getAllTools();
    final index = tools.indexWhere((t) => t.id == updatedTool.id);
    
    if (index != -1) {
      tools[index] = updatedTool;
      return _saveTools(tools);
    }
    return false;
  }

  Future<bool> deleteTool(String id) async {
    final tools = await getAllTools();
    final initialLength = tools.length;
    tools.removeWhere((tool) => tool.id == id);
    
    if (tools.length != initialLength) {
      return _saveTools(tools);
    }
    return false;
  }

  // Search operations
  Future<List<Lesson>> searchLessons(String query) async {
    final lessons = await getAllLessons();
    final lowercaseQuery = query.toLowerCase();
    
    return lessons.where((lesson) =>
        lesson.title.toLowerCase().contains(lowercaseQuery) ||
        lesson.content.toLowerCase().contains(lowercaseQuery)).toList();
  }

  Future<List<Subject>> searchSubjects(String query) async {
    final subjects = await getAllSubjects();
    final lowercaseQuery = query.toLowerCase();
    
    return subjects.where((subject) =>
        subject.title.toLowerCase().contains(lowercaseQuery) ||
        (subject.description?.toLowerCase().contains(lowercaseQuery) ?? false)).toList();
  }

  // Private helper methods
  Future<bool> _saveSubjects(List<Subject> subjects) async {
    final prefs = await _prefs;
    final String jsonString = json.encode(subjects.map((s) => s.toJson()).toList());
    return prefs.setString(_subjectsKey, jsonString);
  }

  Future<bool> _saveLessons(List<Lesson> lessons) async {
    final prefs = await _prefs;
    final String jsonString = json.encode(lessons.map((l) => l.toJson()).toList());
    return prefs.setString(_lessonsKey, jsonString);
  }

  Future<bool> _saveTools(List<EmbeddedTool> tools) async {
    final prefs = await _prefs;
    final String jsonString = json.encode(tools.map((t) => t.toJson()).toList());
    return prefs.setString(_toolsKey, jsonString);
  }

  // Export/Import functionality
  Future<Map<String, dynamic>> exportData() async {
    final subjects = await getAllSubjects();
    final lessons = await getAllLessons();
    final tools = await getAllTools();
    
    return {
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'tools': tools.map((t) => t.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      final subjects = (data['subjects'] as List<dynamic>)
          .map((json) => Subject.fromJson(json))
          .toList();
      final lessons = (data['lessons'] as List<dynamic>)
          .map((json) => Lesson.fromJson(json))
          .toList();
      final tools = (data['tools'] as List<dynamic>)
          .map((json) => EmbeddedTool.fromJson(json))
          .toList();

      await _saveSubjects(subjects);
      await _saveLessons(lessons);
      await _saveTools(tools);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear all data
  Future<bool> clearAllData() async {
    final prefs = await _prefs;
    await prefs.remove(_subjectsKey);
    await prefs.remove(_lessonsKey);
    await prefs.remove(_toolsKey);
    return true;
  }
}