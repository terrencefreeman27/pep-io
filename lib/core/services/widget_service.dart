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

  /// Initialize the widget service
  Future<void> initialize() async {
    if (!Platform.isIOS) return;
    
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('WidgetService: Failed to set app group ID: $e');
    }
  }

  /// Update widget with all protocol data
  Future<bool> updateWidgetWithProtocols({
    required List<Map<String, dynamic>> protocolData,
    required int overallStreak,
    required int overallAdherence,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      // Save all protocols as JSON array
      final protocolsJson = jsonEncode(protocolData);
      
      await Future.wait([
        HomeWidget.saveWidgetData<String>('protocols_json', protocolsJson),
        HomeWidget.saveWidgetData<int>('overall_streak', overallStreak),
        HomeWidget.saveWidgetData<int>('overall_adherence', overallAdherence),
        HomeWidget.saveWidgetData<int>('protocol_count', protocolData.length),
      ]);

      // Tell iOS to refresh the widget
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        qualifiedAndroidName: null,
      );

      debugPrint('WidgetService: Widget updated with ${protocolData.length} protocols');
      return true;
    } catch (e) {
      debugPrint('WidgetService: Failed to update widget: $e');
      return false;
    }
  }

  /// Clear widget data
  Future<bool> clearWidget() async {
    if (!Platform.isIOS) return false;

    try {
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

