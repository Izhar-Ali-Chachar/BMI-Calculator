import 'package:flutter/material.dart';

class BMIModel {
  double? height; // in cm
  double? weight; // in kg
  String gender;

  BMIModel({
    this.height,
    this.weight,
    this.gender = 'male',
  });

  double? calculateBMI() {
    if (height == null || weight == null || height! <= 0) return null;
    double heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
