import '../models/bead_color.dart';
import '../models/bead_count_result.dart';
import '../models/bead_design.dart';

class BeadCountService {
  static final BeadCountService _instance = BeadCountService._internal();
  factory BeadCountService() => _instance;
  BeadCountService._internal();

  double _defaultTolerancePercentage = 0.05;

  double get defaultTolerancePercentage => _defaultTolerancePercentage;

  void setDefaultTolerancePercentage(double percentage) {
    if (percentage >= 0 && percentage <= 1) {
      _defaultTolerancePercentage = percentage;
    }
  }

  List<BeadCountResult> calculateBeadCounts(
    BeadDesign design, {
    double? tolerancePercentage,
  }) {
    final tolerance = tolerancePercentage ?? _defaultTolerancePercentage;
    final colorCounts = design.getBeadCountsWithColors();

    final results = <BeadCountResult>[];
    for (final entry in colorCounts.entries) {
      results.add(
        BeadCountResult.fromCount(
          entry.key,
          entry.value,
          tolerancePercentage: tolerance,
        ),
      );
    }

    results.sort((a, b) => b.count.compareTo(a.count));

    return results;
  }

  Map<String, dynamic> calculateBeadCountsWithTolerance(
    BeadDesign design, {
    double? tolerancePercentage,
  }) {
    final results = calculateBeadCounts(
      design,
      tolerancePercentage: tolerancePercentage,
    );

    final totalBeads = results.fold<int>(
      0,
      (sum, result) => sum + result.count,
    );
    final totalMinTolerance = results.fold<int>(
      0,
      (sum, result) => sum + result.minTolerance,
    );
    final totalMaxTolerance = results.fold<int>(
      0,
      (sum, result) => sum + result.maxTolerance,
    );

    return {
      'results': results,
      'totalBeads': totalBeads,
      'totalMinTolerance': totalMinTolerance,
      'totalMaxTolerance': totalMaxTolerance,
      'totalRange':
          '${totalBeads - totalMinTolerance} - ${totalBeads + totalMaxTolerance}',
      'colorCount': results.length,
    };
  }

  BeadCountResult calculateSingleColorCount(
    BeadColor color,
    int count, {
    double? tolerancePercentage,
  }) {
    return BeadCountResult.fromCount(
      color,
      count,
      tolerancePercentage: tolerancePercentage ?? _defaultTolerancePercentage,
    );
  }

  Map<String, int> getToleranceStats(List<BeadCountResult> results) {
    if (results.isEmpty) {
      return {
        'totalBeads': 0,
        'totalMinTolerance': 0,
        'totalMaxTolerance': 0,
        'colorCount': 0,
      };
    }

    final totalBeads = results.fold<int>(
      0,
      (sum, result) => sum + result.count,
    );
    final totalMinTolerance = results.fold<int>(
      0,
      (sum, result) => sum + result.minTolerance,
    );
    final totalMaxTolerance = results.fold<int>(
      0,
      (sum, result) => sum + result.maxTolerance,
    );

    return {
      'totalBeads': totalBeads,
      'totalMinTolerance': totalMinTolerance,
      'totalMaxTolerance': totalMaxTolerance,
      'colorCount': results.length,
    };
  }
}
