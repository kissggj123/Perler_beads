import '../models/plugin_interface.dart';
import '../models/bead_design.dart';

class PluginService {
  static final PluginService _instance = PluginService._internal();
  factory PluginService() => _instance;
  PluginService._internal();

  final Map<String, IPlugin> _plugins = {};

  List<IPlugin> get plugins => _plugins.values.toList();

  List<String> get pluginNames => _plugins.keys.toList();

  void registerPlugin(IPlugin plugin) {
    if (_plugins.containsKey(plugin.name)) {
      throw PluginException('Plugin "${plugin.name}" is already registered');
    }
    _plugins[plugin.name] = plugin;
  }

  void unregisterPlugin(String pluginName) {
    if (!_plugins.containsKey(pluginName)) {
      throw PluginException('Plugin "$pluginName" not found');
    }
    _plugins.remove(pluginName);
  }

  IPlugin? getPlugin(String pluginName) {
    return _plugins[pluginName];
  }

  bool hasPlugin(String pluginName) {
    return _plugins.containsKey(pluginName);
  }

  List<IPlugin> getPluginsByCategory(String category) {
    return _plugins.values
        .where((plugin) => plugin.metadata.category == category)
        .toList();
  }

  List<IPlugin> getPluginsByTag(String tag) {
    return _plugins.values
        .where((plugin) => plugin.metadata.tags.contains(tag))
        .toList();
  }

  Set<String> getCategories() {
    return _plugins.values
        .map((plugin) => plugin.metadata.category)
        .toSet();
  }

  Set<String> getTags() {
    final tags = <String>{};
    for (final plugin in _plugins.values) {
      tags.addAll(plugin.metadata.tags);
    }
    return tags;
  }

  PluginResult executePlugin(
    String pluginName,
    BeadDesign design,
    Map<String, dynamic> params,
  ) {
    final plugin = _plugins[pluginName];
    if (plugin == null) {
      return PluginResult.failure(
        design,
        'Plugin "$pluginName" not found',
      );
    }

    if (!plugin.validateParameters(params)) {
      return PluginResult.failure(
        design,
        'Invalid parameters for plugin "$pluginName"',
      );
    }

    try {
      return plugin.process(design, params);
    } catch (e) {
      return PluginResult.failure(
        design,
        'Error executing plugin "$pluginName": ${e.toString()}',
      );
    }
  }

  Map<String, dynamic> getDefaultParameters(String pluginName) {
    final plugin = _plugins[pluginName];
    if (plugin == null) {
      return {};
    }
    return plugin.getDefaultParameters();
  }

  bool validatePluginParameters(
    String pluginName,
    Map<String, dynamic> params,
  ) {
    final plugin = _plugins[pluginName];
    if (plugin == null) {
      return false;
    }
    return plugin.validateParameters(params);
  }

  void clearPlugins() {
    _plugins.clear();
  }

  int get pluginCount => _plugins.length;

  Map<String, dynamic> exportPluginList() {
    return {
      'plugins': _plugins.values.map((p) => p.toJson()).toList(),
    };
  }
}

class PluginException implements Exception {
  final String message;
  PluginException(this.message);

  @override
  String toString() => 'PluginException: $message';
}
