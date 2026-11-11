import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warmte_berekening/main.dart';
import 'package:warmte_berekening/services/calculation_state.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CalculationState(),
        child: const WarmteberekeningApp(),
      ),
    );
    expect(find.text('IEC TR 60890:2022'), findsOneWidget);
  });
}
