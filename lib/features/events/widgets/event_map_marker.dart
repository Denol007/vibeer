import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/event_model.dart';

/// Utility class for creating custom map markers based on event state
///
/// Generates different marker icons for:
/// - Events starting soon (< 1 hour)
/// - Events happening now
/// - Events almost full (at capacity)
/// - Regular events with space
class EventMapMarker {
  /// Get marker color and icon based on event state
  static (Color, IconData) getMarkerStyle(EventModel event) {
    final now = DateTime.now();
    final eventStart = event.startTime;
    final isFull = event.currentParticipants >= event.neededParticipants + 1;
    final minutesUntilStart = eventStart.difference(now).inMinutes;

    // Event is happening now (within 15 minutes of start time)
    if (minutesUntilStart.abs() <= 15) {
      return (
        const Color(0xFF9C27B0),
        Icons.flash_on,
      ); // Purple - happening now
    }

    // Event is almost full
    if (isFull) {
      return (const Color(0xFFF44336), Icons.group); // Red - full
    }

    // Event starting soon (< 1 hour)
    if (minutesUntilStart > 0 && minutesUntilStart <= 60) {
      return (
        const Color(0xFFFF9800),
        Icons.schedule,
      ); // Orange - starting soon
    }

    // Regular event with space
    return (
      const Color(0xFF4CAF50),
      Icons.event_available,
    ); // Green - available
  }

  /// Create custom bitmap descriptor for marker
  static Future<BitmapDescriptor> createCustomMarkerBitmap({
    required Color color,
    required IconData icon,
    required String participantCount,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    const double markerSize = 120;
    const double iconSize = 40;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2 + 2),
      markerSize / 2 - 4,
      shadowPaint,
    );

    // Draw main circle background
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      markerSize / 2 - 8,
      circlePaint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      markerSize / 2 - 8,
      borderPaint,
    );

    // Draw icon
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (markerSize - iconPainter.width) / 2,
        (markerSize - iconPainter.height) / 2 - 8,
      ),
    );

    // Draw participant count badge
    final textPainter = TextPainter(
      text: TextSpan(
        text: participantCount,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgeWidth = textPainter.width + 16;
    final badgeHeight = textPainter.height + 8;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(markerSize / 2, markerSize - 16),
        width: badgeWidth,
        height: badgeHeight,
      ),
      const Radius.circular(12),
    );

    // Draw badge background
    final badgePaint = Paint()..color = Colors.white;
    canvas.drawRRect(badgeRect, badgePaint);

    // Draw badge border
    final badgeBorderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(badgeRect, badgeBorderPaint);

    // Draw count text in badge
    final countTextPainter = TextPainter(
      text: TextSpan(
        text: participantCount,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    countTextPainter.layout();
    countTextPainter.paint(
      canvas,
      Offset(
        (markerSize - countTextPainter.width) / 2,
        markerSize - 16 - countTextPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(markerSize.toInt(), markerSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Get marker icon based on event state (fallback to default if custom fails)
  static BitmapDescriptor getMarkerIcon(EventModel event) {
    final (color, _) = getMarkerStyle(event);

    // Fallback to colored default marker
    double hue;
    if (color.value == const Color(0xFF9C27B0).value) {
      hue = BitmapDescriptor.hueViolet;
    } else if (color.value == const Color(0xFFF44336).value) {
      hue = BitmapDescriptor.hueRed;
    } else if (color.value == const Color(0xFFFF9800).value) {
      hue = BitmapDescriptor.hueOrange;
    } else {
      hue = BitmapDescriptor.hueGreen;
    }

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  /// Get marker info window title
  static String getMarkerTitle(EventModel event) {
    return event.title;
  }

  /// Get marker info window snippet
  static String getMarkerSnippet(EventModel event) {
    final participantCount =
        '${event.currentParticipants}/${event.neededParticipants + 1}';
    final minutesUntilStart = event.startTime
        .difference(DateTime.now())
        .inMinutes;

    if (minutesUntilStart.abs() <= 15) {
      return '$participantCount • Происходит сейчас';
    } else if (minutesUntilStart > 0 && minutesUntilStart <= 60) {
      return '$participantCount • Начинается через $minutesUntilStart мин';
    } else if (event.currentParticipants >= event.neededParticipants + 1) {
      return '$participantCount • Набрано';
    } else {
      return '$participantCount участников';
    }
  }

  /// Create a complete Marker from EventModel with custom icon
  static Future<Marker> createMarker({
    required EventModel event,
    required VoidCallback onTap,
  }) async {
    final (color, icon) = getMarkerStyle(event);
    final participantCount =
        '${event.currentParticipants}/${event.neededParticipants + 1}';

    BitmapDescriptor markerIcon;
    try {
      markerIcon = await createCustomMarkerBitmap(
        color: color,
        icon: icon,
        participantCount: participantCount,
      );
    } catch (e) {
      // Fallback to default marker if custom creation fails
      markerIcon = getMarkerIcon(event);
    }

    return Marker(
      markerId: MarkerId(event.id),
      position: LatLng(event.location.latitude, event.location.longitude),
      infoWindow: InfoWindow(
        title: getMarkerTitle(event),
        snippet: getMarkerSnippet(event),
      ),
      icon: markerIcon,
      onTap: onTap,
      anchor: const Offset(0.5, 0.5), // Center the custom marker
    );
  }
}

/// Extension for LatLng to work with GeoPoint
extension GeoPointExt on LatLng {
  LatLng toLatLng(double latitude, double longitude) {
    return LatLng(latitude, longitude);
  }
}
