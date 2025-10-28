import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/view/viewScreen.dart';
import 'data/bmi_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only initialize native sqflite DB on non-web platforms.
  if (!kIsWeb) {
    try {
      await BMIDatabase.instance.database;
    } catch (e, st) {
      print('main: failed to initialize database -> $e\n$st');
    }
  } else {
    print('main: running on web, using in-memory DB fallback');
  }
  runApp(const BMICalculatorApp());
}

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFF5EE),
        fontFamily: 'Roboto',
      ),
      home: const BMICalculatorView(),
    );
  }
}