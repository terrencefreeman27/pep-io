import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service for managing iOS home screen widgets
class WidgetService {
  // App Group identifier - must match iOS widget
  static const String appGroupId = 'group.com.pepio.app';
  
  // iOS widget name - must match widget kind in Swift
  static const String iOSWidgetName = 'PepIOWidget';
  
  // Track initialization state
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  /// Initialize the widget service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }
    
    _initializationFuture = _doInitialize();
    await _initializationFuture;
  }
  
  Future<void> _doInitialize() async {
    if (!Platform.isIOS) {
      _isInitialized = true;
      return;
    }
    
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _isInitialized = true;
      debugPrint('WidgetService: App Group ID set successfully');
    } catch (e) {
      debugPrint('WidgetService: Failed to set app group ID: $e');
    }
  }
  
  /// Ensure initialized before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Update widget with all protocol data
  /// This triggers an immediate widget refresh to show new/updated protocols
  Future<bool> updateWidgetWithProtocols({
    required List<Map<String, dynamic>> protocolData,
    required int overallStreak,
    required int overallAdherence,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      // Ensure App Group is set before saving data
      await _ensureInitialized();
      
      // Save all protocols as JSON array
      final protocolsJson = jsonEncode(protocolData);
      debugPrint('WidgetService: Saving protocols JSON: $protocolsJson');
      
      // Save timestamp for tracking last update (helps with debugging)
      final updateTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      await Future.wait([
        HomeWidget.saveWidgetData<String>('protocols_json', protocolsJson),
        HomeWidget.saveWidgetData<int>('overall_streak', overallStreak),
        HomeWidget.saveWidgetData<int>('overall_adherence', overallAdherence),
        HomeWidget.saveWidgetData<int>('protocol_count', protocolData.length),
        HomeWidget.saveWidgetData<int>('last_widget_update', updateTimestamp),
      ]);

      // Tell iOS to refresh the widget immediately
      // This forces the widget to reload its timeline with new data
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        qualifiedAndroidName: null,
      );

      debugPrint('WidgetService: Widget updated with ${protocolData.length} protocols at $updateTimestamp');
      return true;
    } catch (e) {
      debugPrint('WidgetService: Failed to update widget: $e');
      return false;
    }
  }

  /// Force refresh the widget without changing data
  /// Useful when user adds/removes protocols and you want immediate update
  Future<bool> forceRefreshWidget() async {
    if (!Platform.isIOS) return false;

    try {
      await _ensureInitialized();
      
      // Just trigger widget update to reload timeline
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        qualifiedAndroidName: null,
      );

      debugPrint('WidgetService: Forced widget refresh');
      return true;
    } catch (e) {
      debugPrint('WidgetService: Failed to force refresh widget: $e');
      return false;
    }
  }

  /// Clear widget data
  Future<bool> clearWidget() async {
    if (!Platform.isIOS) return false;

    try {
      // Ensure App Group is set before clearing data
      await _ensureInitialized();
      
      await Future.wait([
        HomeWidget.saveWidgetData<String>('protocols_json', '[]'),
        HomeWidget.saveWidgetData<int>('overall_streak', 0),
        HomeWidget.saveWidgetData<int>('overall_adherence', 0),
        HomeWidget.saveWidgetData<int>('protocol_count', 0),
      ]);

      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        qualifiedAndroidName: null,
      );

      return true;
    } catch (e) {
      debugPrint('WidgetService: Failed to clear widget: $e');
      return false;
    }
  }

  /// Check if widgets are supported
  bool get isSupported => Platform.isIOS;

  /// Show instructions for adding the widget
  static String get addWidgetInstructions => '''
To add the pep.io widget to your home screen:

1. Long-press on your home screen
2. Tap the + button in the top left
3. Search for "pep.io" or "Protocol Tracker"
4. Choose your preferred widget size
5. Tap "Add Widget"

Your protocol data will update automatically!
''';
}

