import 'bead_color.dart';

class BeadCountResult {
  final BeadColor color;
  final int count;
  final int minTolerance;
  final int maxTolerance;
  final double tolerancePercentage;

  BeadCountResult({
    required this.color,
    required this.count,
    required this.minTolerance,
    required this.maxTolerance,
    required this.tolerancePercentage,
  });

  factory BeadCountResult.fromCount(BeadColor color, int count, {double tolerancePercentage = 0.05}) {
    final tolerance = (count * tolerancePercentage).round();
    return BeadCountResult(
      color: color,
      count: count,
      minTolerance: tolerance,
      maxTolerance: tolerance,
      tolerancePercentage: tolerancePercentage,
    );
  }

  int get minCount => count - minTolerance;
  int get maxCount => count + maxTolerance;

  String get displayText {
    if (minTolerance == 0 && maxTolerance == 0) {
      return '$count 颗';
    }
    return '$count±$minTolerance 颗';
  }

  String get rangeText => '$minCount - $maxCount 颗';

  Map<String, dynamic> toJson() {
    return {
      'color': color.toJson(),
      'count': count,
      'minTolerance': minTolerance,
      'maxTolerance': maxTolerance,
      'tolerancePercentage': tolerancePercentage,
    };
  }

  factory BeadCountResult.fromJson(Map<String, dynamic> json) {
    return BeadCountResult(
      color: BeadColor.fromJson(json['color'] as Map<String, dynamic>),
      count: json['count'] as int,
      minTolerance: json['minTolerance'] as int,
      maxTolerance: json['maxTolerance'] as int,
      tolerancePercentage: (json['tolerancePercentage'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeadCountResult &&
        other.color == color &&
        other.count == count &&
        other.minTolerance == minTolerance &&
        other.maxTolerance == maxTolerance;
  }

  @override
  int get hashCode {
    return Object.hash(color, count, minTolerance, maxTolerance);
  }

  @override
  String toString() {
    return 'BeadCountResult(color: ${color.name}, count: $count, tolerance: ±$minTolerance)';
  }
}
