import 'package:flutter/material.dart';
import '../models/models.dart';

class AssemblyStep {
  final int x;
  final int y;
  final BeadColor color;
  final int stepIndex;
  final int totalSteps;
  final List<Point<int>> sameColorPositions;

  AssemblyStep({
    required this.x,
    required this.y,
    required this.color,
    required this.stepIndex,
    required this.totalSteps,
    this.sameColorPositions = const [],
  });

  double get progress => (stepIndex + 1) / totalSteps;
}

class AssemblyGuideService extends ChangeNotifier {
  List<AssemblyStep> _steps = [];
  int _currentStepIndex = -1;
  bool _isPlaying = false;
  double _animationSpeed = 1.0;
  bool _showSameColorHint = true;

  List<AssemblyStep> get steps => List.unmodifiable(_steps);
  int get currentStepIndex => _currentStepIndex;
  AssemblyStep? get currentStep =>
      _currentStepIndex >= 0 && _currentStepIndex < _steps.length
      ? _steps[_currentStepIndex]
      : null;
  bool get isPlaying => _isPlaying;
  double get animationSpeed => _animationSpeed;
  bool get showSameColorHint => _showSameColorHint;
  bool get hasSteps => _steps.isNotEmpty;
  int get totalSteps => _steps.length;
  int get remainingSteps => _steps.length - _currentStepIndex - 1;

  void generateAssemblySteps(BeadDesign design) {
    _steps.clear();
    _currentStepIndex = -1;

    final colorGroups = <String, List<Point<int>>>{};
    final colorMap = <String, BeadColor>{};

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.getBead(x, y);
        if (bead != null) {
          final code = bead.code;
          colorGroups.putIfAbsent(code, () => []);
          colorGroups[code]!.add(Point(x, y));
          colorMap[code] = bead;
        }
      }
    }

    final sortedColors = colorGroups.entries.toList()
      ..sort((a, b) => a.value.length.compareTo(b.value.length));

    int stepIndex = 0;
    for (final entry in sortedColors) {
      final color = colorMap[entry.key]!;
      final positions = entry.value;

      positions.sort((a, b) {
        final rowCompare = a.y.compareTo(b.y);
        if (rowCompare != 0) return rowCompare;
        return a.x.compareTo(b.x);
      });

      for (final position in positions) {
        _steps.add(
          AssemblyStep(
            x: position.x,
            y: position.y,
            color: color,
            stepIndex: stepIndex,
            totalSteps: design.getTotalBeadCount(),
            sameColorPositions: positions,
          ),
        );
        stepIndex++;
      }
    }

    notifyListeners();
  }

  void generateAssemblyStepsByRow(BeadDesign design) {
    _steps.clear();
    _currentStepIndex = -1;

    int stepIndex = 0;
    final totalBeads = design.getTotalBeadCount();

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.getBead(x, y);
        if (bead != null) {
          final sameColorPositions = <Point<int>>[];
          for (int sy = 0; sy < design.height; sy++) {
            for (int sx = 0; sx < design.width; sx++) {
              final otherBead = design.getBead(sx, sy);
              if (otherBead != null && otherBead.code == bead.code) {
                sameColorPositions.add(Point(sx, sy));
              }
            }
          }

          _steps.add(
            AssemblyStep(
              x: x,
              y: y,
              color: bead,
              stepIndex: stepIndex,
              totalSteps: totalBeads,
              sameColorPositions: sameColorPositions,
            ),
          );
          stepIndex++;
        }
      }
    }

    notifyListeners();
  }

  void generateAssemblyStepsByColumn(BeadDesign design) {
    _steps.clear();
    _currentStepIndex = -1;

    int stepIndex = 0;
    final totalBeads = design.getTotalBeadCount();

    for (int x = 0; x < design.width; x++) {
      for (int y = 0; y < design.height; y++) {
        final bead = design.getBead(x, y);
        if (bead != null) {
          final sameColorPositions = <Point<int>>[];
          for (int sy = 0; sy < design.height; sy++) {
            for (int sx = 0; sx < design.width; sx++) {
              final otherBead = design.getBead(sx, sy);
              if (otherBead != null && otherBead.code == bead.code) {
                sameColorPositions.add(Point(sx, sy));
              }
            }
          }

          _steps.add(
            AssemblyStep(
              x: x,
              y: y,
              color: bead,
              stepIndex: stepIndex,
              totalSteps: totalBeads,
              sameColorPositions: sameColorPositions,
            ),
          );
          stepIndex++;
        }
      }
    }

    notifyListeners();
  }

  void start() {
    if (_steps.isEmpty) return;
    _currentStepIndex = 0;
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    if (_steps.isEmpty || _currentStepIndex >= _steps.length - 1) return;
    _isPlaying = true;
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _currentStepIndex = -1;
    notifyListeners();
  }

  void reset() {
    _isPlaying = false;
    _currentStepIndex = -1;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      notifyListeners();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void jumpToStep(int index) {
    if (index >= 0 && index < _steps.length) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  void setAnimationSpeed(double speed) {
    _animationSpeed = speed.clamp(0.25, 4.0);
    notifyListeners();
  }

  void setShowSameColorHint(bool show) {
    _showSameColorHint = show;
    notifyListeners();
  }

  void clearSteps() {
    _steps.clear();
    _currentStepIndex = -1;
    _isPlaying = false;
    notifyListeners();
  }

  List<AssemblyStep> getStepsForColor(String colorCode) {
    return _steps.where((step) => step.color.code == colorCode).toList();
  }

  int getColorRemainingCount(String colorCode) {
    if (_currentStepIndex < 0) return 0;
    return _steps
        .skip(_currentStepIndex + 1)
        .where((step) => step.color.code == colorCode)
        .length;
  }

  Map<BeadColor, int> getColorProgress() {
    final progress = <BeadColor, int>{};
    for (int i = 0; i <= _currentStepIndex && i < _steps.length; i++) {
      final color = _steps[i].color;
      progress[color] = (progress[color] ?? 0) + 1;
    }
    return progress;
  }
}

class Point<T> {
  final T x;
  final T y;

  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point<T> && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class AssemblyAnimationController extends ChangeNotifier {
  final AssemblyGuideService _guideService;
  late final AnimationController _controller;
  bool _isInitialized = false;

  AssemblyAnimationController(this._guideService);

  void initialize(TickerProvider vsync) {
    if (_isInitialized) return;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    )..addStatusListener(_onAnimationStatus);
    _isInitialized = true;
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _guideService.nextStep();
      if (_guideService.isPlaying) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  Animation<double> get animation => _controller;

  void playStep() {
    if (!_isInitialized || !_guideService.hasSteps) return;

    final speed = _guideService.animationSpeed;
    _controller.duration = Duration(milliseconds: (500 / speed).round());
    _controller.forward();
  }

  void pause() {
    _controller.stop();
    _guideService.pause();
  }

  void resume() {
    _guideService.resume();
    playStep();
  }

  void stop() {
    _controller.reset();
    _guideService.stop();
  }

  void reset() {
    _controller.reset();
    _guideService.reset();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }
}
