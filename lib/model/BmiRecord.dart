class BMIRecord {
  int? id;
  double bmi;
  String category;
  double height;
  double weight;
  String gender;
  String createdAt; // ISO string

  BMIRecord({
    this.id,
    required this.bmi,
    required this.category,
    required this.height,
    required this.weight,
    required this.gender,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'bmi': bmi,
      'category': category,
      'height': height,
      'weight': weight,
      'gender': gender,
      'createdAt': createdAt,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory BMIRecord.fromMap(Map<String, dynamic> map) {
    return BMIRecord(
      id: map['id'] as int?,
      bmi: (map['bmi'] as num).toDouble(),
      category: map['category'] as String,
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      gender: map['gender'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}

