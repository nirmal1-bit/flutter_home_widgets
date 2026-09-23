import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_testing/main.dart';

void main() {
  testWidgets('flashcard reveals before the next card', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.text('What is Einstein\'s photoelectric equation?'),
      findsOneWidget,
    );
    expect(find.text('Reveal answer'), findsOneWidget);

    await tester.tap(find.text('Reveal answer'));
    await tester.pump();
    expect(find.textContaining('Kₘₐₓ = hf'), findsOneWidget);

    await tester.tap(find.text('Next card'));
    await tester.pump();
    expect(find.text('What is the threshold frequency?'), findsOneWidget);
  });
}
