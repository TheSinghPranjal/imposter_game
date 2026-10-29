import 'dart:convert';
import 'dart:io';

import 'package:imposter_game/core/constants/ad_ids.dart';

/// Copies the iOS AdMob App ID from config/admob.json into the xcconfig that
/// Info.plist reads. Android reads the JSON directly from Gradle.
void main() {
  final jsonFile = File('config/admob.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln(
      'Missing config/admob.json. Run this from the project root.',
    );
    exit(1);
  }

  final decoded = jsonDecode(jsonFile.readAsStringSync());
  if (decoded is! Map) {
    stderr.writeln('config/admob.json must be a JSON object.');
    exit(1);
  }

  final iosAppId = decoded[AdIds.iosAppIdKey]?.toString().trim() ?? '';
  if (iosAppId.isEmpty) {
    stderr.writeln('${AdIds.iosAppIdKey} is missing from config/admob.json.');
    exit(1);
  }

  final xcconfig = File('ios/Flutter/AdMob.xcconfig');
  xcconfig.writeAsStringSync(
    '// Generated from config/admob.json by tool/sync_admob.dart.\n'
    '// Do not edit by hand. Re-run the tool after changing AdMob IDs.\n'
    'GAD_APPLICATION_IDENTIFIER=$iosAppId\n',
  );
  stdout.writeln(
    'Wrote ${xcconfig.path} (GAD_APPLICATION_IDENTIFIER=$iosAppId)',
  );
}
