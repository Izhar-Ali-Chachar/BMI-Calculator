import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../model/BmiModel.dart';
import '../data/bmi_database.dart';
import '../model/BmiRecord.dart';

class BMIViewModel extends ChangeNotifier {
  final BMIModel _model = BMIModel();

  String get gender => _model.gender;
  double? get height => _model.height;
  double? get weight => _model.weight;
  double? _bmi;
  String? _category;

  double? get bmi => _bmi;
  String? get category => _category;

  Color? get categoryColor =>
      _category != null ? _model.getCategoryColor(_category!) : null;

  List<BMIRecord> _history = [];
  List<BMIRecord> get history => _history;

  BMIViewModel() {
    // Initialize reasonable defaults so BMI is available immediately
    _model.height ??= 170;
    _model.weight ??= 70;
    _calculateBMI();
    loadHistory();
  }

  void setGender(String value) {
    _model.gender = value;
    notifyListeners();
  }

  void setHeight(double value) {
    _model.height = value;
    _calculateBMI();
  }

  void setWeight(double value) {
    _model.weight = value;
    _calculateBMI();
  }

  void _calculateBMI() {
    _bmi = _model.calculateBMI();
    if (_bmi != null) {
      _category = _model.getBMICategory(_bmi!);
    } else {
      _category = null;
    }
    notifyListeners();
  }

  // return true if saved successfully; on error rethrow so caller can show details
  Future<bool> saveRecord() async {
    if (_bmi == null) return false;
    final record = BMIRecord(
      bmi: _bmi!,
      category: _category ?? '',
      height: _model.height ?? 0,
      weight: _model.weight ?? 0,
      gender: _model.gender,
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await BMIDatabase.instance.insertRecord(record);
      await loadHistory();
      return true;
    } catch (e, st) {
      // log and rethrow for the UI to display an informative message
      print('BmiViewModel: saveRecord failed -> $e\n$st');
      rethrow;
    }
  }

  Future<void> loadHistory() async {
    try {
      _history = await BMIDatabase.instance.getRecords();
    } catch (e) {
      _history = [];
    }
    notifyListeners();
  }

  void reset() {
    _model.height = 170;
    _model.weight = 70;
    _model.gender = 'male';
    _calculateBMI();
    notifyListeners();
  }
}
