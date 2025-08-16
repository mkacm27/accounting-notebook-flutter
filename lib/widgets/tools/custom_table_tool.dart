import 'package:flutter/material.dart';
import '../../models/content_models.dart';

class CustomTableTool extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const CustomTableTool({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<CustomTableTool> createState() => _CustomTableToolState();
}

class _CustomTableToolState extends State<CustomTableTool> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  
  List<TableColumn> _columns = [];
  List<List<dynamic>> _rows = [];
  final List<String> _columnTypes = ['text', 'number', 'date', 'currency'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _nameController.text = data['name'] ?? '';
      _tagsController.text = (data['tags'] as List<dynamic>?)?.join(', ') ?? '';
      
      if (data['columns'] != null) {
        _columns = (data['columns'] as List)
            .map((c) => TableColumn.fromJson(c))
            .toList();
      }
      
      if (data['rows'] != null) {
        _rows = (data['rows'] as List)
            .map((r) => List<dynamic>.from(r))
            .toList();
      }
    }
    
    // Ensure at least one column
    if (_columns.isEmpty) {
      _addColumn();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addColumn() {
    setState(() {
      _columns.add(TableColumn(name: 'Column ${_columns.length + 1}', type: 'text'));
      // Add empty cell to all existing rows
      for (var row in _rows) {
        row.add('');
      }
    });
  }

  void _removeColumn(int index) {
    if (_columns.length <= 1) return;
    
    setState(() {
      _columns.removeAt(index);
      // Remove cell from all rows
      for (var row in _rows) {
        if (row.length > index) {
          row.removeAt(index);
        }
      }
    });
  }

  void _addRow() {
    setState(() {
      _rows.add(List.filled(_columns.length, ''));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
  }

  void _updateColumnName(int index, String name) {
    setState(() {
      _columns[index] = TableColumn(name: name, type: _columns[index].type);
    });
  }

  void _updateColumnType(int index, String type) {
    setState(() {
      _columns[index] = TableColumn(name: _columns[index].name, type: type);
    });
  }

  void _updateCellValue(int rowIndex, int colIndex, dynamic value) {
    setState(() {
      _rows[rowIndex][colIndex] = value;
    });
  }

  Widget _buildCellEditor(int rowIndex, int colIndex) {
    final column = _columns[colIndex];
    final currentValue = _rows[rowIndex][colIndex];

    switch (column.type) {
      case 'number':
      case 'currency':
        return TextFormField(
          initialValue: currentValue.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixText: column.type == 'currency' ? '\$' : null,
          ),
          onChanged: (value) {
            final numValue = double.tryParse(value) ?? 0.0;
            _updateCellValue(rowIndex, colIndex, numValue);
          },
        );
      case 'date':
        return TextFormField(
          initialValue: currentValue.toString(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today, size: 16),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _updateCellValue(rowIndex, colIndex, date.toIso8601String().split('T')[0]);
            }
          },
        );
      default:
        return TextFormField(
          initialValue: currentValue.toString(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _updateCellValue(rowIndex, colIndex, value);
          },
        );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one column'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final tableData = {
      'id': widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text,
      'columns': _columns.map((c) => c.toJson()).toList(),
      'rows': _rows,
      'tags': tags,
    };

    widget.onSave(tableData);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Table',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Table metadata
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Table Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter table name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (optional)',
                        hintText: 'Enter tags separated by commas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Column configuration
            Text(
              'Columns',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _columns.length + 1,
                itemBuilder: (context, index) {
                  if (index == _columns.length) {
                    // Add column button
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      child: Card(
                        child: InkWell(
                          onTap: _addColumn,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 32),
                              Text('Add Column'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final column = _columns[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: column.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                    ),
                                    onChanged: (value) => _updateColumnName(index, value),
                                  ),
                                ),
                                if (_columns.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16),
                                    onPressed: () => _removeColumn(index),
                                  ),
                              ],
                            ),
                            DropdownButtonFormField<String>(
                              value: column.type,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                              ),
                              items: _columnTypes.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toUpperCase()),
                              )).toList(),
                              onChanged: (value) => _updateColumnType(index, value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Table data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      children: [
                        ..._columns.map((column) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            column.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )).toList(),
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Actions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    ..._rows.asMap().entries.map((entry) {
                      final rowIndex = entry.key;
                      final row = entry.value;
                      
                      return TableRow(
                        children: [
                          ...row.asMap().entries.map((cellEntry) {
                            final colIndex = cellEntry.key;
                            return Padding(
                              padding: const EdgeInsets.all(4),
                              child: _buildCellEditor(rowIndex, colIndex),
                            );
                          }).toList(),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeRow(rowIndex),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Table'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
