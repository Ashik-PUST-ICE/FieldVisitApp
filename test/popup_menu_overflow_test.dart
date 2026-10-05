import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the "Start Visit" 3-dot menu overflow.
///
/// `PopupMenuButton` forwards its `constraints` straight into the popup MENU
/// route (see `showButtonMenu` in material/popup_menu.dart:
/// `constraints: widget.constraints`). Passing
/// `BoxConstraints.tightFor(width: 36)` therefore collapsed the whole menu to
/// 36px, leaving `36 - 24` = 12px for each item's Row, which overflowed by
/// 83-135px on the real device (see flutter-run.log).
///
/// The fix (a) sizes the button tap target with `IconButton.styleFrom`, and
/// (b) gives the menu itself generous `minWidth`/`maxWidth` instead of a tight
/// fixed width.
void main() {
  const items = <PopupMenuEntry<String>>[
    PopupMenuItem(
      value: 'take_order',
      child: Row(
        children: [
          Icon(Icons.add_shopping_cart_rounded, size: 18),
          SizedBox(width: 8),
          Text('Book / Take Order'),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'products',
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 18),
          SizedBox(width: 8),
          Text('Visit Products'),
        ],
      ),
    ),
  ];

  /// Mirrors the shipped widget in visits_screen.dart.
  Widget buildSubject({BoxConstraints? constraints, ButtonStyle? style}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              constraints: constraints,
              style: style,
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (_) {},
              itemBuilder: (_) => items,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'production 3-dot menu opens with no overflow and full-width labels',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 400),
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        maximumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'menu must open without overflow');
    expect(find.text('Book / Take Order'), findsOneWidget);
    expect(find.text('Visit Products'), findsOneWidget);

    // The menu must be wide enough to actually render the labels.
    final menuWidth =
        tester.getSize(find.byType(PopupMenuItem<String>).first).width;
    expect(menuWidth, greaterThanOrEqualTo(200),
        reason: 'menu collapsed - labels would be clipped');

    // Labels must not be squeezed/clipped.
    expect(
        tester.getSize(find.text('Book / Take Order')).width, greaterThan(100));
  });

  testWidgets('regression: tightFor(width:36) collapses the menu and overflows',
      (WidgetTester tester) async {
    // This is the exact code that shipped before the fix.
    await tester.pumpWidget(buildSubject(
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    ));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // ...which is what threw the RenderFlex overflow in flutter-run.log.
    // Capture the exception FIRST: a RenderFlex overflow is recorded as a
    // FlutterError, and calling getSize() on the collapsed item afterwards
    // would itself throw and mask the real assertion.
    expect(tester.takeException(), isNotNull,
        reason: 'the original bug must still be observable');

    // Menu collapsed to the button's 36px.
    expect(
        tester.getSize(find.byType(PopupMenuItem<String>).first).width, 36.0);
  });
}
