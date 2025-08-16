import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
  final ScrollController _scrollController = ScrollController();
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
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
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
      final index = _controller.selection.baseOffset.clamp(0, _controller.document.length);

      _controller.document.insert(index, '\n');
      _controller.document.insert(index + 1, CustomEmbed(toolType, toolData));
      _controller.document.insert(index + 2, '\n');

      _controller.updateSelection(
        TextSelection.collapsed(offset: (index + 3).clamp(0, _controller.document.length)),
        ChangeSource.local,
      );

      final content = jsonEncode(_controller.document.toDelta().toJson());
      widget.onSave(content);
    } catch (e) {
      // fallback: insert text description
      final index = _controller.selection.baseOffset.clamp(0, _controller.document.length);
      _controller.document.insert(index, '\n[$toolType Tool]\n');
    }
  }

  void _saveContent() {
    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());
      widget.onSave(content);
    } catch (e) {
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

  // Helper functions to toggle attributes (safe, independent of toolbar API)
  void _toggleBold() {
    final isBold = _controller
            .getSelectionStyle()
            .attributes[Attribute.bold.key] !=
        null;
    _controller.formatSelection(isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
  }

  void _toggleItalic() {
    final isItalic = _controller
            .getSelectionStyle()
            .attributes[Attribute.italic.key] !=
        null;
    _controller.formatSelection(isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          // Simple custom toolbar (uses controller directly; robust to Quill API changes)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 48,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Bold',
                  icon: const Icon(Icons.format_bold),
                  onPressed: _toggleBold,
                ),
                IconButton(
                  tooltip: 'Italic',
                  icon: const Icon(Icons.format_italic),
                  onPressed: _toggleItalic,
                ),
                const VerticalDivider(width: 8),
                IconButton(
                  tooltip: 'Insert Tool (Ctrl+K)',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showToolPalette,
                ),
                IconButton(
                  tooltip: 'Save (Ctrl+S)',
                  icon: const Icon(Icons.save),
                  onPressed: _saveContent,
                ),
                const Spacer(),
                // you can add more small controls here if needed
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
                scrollController: _scrollController,
                scrollBottomInset: 0,
                autoFocus: false,
                expands: true,
                padding: EdgeInsets.zero,
                placeholder:
                    'Start writing your lesson content...\n\nTip: Use the + button or press Ctrl+K to insert accounting tools.',
                embedBuilders: [
                  // If you have custom embed builders you can add them here.
                  // For now we leave empty; the embeds inserted as CustomEmbed may need a custom builder.
                ],
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
