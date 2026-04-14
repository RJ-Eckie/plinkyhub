import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

// ---------------------------------------------------------------------------
// JS interop for @mediapipe/tasks-vision (HandLandmarker)
// ---------------------------------------------------------------------------

@JS('FilesetResolver')
extension type _FilesetResolver._(JSObject _) implements JSObject {
  external static JSPromise<JSObject> forVisionTasks(JSString wasmPath);
}

@JS('HandLandmarker')
extension type _HandLandmarker._(JSObject _) implements JSObject {
  external static JSPromise<_HandLandmarker> createFromOptions(
    JSObject vision,
    JSObject options,
  );
  external JSObject detectForVideo(
    JSObject image,
    JSNumber timestampMilliseconds,
  );
}

/// A normalized 3D landmark from MediaPipe (values in 0..1).
class HandLandmark {
  const HandLandmark({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;
}

/// Thumb tip and index finger tip landmark indices.
const thumbTipIndex = 4;
const indexTipIndex = 8;

/// Normalized distance threshold below which the thumb and index
/// finger are considered to be pinching. Tuned for typical webcam
/// hand sizes — roughly 6 % of the frame width.
const pinchThreshold = 0.06;

/// Result of a pinch-gesture check for one hand.
class PinchResult {
  const PinchResult({
    required this.isPinching,
    required this.x,
    required this.y,
    required this.closeness,
  });

  /// Whether the thumb and index tips are close enough to count as a
  /// pinch (distance < [pinchThreshold]).
  final bool isPinching;

  /// Normalised contact point (midpoint of thumb tip and index tip),
  /// in the same 0..1 coordinate space as the raw landmarks.
  final double x;
  final double y;

  /// How tightly the pinch is closed, in [0, 1]. 1 = tips touching,
  /// 0 = at or beyond the threshold. Maps naturally to MIDI velocity
  /// / pressure.
  final double closeness;
}

/// Detects whether a hand is making a pinch gesture (thumb tip close
/// to index finger tip). Much more reliable across hand angles than
/// per-finger extension checks because it only measures the distance
/// between two well-tracked landmarks.
PinchResult? detectPinch(List<HandLandmark> hand) {
  if (hand.length <= indexTipIndex) {
    return null;
  }
  final thumb = hand[thumbTipIndex];
  final index = hand[indexTipIndex];
  final dx = thumb.x - index.x;
  final dy = thumb.y - index.y;
  final distance = sqrt(dx * dx + dy * dy);
  final isPinching = distance < pinchThreshold;
  final closeness = isPinching
      ? (1.0 - distance / pinchThreshold).clamp(0.0, 1.0)
      : 0.0;
  return PinchResult(
    isPinching: isPinching,
    x: (thumb.x + index.x) / 2,
    y: (thumb.y + index.y) / 2,
    closeness: closeness,
  );
}

typedef HandResultsCallback =
    void Function(
      List<List<HandLandmark>> hands,
    );

/// Wraps the MediaPipe Tasks Vision HandLandmarker (loaded from CDN
/// in `web/index.html`). Uses CPU delegate to avoid WebGL context
/// conflicts with Flutter's CanvasKit renderer.
class MediaPipeHandsService {
  _HandLandmarker? _handLandmarker;
  int? _animationFrameId;
  HandResultsCallback? onResults;
  bool _running = false;

  /// Whether the MediaPipe Tasks Vision JS library is loaded.
  static bool get isSupported {
    return globalContext.has('FilesetResolver');
  }

  Future<void> initialize(web.HTMLVideoElement videoElement) async {
    // The ES module script in index.html loads asynchronously; wait
    // for the globals to appear on window before proceeding.
    await _waitForGlobal('FilesetResolver');

    final vision = await _FilesetResolver.forVisionTasks(
      'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision/wasm'.toJS,
    ).toDart;

    _handLandmarker = await _HandLandmarker.createFromOptions(
      vision,
      _makeJsObject({
        'baseOptions': _makeJsObject({
          'modelAssetPath':
              'https://storage.googleapis.com/mediapipe-models/'
                      'hand_landmarker/hand_landmarker/float16/1/'
                      'hand_landmarker.task'
                  .toJS,
          'delegate': 'CPU'.toJS,
        }),
        'runningMode': 'VIDEO'.toJS,
        'numHands': 2.toJS,
      }),
    ).toDart;

    _running = true;
    _detectLoop(videoElement);
  }

  void _detectLoop(web.HTMLVideoElement videoElement) {
    if (!_running || _handLandmarker == null) {
      return;
    }

    void onFrame(JSNumber timestamp) {
      if (!_running || _handLandmarker == null) {
        return;
      }

      try {
        if (videoElement.readyState >= 2) {
          final results = _handLandmarker!.detectForVideo(
            videoElement as JSObject,
            timestamp,
          );
          _processResults(results);
        }
      } on Object catch (error) {
        debugPrint('MediaPipe detect error: $error');
      }

      _animationFrameId = web.window.requestAnimationFrame(onFrame.toJS);
    }

    _animationFrameId = web.window.requestAnimationFrame(onFrame.toJS);
  }

  void _processResults(JSObject results) {
    final callback = onResults;
    if (callback == null) {
      return;
    }

    final landmarksRaw = results['landmarks'];
    if (landmarksRaw == null || landmarksRaw.isUndefinedOrNull) {
      callback([]);
      return;
    }

    final handsArray = landmarksRaw as JSArray;
    final hands = <List<HandLandmark>>[];
    for (var handIndex = 0; handIndex < handsArray.length; handIndex++) {
      final handRaw = handsArray[handIndex];
      if (handRaw == null) {
        continue;
      }
      final landmarks = handRaw as JSArray;
      final points = <HandLandmark>[];
      for (var i = 0; i < landmarks.length; i++) {
        final point = landmarks[i];
        if (point == null) {
          continue;
        }
        final pointObject = point as JSObject;
        final x = pointObject['x'];
        final y = pointObject['y'];
        final z = pointObject['z'];
        if (x == null || y == null || z == null) {
          continue;
        }
        points.add(
          HandLandmark(
            x: (x as JSNumber).toDartDouble,
            y: (y as JSNumber).toDartDouble,
            z: (z as JSNumber).toDartDouble,
          ),
        );
      }
      hands.add(points);
    }
    callback(hands);
  }

  void dispose() {
    _running = false;
    final frameId = _animationFrameId;
    if (frameId != null) {
      web.window.cancelAnimationFrame(frameId);
    }
    _handLandmarker = null;
    _animationFrameId = null;
  }
}

/// Polls until [name] appears on the JS global context, with a
/// timeout so we don't spin forever if the script failed to load.
Future<void> _waitForGlobal(String name) async {
  const pollInterval = Duration(milliseconds: 100);
  const timeout = Duration(seconds: 15);
  final deadline = DateTime.now().add(timeout);
  while (!globalContext.has(name)) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError(
        'MediaPipe script did not load within '
        '${timeout.inSeconds} seconds ($name not found)',
      );
    }
    await Future<void>.delayed(pollInterval);
  }
}

/// Helper to create a plain JS object from a Dart map.
JSObject _makeJsObject(Map<String, JSAny?> properties) {
  final object = JSObject();
  for (final entry in properties.entries) {
    object[entry.key] = entry.value;
  }
  return object;
}
