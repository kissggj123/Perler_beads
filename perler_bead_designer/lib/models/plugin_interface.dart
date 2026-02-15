import 'bead_design.dart';

abstract class PluginParameter {
  final String key;
  final String label;
  final String description;

  const PluginParameter({
    required this.key,
    required this.label,
    required this.description,
  });

  Map<String, dynamic> toJson();
}

class PluginParameterNumber extends PluginParameter {
  final double defaultValue;
  final double min;
  final double max;
  final double step;

  const PluginParameterNumber({
    required super.key,
    required super.label,
    required super.description,
    required this.defaultValue,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.step = 1.0,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'number',
      'key': key,
      'label': label,
      'description': description,
      'defaultValue': defaultValue,
      'min': min,
      'max': max,
      'step': step,
    };
  }
}

class PluginParameterBoolean extends PluginParameter {
  final bool defaultValue;

  const PluginParameterBoolean({
    required super.key,
    required super.label,
    required super.description,
    required this.defaultValue,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'boolean',
      'key': key,
      'label': label,
      'description': description,
      'defaultValue': defaultValue,
    };
  }
}

class PluginParameterSelect extends PluginParameter {
  final String defaultValue;
  final List<SelectOption> options;

  const PluginParameterSelect({
    required super.key,
    required super.label,
    required super.description,
    required this.defaultValue,
    required this.options,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'select',
      'key': key,
      'label': label,
      'description': description,
      'defaultValue': defaultValue,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class SelectOption {
  final String value;
  final String label;

  const SelectOption({
    required this.value,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}

class PluginMetadata {
  final String author;
  final String? website;
  final String? repository;
  final List<String> tags;
  final String category;

  const PluginMetadata({
    required this.author,
    this.website,
    this.repository,
    this.tags = const [],
    this.category = 'general',
  });

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'website': website,
      'repository': repository,
      'tags': tags,
      'category': category,
    };
  }
}

class PluginResult {
  final BeadDesign design;
  final String? message;
  final bool success;
  final Map<String, dynamic>? statistics;

  const PluginResult({
    required this.design,
    this.message,
    this.success = true,
    this.statistics,
  });

  factory PluginResult.success(BeadDesign design, {String? message, Map<String, dynamic>? statistics}) {
    return PluginResult(
      design: design,
      message: message,
      success: true,
      statistics: statistics,
    );
  }

  factory PluginResult.failure(BeadDesign originalDesign, String errorMessage) {
    return PluginResult(
      design: originalDesign,
      message: errorMessage,
      success: false,
    );
  }
}

abstract class IPlugin {
  String get name;
  String get description;
  String get version;
  PluginMetadata get metadata;

  List<PluginParameter> get parameters;

  Map<String, dynamic> getDefaultParameters();

  PluginResult process(BeadDesign design, Map<String, dynamic> params);

  bool validateParameters(Map<String, dynamic> params);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'version': version,
      'metadata': metadata.toJson(),
      'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }
}
