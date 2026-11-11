import 'package:apni_factory/main.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/app_state_views.dart';
import 'package:apni_factory/screens/sign_in.dart';
import 'package:apni_factory/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'isLoggedInKey': false});
  });

  testWidgets('MyApp boots safely without Firebase initialization',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        home: SpalshScreen(splashDelay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('AppErrorRetryView renders accessible retry control',
      (WidgetTester tester) async {
    int retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorRetryView(
            title: 'Connection timed out',
            message: 'Unable to load products right now.',
            onRetry: () => retryCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('Connection timed out'), findsOneWidget);
    expect(find.text('Unable to load products right now.'), findsOneWidget);

    final retryButton = find.text('Retry');
    expect(retryButton, findsOneWidget);
    final size = tester.getSize(
      find.ancestor(
        of: retryButton,
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(retryButton);
    await tester.pump();
    expect(retryCount, 1);
  });

  testWidgets('AppEmptyStateView renders title, subtitle, and optional action',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyStateView(
            title: 'No matching SKUs',
            subtitle: 'Try clearing your filter selection.',
            action: OutlinedButton(
              onPressed: () {},
              child: const Text('Reset Filters'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('No matching SKUs'), findsOneWidget);
    expect(find.text('Try clearing your filter selection.'), findsOneWidget);
    expect(find.text('Reset Filters'), findsOneWidget);
  });

  testWidgets('AppNetworkImage gracefully renders fallback on invalid URL',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppNetworkImage(
            imageUrl: '',
            width: 64,
            height: 64,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}
