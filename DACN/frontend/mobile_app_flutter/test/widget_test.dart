import 'package:flutter_test/flutter_test.dart';
import 'package:hcmc_uhi/main.dart';

void main() {
  testWidgets('App title is HCMC UHI', (tester) async {
    await tester.pumpWidget(const HcmcUhiApp());
    expect(find.textContaining('HCMC'), findsWidgets);
  });
}
