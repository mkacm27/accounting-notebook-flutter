import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/database.dart';
import '../models/content_models.dart';

class ExportService {
  /// Export all data to JSON format
  Future<void> exportToJson(AppDatabase database, {bool includeAttachments = false}) async {
    try {
      final exportData = await _generateExportData(database, includeAttachments);
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // For web, we'll use file picker to save
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'accounting_notebook_export_$timestamp.json';
      
      // Save using file picker (web compatible)
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save export file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
      }
      
      // Optionally trigger file picker to save to user-chosen location
      // This would require platform-specific implementation
      
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Import data from JSON file
  Future<void> importFromJson(AppDatabase database) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> importData = jsonDecode(jsonString);

      // Validate JSON structure
      if (!_isValidExportFormat(importData)) {
        throw Exception('Invalid export file format');
      }

      // Clear existing data (with user confirmation in UI)
      await _clearExistingData(database);

      // Import subjects and lessons
      await _importData(database, importData);

    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  /// Generate export data structure
  Future<Map<String, dynamic>> _generateExportData(AppDatabase database, bool includeAttachments) async {
    final subjects = await database.getAllSubjects();
    List<Map<String, dynamic>> subjectData = [];

    for (final subject in subjects) {
      final lessons = await database.getLessonsForSubject(subject.id);
      List<Map<String, dynamic>> lessonData = [];

      for (final lesson in lessons) {
        final tools = await database.getToolsForLesson(lesson.id);
        
        // Parse content blocks from Quill Delta
        List<Map<String, dynamic>> contentBlocks = [];
        try {
          final delta = jsonDecode(lesson.content);
          contentBlocks = _parseContentBlocks(delta, tools);
        } catch (e) {
          // If parsing fails, create a simple text block
          contentBlocks = [
            {
              'type': 'paragraph',
              'text': 'Content parsing error: ${e.toString()}',
            }
          ];
        }

        lessonData.add({
          'id': lesson.id,
          'title': lesson.title,
          'tags': lesson.tags,
          'contentBlocks': contentBlocks,
          'createdAt': lesson.createdAt.toIso8601String(),
          'updatedAt': lesson.updatedAt.toIso8601String(),
        });
      }

      subjectData.add({
        'id': subject.id,
        'title': subject.title,
        'description': subject.description,
        'tags': subject.tags,
        'lessons': lessonData,
        'createdAt': subject.createdAt.toIso8601String(),
        'updatedAt': subject.updatedAt.toIso8601String(),
      });
    }

    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'subjects': subjectData,
    };
  }

  /// Parse Quill Delta content into structured blocks
  List<Map<String, dynamic>> _parseContentBlocks(Map<String, dynamic> delta, List<EmbeddedTool> tools) {
    List<Map<String, dynamic>> blocks = [];
    
    if (delta['ops'] is List) {
      final ops = delta['ops'] as List;
      
      for (final op in ops) {
        if (op is Map<String, dynamic>) {
          if (op.containsKey('insert')) {
            final insert = op['insert'];
            
            if (insert is String) {
              // Text content
              final attributes = op['attributes'] as Map<String, dynamic>?;
              
              // Determine block type from attributes
              String blockType = 'paragraph';
              if (attributes != null) {
                if (attributes.containsKey('header')) {
                  blockType = 'heading';
                } else if (attributes.containsKey('list')) {
                  blockType = 'list';
                }
              }
              
              blocks.add({
                'type': blockType,
                'text': insert,
                'attributes': attributes ?? {},
              });
            } else if (insert is Map && insert.containsKey('custom')) {
              // Embedded tool
              final toolData = insert['custom'] as Map<String, dynamic>;
              blocks.add({
                'type': 'embedded_tool',
                'toolType': toolData['type'] ?? 'unknown',
                'data': toolData['data'] ?? {},
              });
            }
          }
        }
      }
    }
    
    return blocks;
  }

  /// Validate export file format
  bool _isValidExportFormat(Map<String, dynamic> data) {
    return data.containsKey('version') &&
           data.containsKey('exported_at') &&
           data.containsKey('subjects') &&
           data['subjects'] is List;
  }

