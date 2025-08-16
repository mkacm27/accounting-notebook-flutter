import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../models/database.dart';
import 'tools/tool_palette.dart';
import 'embeds/journal_embed.dart';
import 'embeds/amortization_embed.dart';
import 'embeds/custom_table_embed.dart';

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
  bool _isToolPaletteVisible = false;

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
    setState(() {
      _isToolPaletteVisible = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToolPalette(
        onToolSelected: _insertTool,
        onClose: () {
          setState(() {
            _isToolPaletteVisible = false;
          });
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      setState(() {
        _isToolPaletteVisible = false;
      });
    });
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

      final content = jsonEncode(_controller.document.toDelta().toJson());
      widget.onSave(content);
    } catch (e) {
      print('Error inserting tool: $e');
      final index = _controller.selection.baseOffset;
      _controller.document.insert(index, '\n[$toolType Tool]\n');
    }
  }

  void _saveContent() {
    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());
      widget.onSave(content);
    } catch (e) {
      print('Error saving content: $e');
      final plainText = _controller.document.toPlainText();
      widget.onSave(plainText);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyK &&
          HardwareKeyboard.instance.isControlPressed) {
        _showToolPalette();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS &&
          HardwareKeyboard.instance.isControlPressed) {
        _saveContent();
        return true;
      }
    }
    return false;
  }

  Widget _buildCustomEmbed(CustomEmbed embed) {
    switch (embed.type) {
      case 'journal':
        return JournalEmbed(
          data: embed.data,
          onEdit: (newData) => _insertTool('journal', newData),
        );
      case 'amortization':
        return AmortizationEmbed(
          data: embed.data,
          onEdit: (newData) => _insertTool('amortization', newData),
        );
      case 'customTable':
        return CustomTableEmbed(
          data: embed.data,
          onEdit: (newData) => _insertTool('customTable', newData),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('Unknown embed type: ${embed.type}'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          // Toolbar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              multiRowsDisplay: false,
              showFontFamily: false,
              showFontSize: false,
              showSubscript: false,
              showSuperscript: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showSearchButton: false,
              customButtons: [
                QuillCustomButton(
                  icon: Icons.add_circle_outline,
                  tooltip: 'Insert Tool (Ctrl+K)',
                  onPressed: _showToolPalette,
                ),
                QuillCustomButton(
                  icon: Icons.save,
                  tooltip: 'Save (Ctrl+S)',
                  onPressed: _saveContent,
                ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: ScrollController(),
                scrollable: true,
                autoFocus: false,
                readOnly: false,
                expands: true,
                padding: EdgeInsets.zero,
                placeholder:
                    'Start writing your lesson content...\n\nTip: Use the + button or press Ctrl+K to insert accounting tools.',
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const VerticalSpacing(8, 8),
                    const VerticalSpacing(0, 0),
                    null,
                    null,
                  ),
                ),
                embedBuilders: [],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomEmbed extends Embeddable {
  final String type;
  final Map<String, dynamic> data;

  const CustomEmbed(this.type, this.data) : super('custom', data);
}
