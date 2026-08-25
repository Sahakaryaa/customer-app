import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme/app_colors.dart';

/// Standardized CARTO raster tile layers per DESIGN_SPEC (no Google tiles).
class AppTiles {
  AppTiles._();

  static const String _userAgent = 'com.sahakarya.customer_app';

  /// Silences offline tile failures gracefully.
  static void _onTileError(TileImage tile, Object error, StackTrace? trace) {}

  /// CARTO Voyager — default light style for discovery/preview maps.
  static TileLayer voyager() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: _userAgent,
      maxNativeZoom: 19,
      retinaMode: true,
      errorTileCallback: _onTileError,
    );
  }

  /// CARTO Positron dark — for the tracking hero.
  static TileLayer darkAll() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: _userAgent,
      maxNativeZoom: 19,
      retinaMode: true,
      errorTileCallback: _onTileError,
    );
  }

  /// Required attribution layer (CARTO / OSM).
  static RichAttributionWidget attribution({bool dark = false}) {
    return RichAttributionWidget(
      showFlutterMapAttribution: false,
      popupBackgroundColor: dark ? AppColors.darkEnd : null,
      attributions: [
        TextSourceAttribution(
          '© OpenStreetMap contributors',
          textStyle: TextStyle(
            color: dark ? Colors.white60 : AppColors.inkSoft,
            fontSize: 10,
          ),
        ),
        TextSourceAttribution(
          '© CARTO',
          textStyle: TextStyle(
            color: dark ? Colors.white60 : AppColors.inkSoft,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
