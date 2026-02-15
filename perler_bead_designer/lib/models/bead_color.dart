import 'dart:math';

import 'package:flutter/material.dart';

enum BeadBrand {
  perler,
  hama,
  artkal,
  taobao,
  pinduoduo,
  generic,
}

class BeadColor {
  final String code;
  final String name;
  final int red;
  final int green;
  final int blue;
  final BeadBrand brand;
  final String? category;

  const BeadColor({
    required this.code,
    required this.name,
    required this.red,
    required this.green,
    required this.blue,
    this.brand = BeadBrand.generic,
    this.category,
  });

  String get id => code;

  Color get color => Color.fromRGBO(red, green, blue, 1.0);

  String get hexCode => '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  String get hex => hexCode;

  int get r => red;
  int get g => green;
  int get b => blue;

  bool get isLight {
    final luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;
    return luminance > 0.5;
  }

  bool get isDark => !isLight;

  double distanceToColor(Color targetColor) {
    final targetRed = (targetColor.r * 255.0).round().clamp(0, 255);
    final targetGreen = (targetColor.g * 255.0).round().clamp(0, 255);
    final targetBlue = (targetColor.b * 255.0).round().clamp(0, 255);
    final dr = red - targetRed;
    final dg = green - targetGreen;
    final db = blue - targetBlue;
    return sqrt(dr * dr + dg * dg + db * db);
  }

  double distanceTo(BeadColor other) {
    final dr = red - other.red;
    final dg = green - other.green;
    final db = blue - other.blue;
    return sqrt(dr * dr + dg * dg + db * db);
  }

  factory BeadColor.fromJson(Map<String, dynamic> json) {
    return BeadColor(
      code: json['code'] as String,
      name: json['name'] as String,
      red: json['red'] as int,
      green: json['green'] as int,
      blue: json['blue'] as int,
      brand: BeadBrand.values.firstWhere(
        (b) => b.name == json['brand'],
        orElse: () => BeadBrand.generic,
      ),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'red': red,
      'green': green,
      'blue': blue,
      'brand': brand.name,
      'category': category,
    };
  }

  BeadColor copyWith({
    String? code,
    String? name,
    int? red,
    int? green,
    int? blue,
    BeadBrand? brand,
    String? category,
  }) {
    return BeadColor(
      code: code ?? this.code,
      name: name ?? this.name,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      brand: brand ?? this.brand,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeadColor && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'BeadColor($code: $name)';
}
