import 'package:flutter/material.dart';
import '../models/bead_design.dart';
import '../models/plugin_interface.dart';
import '../services/plugin_service.dart';
import '../plugins/color_optimizer_plugin.dart';
import '../plugins/dithering_plugin.dart';
import '../plugins/outline_plugin.dart';

class PluginProvider extends ChangeNotifier {
  final PluginService _pluginService;

  List<IPlugin> _plugins = [];
  IPlugin? _selectedPlugin;
  Map<String, dynamic> _currentParameters = {};
  bool _isProcessing = false;
  String? _lastError;
  PluginResult? _lastResult;
  BeadDesign? _currentDesign;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  PluginProvider() : _pluginService = PluginService() {
    _loadBuiltInPlugins();
  }

  List<IPlugin> get plugins => _plugins;
  IPlugin? get selectedPlugin => _selectedPlugin;
  Map<String, dynamic> get currentParameters => _currentParameters;
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  PluginResult? get lastResult => _lastResult;
  BeadDesign? get currentDesign => _currentDesign;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<IPlugin> get filteredPlugins {
    var filtered = _plugins;
    
    if (_selectedCategory != 'all') {
      filtered = filtered.where((p) => p.metadata.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
               p.description.toLowerCase().contains(query) ||
               p.metadata.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }
    
    return filtered;
  }

  void _loadBuiltInPlugins() {
    _pluginService.registerPlugin(ColorOptimizerPlugin());
    _pluginService.registerPlugin(DitheringPlugin());
    _pluginService.registerPlugin(OutlinePlugin());
    _plugins = _pluginService.plugins;
    notifyListeners();
  }

  void setCurrentDesign(BeadDesign? design) {
    _currentDesign = design;
    notifyListeners();
  }

  void selectPlugin(String pluginName) {
    final plugin = _pluginService.getPlugin(pluginName);
    if (plugin != null) {
      _selectedPlugin = plugin;
      _currentParameters = plugin.getDefaultParameters();
      _lastError = null;
      _lastResult = null;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedPlugin = null;
    _currentParameters = {};
    _lastError = null;
    _lastResult = null;
    notifyListeners();
  }

  void updateParameter(String key, dynamic value) {
    _currentParameters[key] = value;
    notifyListeners();
  }

  void updateParameters(Map<String, dynamic> params) {
    _currentParameters.addAll(params);
    notifyListeners();
  }

  void resetParameters() {
    if (_selectedPlugin != null) {
      _currentParameters = _selectedPlugin!.getDefaultParameters();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<PluginResult?> executePlugin() async {
    if (_selectedPlugin == null || _currentDesign == null) {
      _lastError = '请先选择插件和设计';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = _pluginService.executePlugin(
        _selectedPlugin!.name,
        _currentDesign!,
        _currentParameters,
      );

      _lastResult = result;

      if (result.success) {
        _currentDesign = result.design;
      } else {
        _lastError = result.message;
      }
      
      return result;
    } catch (e) {
      _lastError = '执行插件时发生错误: ${e.toString()}';
      return PluginResult.failure(_currentDesign!, _lastError!);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  PluginResult executePluginWithDesign(BeadDesign design) {
    if (_selectedPlugin == null) {
      return PluginResult.failure(design, '请先选择插件');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final result = _pluginService.executePlugin(
        _selectedPlugin!.name,
        design,
        _currentParameters,
      );

      _lastResult = result;
      _lastError = result.success ? null : result.message;

      return result;
    } catch (e) {
      _lastError = '执行插件时发生错误: ${e.toString()}';
      return PluginResult.failure(design, _lastError!);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  List<IPlugin> getPluginsByCategory(String category) {
    return _plugins.where((p) => p.metadata.category == category).toList();
  }

  Set<String> get categories {
    return _plugins.map((p) => p.metadata.category).toSet();
  }

  Map<String, List<IPlugin>> get pluginsGroupedByCategory {
    final grouped = <String, List<IPlugin>>{};
    for (final plugin in _plugins) {
      grouped.putIfAbsent(plugin.metadata.category, () => []).add(plugin);
    }
    return grouped;
  }

  void registerCustomPlugin(IPlugin plugin) {
    try {
      _pluginService.registerPlugin(plugin);
      _plugins = _pluginService.plugins;
      notifyListeners();
    } catch (e) {
      _lastError = '注册插件失败: ${e.toString()}';
      notifyListeners();
    }
  }

  void unregisterPlugin(String pluginName) {
    if (_selectedPlugin?.name == pluginName) {
      clearSelection();
    }
    _pluginService.unregisterPlugin(pluginName);
    _plugins = _pluginService.plugins;
    notifyListeners();
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  void clearLastResult() {
    _lastResult = null;
    notifyListeners();
  }

  bool validateCurrentParameters() {
    if (_selectedPlugin == null) return false;
    return _selectedPlugin!.validateParameters(_currentParameters);
  }

  bool get hasDesign => _currentDesign != null;
  bool get hasSelection => _selectedPlugin != null;
  bool get canExecute => hasDesign && hasSelection && !isProcessing && validateCurrentParameters();
}
