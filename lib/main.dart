import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/accounting_notebook_app.dart';
import 'services/data_recovery_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clear any corrupted data and initialize sample data if needed
  await DataRecoveryService.clearCorruptedData();
  await DataRecoveryService.initializeSampleData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accounting Notebook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        typography: Typography.material2021(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        typography: Typography.material2021(),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      home: const AccountingNotebookApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}
