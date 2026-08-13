import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Which haptic pattern to use on a qualifying short tap.
enum PadHaptic {
  none,
  dpad,
  confirm,
  cancel,
  shift,
  custom,
}

/// Short tap = haptic; long press (skip, dash, walk) = silent.
abstract final class PadHapticPolicy {
  static const shortTapMax = Duration(milliseconds: 220);
}

/// D-pad short tap sends a fixed-length key pulse for one grid step.
abstract final class PadStepPolicy {
  static const holdThreshold = PadHapticPolicy.shortTapMax;
  /// Short pulse for 1-tile steps (常時ダッシュ作品でも行き過ぎを抑える).
  static const pulseDuration = Duration(milliseconds: 42);
}

Future<void> triggerPadHaptic(PadHaptic type, {required bool enabled}) async {
  if (!enabled || type == PadHaptic.none) {
    return;
  }

  if (!kIsWeb && Platform.isAndroid) {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final duration = switch (type) {
        PadHaptic.dpad => 14,
        PadHaptic.confirm => 22,
        PadHaptic.cancel => 38,
        PadHaptic.shift => 22,
        PadHaptic.custom => 30,
        PadHaptic.none => 0,
      };
      if (duration <= 0) {
        return;
      }

      final amplitude = switch (type) {
        PadHaptic.dpad => 64,
        PadHaptic.confirm => 96,
        PadHaptic.cancel => 180,
        PadHaptic.shift => 96,
        PadHaptic.custom => 128,
        PadHaptic.none => 0,
      };

      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(duration: duration, amplitude: amplitude);
      } else {
        await Vibration.vibrate(duration: duration);
      }
      return;
    }
  }

  switch (type) {
    case PadHaptic.dpad:
      await HapticFeedback.selectionClick();
    case PadHaptic.confirm:
    case PadHaptic.shift:
      await HapticFeedback.mediumImpact();
    case PadHaptic.cancel:
    case PadHaptic.custom:
      await HapticFeedback.heavyImpact();
    case PadHaptic.none:
      break;
  }
}

/// Layout spacing tuned for one-hand / blind touch.
abstract final class PadLayout {
  static const actionGap = 16.0;
  static const rowGap = 16.0;
  static const dpadArmGap = 12.0;
  static const dpadBandGap = 4.0;
  /// Visible arm size within expanded hit area (cross look).
  static const dpadVisualArmWidthFactor = 0.34;
  static const dpadVisualSideWidthFactor = 0.92;
  static const panelPadding = 14.0;
  static const padZonesGap = 20.0;
  /// Phone / folded-foldable design width; larger screens letterbox instead of stretch.
  static const maxContentWidth = 480.0;
}
