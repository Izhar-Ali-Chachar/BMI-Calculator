import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../viewmodel/BmiViewModel.dart';
import 'historyScreen.dart';
import '../data/bmi_database.dart';
import '../model/BmiRecord.dart';

import 'package:fluttertoast/fluttertoast.dart';

class BMICalculatorView extends StatefulWidget {
  const BMICalculatorView({Key? key}) : super(key: key);

  @override
  State<BMICalculatorView> createState() => _BMICalculatorViewState();
}

class _BMICalculatorViewState extends State<BMICalculatorView> {
  final BMIViewModel _viewModel = BMIViewModel();

  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  static const double minHeight = 100;
  static const double maxHeight = 250;
  static const double minWeight = 30;
  static const double maxWeight = 200;

  bool _heightListenerActive = true;
  bool _weightListenerActive = true;

  // new: unit state (height: cm, m, ft) (weight: kg, lb)
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  // helper: convert displayed unit -> model (cm/kg)
  double _heightToCm(double value, String unit) {
    switch (unit) {
      case 'm':
        return value * 100.0;
      case 'ft':
        return value * 30.48; // 1 ft = 30.48 cm
      case 'cm':
      default:
        return value;
    }
  }

  double _cmToUnit(double cm, String unit) {
    switch (unit) {
      case 'm':
        return cm / 100.0;
      case 'ft':
        return cm / 30.48;
      case 'cm':
      default:
        return cm;
    }
  }

  double _weightToKg(double value, String unit) {
    switch (unit) {
      case 'lb':
        return value * 0.45359237;
      case 'kg':
      default:
        return value;
    }
  }

  double _kgToUnit(double kg, String unit) {
    switch (unit) {
      case 'lb':
        return kg / 0.45359237;
      case 'kg':
      default:
        return kg;
    }
  }

