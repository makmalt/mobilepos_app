import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobilepos_app/scanbarcode/scanbarcode.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<MobileScannerController>(),
  MockSpec<NavigatorObserver>(),
])
import 'scanbarcode_test.mocks.dart';

void main() {
  late MockMobileScannerController mockScannerController;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockScannerController = MockMobileScannerController();
    mockNavigatorObserver = MockNavigatorObserver();

    // Setup NavigatorObserver mock
    when(mockNavigatorObserver.navigator).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scanbarcode(),
      navigatorObservers: [mockNavigatorObserver],
    );
  }

  testWidgets('processBarcode test', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    reset(mockNavigatorObserver); // Reset after initial push

    final state = tester.state<ScanbarcodeState>(find.byType(Scanbarcode));

    // Test initial state
    expect(state.isProcessing, false);

    // Process barcode
    state.processBarcode('123456');
    await tester.pump();

    // Verify state changes
    expect(state.isProcessing, true);
    // Verify navigation was attempted
    verify(mockNavigatorObserver.didPush(any, any)).called(1);
  });

  testWidgets('processBarcode sedang memproses', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    reset(mockNavigatorObserver); // Reset after initial push

    final state = tester.state<ScanbarcodeState>(find.byType(Scanbarcode));

    // First barcode processing
    print("sedang memproses");
    state.processBarcode('123456');
    await tester.pump();

    // Verify isProcessing is true
    expect(state.isProcessing, true);
    
    // Try to process another barcode while still processing
    state.processBarcode('789012');
    await tester.pump();

    // Verify isProcessing is still true
    expect(state.isProcessing, true);

    // Verify only one navigation attempt was made
    verify(mockNavigatorObserver.didPush(any, any)).called(1);
  });
}
