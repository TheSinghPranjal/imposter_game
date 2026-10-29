import 'dart:convert';
import 'dart:io';

import 'package:imposter_game/core/constants/ad_ids.dart';

/// Fails the process when a release build still has sample or placeholder IDs.
///
///   dart run tool/validate_admob.dart --android
///   dart run tool/validate_admob.dart --ios
void main(List<String> args) {
  final android = args.contains('--android');
  final ios = args.contains('--ios');
  if (android == ios) {
    stderr.writeln('Usage: dart run tool/validate_admob.dart --android|--ios');
    exit(64);
  }

  final jsonFile = File('config/admob.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln('error: config/admob.json is missing.');
    exit(1);
  }

  final decoded = jsonDecode(jsonFile.readAsStringSync());
  if (decoded is! Map) {
    stderr.writeln('error: config/admob.json must be a JSON object.');
    exit(1);
  }

  final ids = decoded.map(
    (key, value) => MapEntry(key.toString(), value.toString()),
  );
  final problems = AdIds.problemsFor(ids, ios: ios);

  if (ios) {
    final xcconfig = File('ios/Flutter/AdMob.xcconfig');
    final expected = (ids[AdIds.iosAppIdKey] ?? '').trim();
    final configured = _readIosAppId(xcconfig);
    if (configured != expected) {
      problems.add(
        'ios/Flutter/AdMob.xcconfig has GAD_APPLICATION_IDENTIFIER='
        '$configured but config/admob.json has $expected. '
        'Run: dart run tool/sync_admob.dart',
      );
    }
  }

  if (problems.isNotEmpty) {
    stderr.writeln(
      'error: Release ${android ? 'Android' : 'iOS'} AdMob IDs are still '
      'sample values or placeholders. Edit config/admob.json '
      '(publisher ${AdIds.publisherPrefix}) and, for iOS, run '
      'dart run tool/sync_admob.dart.',
    );
    for (final problem in problems) {
      stderr.writeln('  - $problem');
    }
    exit(1);
  }

  stdout.writeln(
    'AdMob ${android ? 'Android' : 'iOS'} release IDs look valid.',
  );
}

String _readIosAppId(File xcconfig) {
  if (!xcconfig.existsSync()) return '';
  for (final line in xcconfig.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('GAD_APPLICATION_IDENTIFIER=')) {
      return trimmed.substring('GAD_APPLICATION_IDENTIFIER='.length).trim();
    }
  }
  return '';
}
