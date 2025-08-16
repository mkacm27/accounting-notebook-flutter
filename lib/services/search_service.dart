import 'dart:convert';
import '../models/database.dart';
import '../models/content_models.dart';

class SearchResult {
  final String id;
  final String title;
  final String type; // 'subject' or 'lesson'
  final String? subjectId;
  final String? subjectTitle;
  final String snippet;
  final List<String> tags;
  final DateTime updatedAt;

  SearchResult({
    required this.id,
    required this.title,
    required this.type,
    this.subjectId,
    this.subjectTitle,
    required this.snippet,
    required this.tags,
    required this.updatedAt,
  });
}

class SearchService {
  /// Search across subjects and lessons
  Future<List<SearchResult>> search(
    AppDatabase database,
    String query, {
    List<String>? tagFilters,
    String? subjectFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    if (query.trim().isEmpty && 
        (tagFilters == null || tagFilters.isEmpty) &&
        subjectFilter == null &&
        dateFrom == null &&
        dateTo == null) {
      return [];
    }

    List<SearchResult> results = [];
    
    // Search subjects
    final subjects = await _searchSubjects(database, query, tagFilters, dateFrom, dateTo);
    results.addAll(subjects);
    
    // Search lessons
    final lessons = await _searchLessons(database, query, tagFilters, subjectFilter, dateFrom, dateTo);
    results.addAll(lessons);
    
    // Sort by relevance (title matches first, then by date)
    results.sort((a, b) {
      final aTitle = a.title.toLowerCase().contains(query.toLowerCase());
      final bTitle = b.title.toLowerCase().contains(query.toLowerCase());
      
      if (aTitle && !bTitle) return -1;
      if (!aTitle && bTitle) return 1;
      
      return b.updatedAt.compareTo(a.updatedAt);
    });
    
    return results;
  }

  /// Search subjects
  Future<List<SearchResult>> _searchSubjects(
    AppDatabase database,
    String query,
    List<String>? tagFilters,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    List<Subject> subjects;
    
    if (query.trim().isNotEmpty) {
      subjects = await database.searchSubjects(query);
    } else {
      subjects = await database.getAllSubjects();
    }
    
    List<SearchResult> results = [];
    
    for (final subject in subjects) {
      // Apply tag filter
      if (tagFilters != null && tagFilters.isNotEmpty) {
        final hasMatchingTag = subject.tags.any((tag) => 
            tagFilters.any((filter) => tag.toLowerCase().contains(filter.toLowerCase())));
        if (!hasMatchingTag) continue;
      }
      
      // Apply date filter
      if (dateFrom != null && subject.updatedAt.isBefore(dateFrom)) continue;
      if (dateTo != null && subject.updatedAt.isAfter(dateTo.add(const Duration(days: 1)))) continue;
      
      // Create snippet
      String snippet = subject.description ?? '';
      if (snippet.isEmpty) {
        snippet = 'Subject with ${subject.tags.length} tags';
      }
      if (snippet.length > 100) {
        snippet = '${snippet.substring(0, 97)}...';
      }
      
      results.add(SearchResult(
        id: subject.id,
        title: subject.title,
        type: 'subject',
        snippet: snippet,
        tags: subject.tags,
        updatedAt: subject.updatedAt,
      ));
    }
    
    return results;
  }

  /// Search lessons
  Future<List<SearchResult>> _searchLessons(
    AppDatabase database,
    String query,
    List<String>? tagFilters,
    String? subjectFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    List<Lesson> lessons;
    
    if (query.trim().isNotEmpty) {
      lessons = await database.searchLessons(query);
    } else {
      // Get all lessons across all subjects
      final subjects = await database.getAllSubjects();
      lessons = [];
      for (final subject in subjects) {
        final subjectLessons = await database.getLessonsForSubject(subject.id);
        lessons.addAll(subjectLessons);
      }
    }
    
    List<SearchResult> results = [];
    
    for (final lesson in lessons) {
      // Apply subject filter
      if (subjectFilter != null && lesson.subjectId != subjectFilter) continue;
      
      // Apply tag filter
      if (tagFilters != null && tagFilters.isNotEmpty) {
        final hasMatchingTag = lesson.tags.any((tag) => 
            tagFilters.any((filter) => tag.toLowerCase().contains(filter.toLowerCase())));
        if (!hasMatchingTag) continue;
      }
      
      // Apply date filter
      if (dateFrom != null && lesson.updatedAt.isBefore(dateFrom)) continue;
      if (dateTo != null && lesson.updatedAt.isAfter(dateTo.add(const Duration(days: 1)))) continue;
      
      // Get subject info
      Subject? subject;
      try {
        subject = await database.getSubject(lesson.subjectId);
      } catch (e) {
        // Subject might not exist
      }
      
      // Create snippet from content
      String snippet = await _extractContentSnippet(lesson.content, query);
      
      results.add(SearchResult(
        id: lesson.id,
        title: lesson.title,
        type: 'lesson',
        subjectId: lesson.subjectId,
        subjectTitle: subject?.title,
        snippet: snippet,
        tags: lesson.tags,
        updatedAt: lesson.updatedAt,
      ));
    }
    
    return results;
  }

  /// Extract snippet from lesson content
  Future<String> _extractContentSnippet(String content, String query) async {
    try {
      final delta = jsonDecode(content);
      final text = _extractTextFromDelta(delta);
      
      if (query.trim().isEmpty) {
        return text.length > 100 ? '${text.substring(0, 97)}...' : text;
      }
      
      // Find query in text and create snippet around it
      final lowerText = text.toLowerCase();
      final lowerQuery = query.toLowerCase();
      final index = lowerText.indexOf(lowerQuery);
      
      if (index >= 0) {
        final start = (index - 50).clamp(0, text.length);
        final end = (index + query.length + 50).clamp(0, text.length);
        String snippet = text.substring(start, end);
        
        if (start > 0) snippet = '...$snippet';
        if (end < text.length) snippet = '$snippet...';
        
        return snippet;
      }
      
      return text.length > 100 ? '${text.substring(0, 97)}...' : text;
    } catch (e) {
      return 'Content parsing error';
    }
  }

  /// Extract plain text from Quill Delta
  String _extractTextFromDelta(Map<String, dynamic> delta) {
    final StringBuffer buffer = StringBuffer();
    
    if (delta['ops'] is List) {
      final ops = delta['ops'] as List;
      
      for (final op in ops) {
        if (op is Map<String, dynamic> && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          } else if (insert is Map && insert.containsKey('custom')) {
            // Handle embedded tools
            final toolData = insert['custom'] as Map<String, dynamic>;
            buffer.write('[${toolData['type'] ?? 'Tool'}] ');
          }
        }
      }
    }
    
    return buffer.toString().trim();
  }

  /// Get all unique tags across subjects and lessons
  Future<List<String>> getAllTags(AppDatabase database) async {
    final Set<String> allTags = <String>{};
    
    // Get tags from subjects
    final subjects = await database.getAllSubjects();
    for (final subject in subjects) {
      allTags.addAll(subject.tags);
      
      // Get tags from lessons in this subject
      final lessons = await database.getLessonsForSubject(subject.id);
      for (final lesson in lessons) {
        allTags.addAll(lesson.tags);
      }
    }
    
    final tagList = allTags.toList()..sort();
    return tagList;
  }

  /// Get search suggestions based on partial query
  Future<List<String>> getSearchSuggestions(AppDatabase database, String partialQuery) async {
    if (partialQuery.trim().length < 2) return [];
    
    final Set<String> suggestions = <String>{};
    final lowerQuery = partialQuery.toLowerCase();
    
    // Get suggestions from subject titles
    final subjects = await database.getAllSubjects();
    for (final subject in subjects) {
      if (subject.title.toLowerCase().contains(lowerQuery)) {
        suggestions.add(subject.title);
      }
    }
    
    // Get suggestions from lesson titles
    for (final subject in subjects) {
      final lessons = await database.getLessonsForSubject(subject.id);
      for (final lesson in lessons) {
        if (lesson.title.toLowerCase().contains(lowerQuery)) {
          suggestions.add(lesson.title);
        }
      }
    }
    
    // Get suggestions from tags
    final tags = await getAllTags(database);
    for (final tag in tags) {
      if (tag.toLowerCase().contains(lowerQuery)) {
        suggestions.add('#$tag');
      }
    }
    
    return suggestions.take(10).toList();
  }

  /// Search within a specific lesson's content
  Future<List<String>> searchInLesson(String content, String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final delta = jsonDecode(content);
      final text = _extractTextFromDelta(delta);
      final lines = text.split('\n');
      
      final List<String> matches = [];
      final lowerQuery = query.toLowerCase();
      
      for (final line in lines) {
        if (line.toLowerCase().contains(lowerQuery)) {
          matches.add(line.trim());
        }
      }
      
      return matches;
    } catch (e) {
      return [];
    }
  }
}