  String _formatDisplay(double value, String unit) {
    // show integers for cm/kg; one decimal for m/ft/lb
    if (unit == 'cm' || unit == 'kg') {
      return value.round().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }

  @override
  void initState() {
    super.initState();
    // initialize controllers with converted display values
    final initialHeightDisplay = _formatDisplay(_cmToUnit(_viewModel.height ?? 170, _heightUnit), _heightUnit);
    final initialWeightDisplay = _formatDisplay(_kgToUnit(_viewModel.weight ?? 70, _weightUnit), _weightUnit);

    _heightController = TextEditingController(text: initialHeightDisplay);
    _weightController = TextEditingController(text: initialWeightDisplay);

    _heightController.addListener(() {
      if (!_heightListenerActive) return;
      final txt = _heightController.text;
      final parsed = double.tryParse(txt);
      if (parsed == null) return;
      double value = parsed;
      // clamp in model-space: convert displayed value -> cm then clamp
      double cm = _heightToCm(value, _heightUnit);
      if (cm < minHeight) cm = minHeight;
      if (cm > maxHeight) cm = maxHeight;
      // convert back to displayed unit for consistent text (avoid weird rounding)
      final displayVal = _cmToUnit(cm, _heightUnit);
      if ((_viewModel.height ?? 0) != cm) {
        _heightListenerActive = false;
        _heightController.text = _formatDisplay(displayVal, _heightUnit);
        _heightController.selection = TextSelection.fromPosition(TextPosition(offset: _heightController.text.length));
        _viewModel.setHeight(cm);
        _heightListenerActive = true;
      }
    });

    _weightController.addListener(() {
      if (!_weightListenerActive) return;
      final txt = _weightController.text;
      final parsed = double.tryParse(txt);
      if (parsed == null) return;
      double value = parsed;
      // clamp in model-space
      double kg = _weightToKg(value, _weightUnit);
      if (kg < minWeight) kg = minWeight;
      if (kg > maxWeight) kg = maxWeight;
      final displayVal = _kgToUnit(kg, _weightUnit);
      if ((_viewModel.weight ?? 0) != kg) {
        _weightListenerActive = false;
        _weightController.text = _formatDisplay(displayVal, _weightUnit);
        _weightController.selection = TextSelection.fromPosition(TextPosition(offset: _weightController.text.length));
        _viewModel.setWeight(kg);
        _weightListenerActive = true;
      }
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool _canSave() {
    final h = _viewModel.height;
    final w = _viewModel.weight;
    return _viewModel.bmi != null
        && h != null && w != null
        && h >= minHeight && h <= maxHeight
        && w >= minWeight && w <= maxWeight;
  }

  Future<void> _onSavePressed() async {
    if (!_canSave()) {
      Fluttertoast.showToast(msg: 'Invalid input, cannot save', gravity: ToastGravity.BOTTOM);
      return;
    }
    try {
      await _viewModel.saveRecord();
      Fluttertoast.showToast(msg: 'Saved', gravity: ToastGravity.BOTTOM);
    } catch (e, st) {
      // show the error to the user and also keep logs visible
      print('View: save failed -> $e\n$st');
      Fluttertoast.showToast(msg: 'Failed to save: ${e.toString()}', gravity: ToastGravity.BOTTOM, toastLength: Toast.LENGTH_LONG);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final padding = isTablet ? 40.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 600 : 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isTablet),
                        SizedBox(height: isTablet ? 40 : 30),
                        _buildGenderSelector(isTablet),
                        SizedBox(height: isTablet ? 30 : 20),
                        _buildHeightSlider(isTablet),
                        SizedBox(height: isTablet ? 30 : 20),
                        _buildWeightSlider(isTablet),
                        SizedBox(height: isTablet ? 40 : 30),
                        if (_viewModel.bmi != null)
                          _buildResultCard(isTablet),
                        SizedBox(height: isTablet ? 20 : 15),
                        _buildResetButton(isTablet),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: Colors.white,
                  size: isTablet ? 40 : 32,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  'BMI Calculator',
                  style: TextStyle(
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.history, color: const Color(0xFFFF6B35)),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              List<BMIRecord> records = [];
              try {
                records = await BMIDatabase.instance.getRecords();
              } catch (e) {
                // ignore; HistoryScreen will fetch again if needed
              }
              Navigator.of(context).pop(); // remove loader
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HistoryScreen(initialRecords: records)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF6B35),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('male', Icons.male, isTablet),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildGenderButton('female', Icons.female, isTablet),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String gender, IconData icon, bool isTablet) {
    final isSelected = _viewModel.gender == gender;
    return GestureDetector(
      onTap: () => _viewModel.setGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isTablet ? 48 : 40,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Text(
              gender.toUpperCase(),
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightSlider(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Height',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF6B35),
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // unit dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: _heightUnit,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'cm', child: Text('cm')),
                    DropdownMenuItem(value: 'm', child: Text('m')),
                    DropdownMenuItem(value: 'ft', child: Text('ft')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      // convert current displayed value to model, then reformat display in new unit
                      final parsed = double.tryParse(_heightController.text) ?? _cmToUnit(_viewModel.height ?? 170, _heightUnit);
                      final modelCm = _heightToCm(parsed, _heightUnit);
                      _heightUnit = v;
                      // update controller text to reflect new unit
                      final newDisplay = _formatDisplay(_cmToUnit(modelCm, _heightUnit), _heightUnit);
                      _heightListenerActive = false;
                      _heightController.text = newDisplay;
                      _heightListenerActive = true;
                    });
                  },
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF6B35),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: const Color(0xFFFF6B35),
              overlayColor: const Color(0xFFFF6B35).withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: isTablet ? 14 : 12,
              ),
            ),
            child: Slider(
              // Slider works in model units (cm)
              value: _viewModel.height ?? 170,
              min: minHeight,
              max: maxHeight,
              onChanged: (value) {
                _viewModel.setHeight(value);
                // update controller text in selected unit without retriggering listener
                final displayVal = _cmToUnit(value, _heightUnit);
                _heightListenerActive = false;
                _heightController.text = _formatDisplay(displayVal, _heightUnit);
                _heightListenerActive = true;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF6B35),
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: _weightUnit,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      final parsed = double.tryParse(_weightController.text) ?? _kgToUnit(_viewModel.weight ?? 70, _weightUnit);
                      final modelKg = _weightToKg(parsed, _weightUnit);
                      _weightUnit = v;
                      final newDisplay = _formatDisplay(_kgToUnit(modelKg, _weightUnit), _weightUnit);
                      _weightListenerActive = false;
                      _weightController.text = newDisplay;
                      _weightListenerActive = true;
                    });
                  },
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF6B35),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: const Color(0xFFFF6B35),
              overlayColor: const Color(0xFFFF6B35).withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: isTablet ? 14 : 12,
              ),
            ),
            child: Slider(
              value: _viewModel.weight ?? 70,
              min: minWeight,
              max: maxWeight,
              onChanged: (value) {
                _viewModel.setWeight(value);
                final displayVal = _kgToUnit(value, _weightUnit);
                _weightListenerActive = false;
                _weightController.text = _formatDisplay(displayVal, _weightUnit);
                _weightListenerActive = true;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _viewModel.bmi != null ? 1.0 : 0.0,
          child: Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _viewModel.categoryColor ?? Colors.grey,
                  (_viewModel.categoryColor ?? Colors.grey).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_viewModel.categoryColor ?? Colors.grey).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your BMI',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  _viewModel.bmi!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: isTablet ? 64 : 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 20,
                    vertical: isTablet ? 12 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _viewModel.category!,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        ElevatedButton.icon(
          onPressed: _canSave() ? _onSavePressed : null,
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('Save to History'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(bool isTablet) {
    return ElevatedButton(
      onPressed: _viewModel.reset,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF6B35),
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 20 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
            color: Color(0xFFFF6B35),
            width: 2,
          ),
        ),
        elevation: 0,
      ),
      child: Text(
        'Reset',
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}