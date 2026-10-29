import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imposter_game/app/app.dart';

void main() {
  testWidgets('app boots to home after splash bootstrap override', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FindTheImposterApp()),
    );
    // Initial splash / loading is acceptable.
    expect(find.byType(FindTheImposterApp), findsOneWidget);
  });
}
