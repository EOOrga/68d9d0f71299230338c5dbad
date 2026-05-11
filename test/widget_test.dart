import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:garon_denise/models.dart';
import 'package:garon_denise/operations_app.dart';
import 'package:garon_denise/operations_store.dart';

void main() {
  testWidgets('shows the operations dashboard and navigates tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GaronDeniseApp(
        store: MemoryOperationsStore.seeded(),
        screenshotMode: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('GARON DENISE'), findsOneWidget);
    expect(find.text('Operations board'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Procurement and supplies'), findsOneWidget);
    expect(find.text('Cold-chain pallet wrap'), findsOneWidget);
  });

  testWidgets('creates a local operations record', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryOperationsStore(items: const []);

    await tester.pumpWidget(
      GaronDeniseApp(store: store, screenshotMode: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('add-work-item')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
      find.byKey(const ValueKey('title-field')),
      'New warehouse order',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Partner or supplier'),
      'Atlas Wholesale',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Value or quantity'),
      '42 cases',
    );

    await tester.ensureVisible(find.byKey(const ValueKey('save-work-item')));
    await tester.tap(find.byKey(const ValueKey('save-work-item')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final items = await store.loadItems();
    expect(items, hasLength(1));
    expect(items.single.type, WorkType.lead);
    expect(find.text('New warehouse order'), findsOneWidget);
  });
}
