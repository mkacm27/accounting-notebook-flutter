import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/database.dart';
import 'embeds/amortization_embed.dart';
import 'embeds/custom_table_embed.dart';
import 'embeds/journal_embed.dart';
import 'tools/tool_palette.dart';

class RichTextEditor extends StatefulWidget {
  final String initialContent;
  final AppDatabase database;
  final String lessonId;
  final VoidCallback onContentChanged;
  final Function(String) onSave;

  const RichTextEditor({
    super.key,
    required this.initialContent,
    required this.database,
    required this.lessonId,
    required this.onContentChanged,
    required this.onSave,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    Document document;
    try {
      if (widget.initialContent.isEmpty || widget.initialContent == '[]') {
        document = Document();
      } else {
        document = Document.fromJson(jsonDecode(widget.initialContent));
      }
    } catch (e) {
      document = Document();
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller.addListener(_onContentChanged);
  }

  @override
  void didUpdateWidget(RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent) {
      _controller.removeListener(_onContentChanged);
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    widget.onContentChanged();
  }

  void _showToolPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToolPalette(
        onToolSelected: _insertTool,
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _insertTool(String toolType, Map<String, dynamic> toolData) {
    try {
      final index = _controller.selection.baseOffset;
      _controller.document.insert(index, '\n');
      _controller.document.insert(index + 1, CustomEmbed(toolType, toolData));
      _controller.document.insert(index + 2, '\n');
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 3),
        ChangeSource.local,
      );
      _saveContent();
    } catch (e) {
      // Handle error
    }
  }

  void _saveContent() {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    widget.onSave(content);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ? Corrected Toolbar Widget
        QuillSimpleToolbar(
          configurations: QuillSimpleToolbarConfigurations(
            controller: _controller,
            showFontFamily: false,
            showFontSize: false,
            showSubscript: false,
            showSuperscript: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showSearchButton: false,
            customButtons: [
              QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Insert Tool (Ctrl+K)',
                onPressed: _showToolPalette,
              ),
              QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.save),
                tooltip: 'Save (Ctrl+S)',
                onPressed: _saveContent,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            // ? Corrected Editor Widget
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: false,
              embedBuilders: [],
              placeholder:
                  'Start writing your lesson content...\n\nTip: Use the + button or press Ctrl+K to insert accounting tools.',
            ),
          ),
        ),
      ],
    );
  }
}

class CustomEmbed extends Embeddable {
  final String type;
  final Map<String, dynamic> data;

  const CustomEmbed(this.type, this.data) : super('custom', data);
}