  /// Clear existing data (should be called with user confirmation)
  Future<void> _clearExistingData(AppDatabase database) async {
    // Note: In production, this should have user confirmation
    final subjects = await database.getAllSubjects();
    for (final subject in subjects) {
      final lessons = await database.getLessonsForSubject(subject.id);
      for (final lesson in lessons) {
        // Delete tools first due to foreign key constraints
        final tools = await database.getToolsForLesson(lesson.id);
        for (final tool in tools) {
          await database.deleteTool(tool.id);
        }
        await database.deleteLesson(lesson.id);
      }
      await database.deleteSubject(subject.id);
    }
  }

  /// Import data from parsed JSON
  Future<void> _importData(AppDatabase database, Map<String, dynamic> importData) async {
    final subjects = importData['subjects'] as List;
    
    for (final subjectJson in subjects) {
      final subject = subjectJson as Map<String, dynamic>;
      
      // Insert subject
      final subjectData = Subject(
        id: subject['id'] as String,
        title: subject['title'] as String,
        description: subject['description'] as String?,
        tags: List<String>.from(subject['tags'] ?? []),
        createdAt: DateTime.parse(subject['createdAt'] as String),
        updatedAt: DateTime.parse(subject['updatedAt'] as String),
      );
      
      await database.insertSubject(subjectData);
      
      // Insert lessons
      final lessons = subject['lessons'] as List? ?? [];
      for (final lessonJson in lessons) {
        final lesson = lessonJson as Map<String, dynamic>;
        
        // Convert content blocks back to Quill Delta format
        final contentBlocks = lesson['contentBlocks'] as List? ?? [];
        final deltaOps = _convertBlocksToQuillDelta(contentBlocks);
        final contentJson = jsonEncode({'ops': deltaOps});
        
        final lessonData = Lesson(
          id: lesson['id'] as String,
          subjectId: subject['id'] as String,
          title: lesson['title'] as String,
          tags: List<String>.from(lesson['tags'] ?? []),
          content: contentJson,
          createdAt: DateTime.parse(lesson['createdAt'] as String),
          updatedAt: DateTime.parse(lesson['updatedAt'] as String),
        );
        
        await database.insertLesson(lessonData);
        
        // Insert embedded tools
        for (int i = 0; i < contentBlocks.length; i++) {
          final block = contentBlocks[i] as Map<String, dynamic>;
          if (block['type'] == 'embedded_tool') {
            final toolData = EmbeddedTool(
              id: '${lesson['id']}_tool_$i',
              lessonId: lesson['id'] as String,
              toolType: block['toolType'] as String,
              toolData: jsonEncode(block['data']),
              position: i,
              createdAt: DateTime.now(),
            );
            
            await database.insertTool(toolData);
          }
        }
      }
    }
  }

  /// Convert content blocks back to Quill Delta operations
  List<Map<String, dynamic>> _convertBlocksToQuillDelta(List<dynamic> blocks) {
    List<Map<String, dynamic>> ops = [];
    
    for (final block in blocks) {
      if (block is Map<String, dynamic>) {
        switch (block['type']) {
          case 'paragraph':
            ops.add({
              'insert': block['text'] ?? '',
              'attributes': block['attributes'] ?? {},
            });
            break;
          case 'heading':
            ops.add({
              'insert': block['text'] ?? '',
              'attributes': {
                'header': block['level'] ?? 1,
                ...block['attributes'] as Map<String, dynamic>? ?? {},
              },
            });
            break;
          case 'list':
            ops.add({
              'insert': block['text'] ?? '',
              'attributes': {
                'list': block['listType'] ?? 'bullet',
                ...block['attributes'] as Map<String, dynamic>? ?? {},
              },
            });
            break;
          case 'embedded_tool':
            ops.add({
              'insert': {
                'custom': {
                  'type': block['toolType'],
                  'data': block['data'],
                }
              }
            });
            break;
          default:
            // Default to paragraph
            ops.add({
              'insert': block['text'] ?? '',
            });
        }
        
        // Add newline after each block
        ops.add({'insert': '\n'});
      }
    }
    
    return ops;
  }

  /// Get export file size estimation
  Future<String> getExportSizeEstimate(AppDatabase database) async {
    try {
      final exportData = await _generateExportData(database, false);
      final jsonString = jsonEncode(exportData);
      final bytes = utf8.encode(jsonString).length;
      
      if (bytes < 1024) {
        return '${bytes} B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
