import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';

import '../app_logger.dart';

/// Installs mobile Crashlytics handlers for Flutter and platform errors.
Future<void> configureCrashReporting() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'FlutterError fatal capturado',
      error: details.exception,
      stackTrace: details.stack,
    );

    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Error no controlado capturado por PlatformDispatcher',
      error: error,
      stackTrace: stackTrace,
    );

    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);

    return true;
  };

  AppLogger.info('Crashlytics configurado para plataforma móvil');
}

/// Records errors caught by the top-level zone after Flutter has booted.
Future<void> recordFatalZoneError(Object error, StackTrace stackTrace) async {
  AppLogger.error(
    'Error global capturado por runZonedGuarded',
    error: error,
    stackTrace: stackTrace,
  );

  try {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: true,
    );
  } catch (crashlyticsError, crashlyticsStackTrace) {
    AppLogger.error(
      'No fue posible enviar el error global a Crashlytics',
      error: crashlyticsError,
      stackTrace: crashlyticsStackTrace,
    );
  }
}

/// Crashlytics facade for mobile builds.
class CrashService {
  const CrashService();

  Future<void> log(String message) async {
    AppLogger.info('[CrashService] $message');

    await FirebaseCrashlytics.instance.log(message);
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    AppLogger.error(
      reason ?? 'Error no fatal registrado',
      error: error,
      stackTrace: stackTrace,
    );

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    AppLogger.error(
      reason ?? 'Error fatal registrado',
      error: error,
      stackTrace: stackTrace,
    );

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: true,
    );
  }

  Future<void> setUserIdentifier(String userId) async {
    AppLogger.info('[CrashService] Usuario asociado a Crashlytics: $userId');

    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }
