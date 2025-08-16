import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/content_models.dart';

class AmortizationTool extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const AmortizationTool({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<AmortizationTool> createState() => _AmortizationToolState();
}

class _AmortizationToolState extends State<AmortizationTool> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _assetValueController = TextEditingController();
  final _usefulLifeController = TextEditingController();
  final _salvageValueController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  String _selectedMethod = 'straight-line';
  String _selectedPeriodicity = 'annual';
  List<AmortizationPeriod> _schedule = [];

  final List<String> _methods = ['straight-line', 'declining-balance'];
  final List<String> _periodicities = ['annual', 'monthly'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _assetNameController.text = data['assetName'] ?? '';
      _purchaseDate = DateTime.parse(data['purchaseDate'] ?? DateTime.now().toIso8601String());
      _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(_purchaseDate);
      _assetValueController.text = data['assetValue']?.toString() ?? '';
      _usefulLifeController.text = data['usefulLifeYears']?.toString() ?? '';
      _selectedMethod = data['method'] ?? 'straight-line';
      _salvageValueController.text = data['salvageValue']?.toString() ?? '0';
      _selectedPeriodicity = data['periodicity'] ?? 'annual';
      _tagsController.text = (data['tags'] as List<dynamic>?)?.join(', ') ?? '';
      
      if (data['schedule'] != null) {
        _schedule = (data['schedule'] as List)
            .map((p) => AmortizationPeriod.fromJson(p))
            .toList();
      }
    } else {
      _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(_purchaseDate);
      _salvageValueController.text = '0';
    }
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _purchaseDateController.dispose();
    _assetValueController.dispose();
    _usefulLifeController.dispose();
    _salvageValueController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _purchaseDate = date;
        _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  void _calculateSchedule() {
    if (!_formKey.currentState!.validate()) return;

    final assetValue = double.parse(_assetValueController.text);
    final usefulLife = int.parse(_usefulLifeController.text);
    final salvageValue = double.parse(_salvageValueController.text);

    if (assetValue <= salvageValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset value must be greater than salvage value'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<AmortizationPeriod> schedule = [];
    
    if (_selectedMethod == 'straight-line') {
      schedule = _calculateStraightLineSchedule(assetValue, usefulLife, salvageValue);
    } else {
      schedule = _calculateDecliningBalanceSchedule(assetValue, usefulLife, salvageValue);
    }

    setState(() {
      _schedule = schedule;
    });
  }

  List<AmortizationPeriod> _calculateStraightLineSchedule(
    double assetValue, 
    int usefulLife, 
    double salvageValue
  ) {
    final depreciableAmount = assetValue - salvageValue;
    final periodsPerYear = _selectedPeriodicity == 'monthly' ? 12 : 1;
    final totalPeriods = usefulLife * periodsPerYear;
    final periodExpense = depreciableAmount / totalPeriods;
    
    List<AmortizationPeriod> schedule = [];
    double accumulated = 0;
    
    for (int i = 1; i <= totalPeriods; i++) {
      accumulated += periodExpense;
      final year = _selectedPeriodicity == 'monthly' 
          ? ((i - 1) ~/ 12) + 1
          : i;
      final month = _selectedPeriodicity == 'monthly' 
          ? ((i - 1) % 12) + 1
          : null;
      
      final period = _selectedPeriodicity == 'monthly'
          ? '${_purchaseDate.year + year - 1}-${month.toString().padLeft(2, '0')}'
          : '${_purchaseDate.year + year - 1}';
      
      schedule.add(AmortizationPeriod(
        period: period,
        expense: periodExpense,
        accumulated: accumulated,
      ));
    }
    
    return schedule;
  }

  List<AmortizationPeriod> _calculateDecliningBalanceSchedule(
    double assetValue, 
    int usefulLife, 
    double salvageValue
  ) {
    final rate = 2.0 / usefulLife; // Double declining balance
    final periodsPerYear = _selectedPeriodicity == 'monthly' ? 12 : 1;
    final totalPeriods = usefulLife * periodsPerYear;
    final periodRate = rate / periodsPerYear;
    
    List<AmortizationPeriod> schedule = [];
    double bookValue = assetValue;
    double accumulated = 0;
    
    for (int i = 1; i <= totalPeriods; i++) {
      double expense = bookValue * periodRate;
      
      // Don't depreciate below salvage value
      if (accumulated + expense > assetValue - salvageValue) {
        expense = (assetValue - salvageValue) - accumulated;
      }
      
      accumulated += expense;
      bookValue -= expense;
      
      final year = _selectedPeriodicity == 'monthly' 
          ? ((i - 1) ~/ 12) + 1
          : i;
      final month = _selectedPeriodicity == 'monthly' 
          ? ((i - 1) % 12) + 1
          : null;
      
      final period = _selectedPeriodicity == 'monthly'
          ? '${_purchaseDate.year + year - 1}-${month.toString().padLeft(2, '0')}'
          : '${_purchaseDate.year + year - 1}';
      
      schedule.add(AmortizationPeriod(
        period: period,
        expense: expense,
        accumulated: accumulated,
      ));
      
      if (bookValue <= salvageValue) break;
    }
    
    return schedule;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate the schedule first'),
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

    final amortizationData = {
      'id': widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'assetName': _assetNameController.text,
      'purchaseDate': _purchaseDate.toIso8601String(),
      'assetValue': double.parse(_assetValueController.text),
      'usefulLifeYears': int.parse(_usefulLifeController.text),
      'method': _selectedMethod,
      'salvageValue': double.parse(_salvageValueController.text),
      'periodicity': _selectedPeriodicity,
      'tags': tags,
      'schedule': _schedule.map((p) => p.toJson()).toList(),
    };

    widget.onSave(amortizationData);
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
                  'Amortization Schedule',
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
              child: Row(
                children: [
                  // Form
                  Expanded(
                    flex: 1,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _assetNameController,
                              decoration: const InputDecoration(
                                labelText: 'Asset Name',
                                hintText: 'e.g., Equipment, Vehicle',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter asset name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _purchaseDateController,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: _selectPurchaseDate,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please select purchase date';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _assetValueController,
                              decoration: const InputDecoration(
                                labelText: 'Asset Value',
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
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _usefulLifeController,
                              decoration: const InputDecoration(
                                labelText: 'Useful Life (Years)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                final years = int.tryParse(value!);
                                if (years == null || years <= 0) {
                                  return 'Invalid years';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            DropdownButtonFormField<String>(
                              value: _selectedMethod,
                              decoration: const InputDecoration(
                                labelText: 'Depreciation Method',
                                border: OutlineInputBorder(),
                              ),
                              items: _methods.map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method.replaceAll('-', ' ').toUpperCase()),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMethod = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _salvageValueController,
                              decoration: const InputDecoration(
                                labelText: 'Salvage Value',
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
                                if (amount == null || amount < 0) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            DropdownButtonFormField<String>(
                              value: _selectedPeriodicity,
                              decoration: const InputDecoration(
                                labelText: 'Periodicity',
                                border: OutlineInputBorder(),
                              ),
                              items: _periodicities.map((period) => DropdownMenuItem(
                                value: period,
                                child: Text(period.toUpperCase()),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeriodicity = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Tags (optional)',
                                hintText: 'Enter tags separated by commas',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            ElevatedButton(
                              onPressed: _calculateSchedule,
                              child: const Text('Calculate Schedule'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Schedule preview
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Depreciation Schedule',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _schedule.isEmpty
                              ? Center(
                                  child: Text(
                                    'Calculate schedule to preview',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Table(
                                    border: TableBorder.all(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    ),
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                        ),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text('Accumulated', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      ..._schedule.map((period) => TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(period.period),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text('\$${period.expense.toStringAsFixed(2)}'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text('\$${period.accumulated.toStringAsFixed(2)}'),
                                          ),
                                        ],
                                      )).toList(),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  child: const Text('Save Schedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
