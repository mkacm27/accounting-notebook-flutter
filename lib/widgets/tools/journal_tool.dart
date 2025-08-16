import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/content_models.dart';

class JournalTool extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const JournalTool({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<JournalTool> createState() => _JournalToolState();
}

class _JournalToolState extends State<JournalTool> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _accountDebitController = TextEditingController();
  final _accountCreditController = TextEditingController();
  final _debitAmountController = TextEditingController();
  final _creditAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  // Common account suggestions
  final List<String> _commonAccounts = [
    'Cash',
    'Accounts Receivable',
    'Inventory',
    'Equipment',
    'Accounts Payable',
    'Notes Payable',
    'Common Stock',
    'Retained Earnings',
    'Sales Revenue',
    'Cost of Goods Sold',
    'Salaries Expense',
    'Rent Expense',
    'Utilities Expense',
    'Depreciation Expense',
    'Interest Expense',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _selectedDate = DateTime.parse(data['date'] ?? DateTime.now().toIso8601String());
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _accountDebitController.text = data['accountDebit'] ?? '';
      _accountCreditController.text = data['accountCredit'] ?? '';
      _debitAmountController.text = data['debitAmount']?.toString() ?? '';
      _creditAmountController.text = data['creditAmount']?.toString() ?? '';
      _descriptionController.text = data['description'] ?? '';
      _tagsController.text = (data['tags'] as List<dynamic>?)?.join(', ') ?? '';
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _accountDebitController.dispose();
    _accountCreditController.dispose();
    _debitAmountController.dispose();
    _creditAmountController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final debitAmount = double.tryParse(_debitAmountController.text) ?? 0.0;
    final creditAmount = double.tryParse(_creditAmountController.text) ?? 0.0;

    if (debitAmount != creditAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debit and credit amounts must be equal'),
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

    final journalData = {
      'id': widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'date': _selectedDate.toIso8601String(),
      'accountDebit': _accountDebitController.text,
      'accountCredit': _accountCreditController.text,
      'debitAmount': debitAmount,
      'creditAmount': creditAmount,
      'description': _descriptionController.text,
      'tags': tags,
    };

    widget.onSave(journalData);
  }

  Widget _buildAccountField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _commonAccounts;
        }
        return _commonAccounts.where((account) =>
            account.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.text = controller.text;
        textController.addListener(() {
          controller.text = textController.text;
        });
        
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter $label';
            }
            return null;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journal Entry',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Date
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectDate,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Debit Account
                      _buildAccountField(
                        controller: _accountDebitController,
                        label: 'Debit Account',
                        hint: 'Account to be debited',
                      ),
                      const SizedBox(height: 16),
                      
                      // Credit Account
                      _buildAccountField(
                        controller: _accountCreditController,
                        label: 'Credit Account',
                        hint: 'Account to be credited',
                      ),
                      const SizedBox(height: 16),
                      
                      // Amounts
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _debitAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Debit Amount',
                                prefixText: '\$',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                final amount = double.tryParse(value!);
                                if (amount == null || amount <= 0) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // Auto-fill credit amount
                                _creditAmountController.text = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _creditAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Credit Amount',
                                prefixText: '\$',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                final amount = double.tryParse(value!);
                                if (amount == null || amount <= 0) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the transaction',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Tags
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (optional)',
                          hintText: 'Enter tags separated by commas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
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
                  child: const Text('Save Entry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
