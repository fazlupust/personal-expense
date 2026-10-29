import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_expense/app/core/localization/app_translations.dart';
import 'package:personal_expense/app/core/theme/app_theme.dart';
import 'package:personal_expense/app/features/categories/controllers/categories_controller.dart';
import 'package:personal_expense/app/features/dashboard/views/components/balance_card.dart';
import 'package:personal_expense/app/features/navigation/controllers/navigation_controller.dart';
import 'package:personal_expense/app/features/navigation/views/navigation_view.dart';
import 'package:personal_expense/app/features/notes/controllers/notes_controller.dart';
import 'package:personal_expense/app/features/reports/controllers/reports_controller.dart';
import 'package:personal_expense/app/features/settings/controllers/settings_controller.dart';
import 'package:personal_expense/app/features/transactions/controllers/transactions_controller.dart';
import 'package:personal_expense/app/features/transactions/views/components/entry_form_sheet.dart';
import 'package:personal_expense/app/features/settings/views/components/budget_management_sheet.dart';
import 'package:personal_expense/app/features/settings/views/components/edit_profile_sheet.dart';
import 'package:personal_expense/app/features/notes/views/components/note_form_sheet.dart';
import 'package:personal_expense/app/features/notes/views/notes_view.dart';
import 'package:personal_expense/app/data/models/note_model.dart';
import 'package:personal_expense/app/features/reports/views/generate_report_view.dart';
import 'package:personal_expense/app/features/settings/views/components/data_export_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeDateFormatting('bn', null);
    await initializeDateFormatting('en', null);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Get.reset();
    Get.put<SharedPreferences>(prefs);
    Get.put<SettingsController>(SettingsController(prefs));
    Get.put<TransactionsController>(TransactionsController());
    Get.put<CategoriesController>(CategoriesController());
    Get.put<NavigationController>(NavigationController());
    Get.put<NotesController>(NotesController());
    Get.put<ReportsController>(ReportsController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Samsung Galaxy A15 screen simulation - No RenderFlex overflows', (tester) async {
    // Samsung Galaxy A15 specs: 1080 x 2340 px, ~2.625 DPR -> ~411.4 x 891.4 logical dp
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const NavigationView(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Dashboard should render without exceptions on Samsung A15');

    // Verify BalanceCard renders properly
    expect(find.byType(BalanceCard), findsOneWidget);

    // Switch to Transactions tab (index 1)
    Get.find<NavigationController>().select(1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Transactions tab should render without exceptions on Samsung A15');

    // Switch to Reports tab (index 2)
    Get.find<NavigationController>().select(2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Reports tab should render without exceptions on Samsung A15');

    // Switch to Profile tab (index 3)
    Get.find<NavigationController>().select(3);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Profile tab should render without exceptions on Samsung A15');
  });

  testWidgets('Samsung Galaxy A15 compact mode (360x800) simulation - No RenderFlex overflows', (tester) async {
    // High-density compact simulation: 360 x 800 logical dp
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0; // 360 x 800 dp
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const NavigationView(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Dashboard should render cleanly on 360x800 dp');
  });

  testWidgets('Samsung Galaxy A15 Bottom Sheets & Buttons render cleanly without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showEntrySheet(context),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open EntryFormSheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'EntryFormSheet should render without overflow on Samsung A15');

    // Verify Submit & Cancel buttons are present and visible
    expect(find.text('Submit'.tr), findsOneWidget);
    expect(find.text('Cancel'.tr), findsOneWidget);

    // Close sheet
    Get.back();
    await tester.pumpAndSettle();
  });

  testWidgets('Samsung Galaxy A15 BudgetManagementSheet renders cleanly with Save Budgets button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const Scaffold(
          body: BudgetManagementSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'BudgetManagementSheet should render without overflow');
    expect(find.text('Save Budgets'.tr), findsOneWidget);
  });

  testWidgets('Samsung Galaxy A15 EditProfileSheet renders cleanly with Update Profile button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const Scaffold(
          body: EditProfileSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final exc = tester.takeException();
    if (exc != null) {
      if (exc is FlutterError) {
        for (final d in exc.diagnostics) {
          debugPrint('NODE: ${d.toString()}');
        }
      } else {
        debugPrint('EXCEPTION: $exc');
      }
    }
    expect(exc, isNull, reason: 'EditProfileSheet should render without overflow');
    expect(find.text('Update Profile'.tr), findsOneWidget);
  });

  testWidgets('Samsung Galaxy A15 NoteFormSheet renders cleanly with Submit & Cancel buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const Scaffold(
          body: NoteFormSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'NoteFormSheet should render without overflow');
    expect(find.text('Submit'.tr), findsOneWidget);
    expect(find.text('Cancel'.tr), findsOneWidget);
  });

  testWidgets('Samsung Galaxy A15 GenerateReportView renders cleanly with reduced padding and zero overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const GenerateReportView(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'GenerateReportView should render cleanly without overflow');
    expect(find.text('Net Saved'.tr), findsOneWidget);
    expect(find.text('Generated Report'.tr), findsOneWidget);
  });

  testWidgets('Samsung Galaxy A15 NotesView renders time, hides GPS coords, and clears search', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final notesCtrl = Get.find<NotesController>();
    notesCtrl.notes = [
      NoteModel(
        id: 'note_1',
        title: 'Office due from Rahim',
        personName: 'Rahim',
        amount: 500.0,
        notes: 'Team snacks money',
        date: DateTime(2026, 10, 27, 14, 30),
        latitude: 23.82,
        longitude: 90.41,
      ),
    ];
    notesCtrl.isLoading = false;
    notesCtrl.update();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const NotesView(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify raw latitude / longitude coordinates are NOT displayed
    expect(find.textContaining('23.82'), findsNothing);
    expect(find.textContaining('90.41'), findsNothing);

    // Verify time is displayed
    expect(find.textContaining('02:30 PM'), findsOneWidget);

    // Type in search box
    await tester.enterText(find.byType(TextField), 'Rahim');
    await tester.pumpAndSettle();

    expect(notesCtrl.searchQuery, 'Rahim');
    expect(notesCtrl.searchCtrl.text, 'Rahim');
    expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(notesCtrl.searchQuery, isEmpty);
    expect(notesCtrl.searchCtrl.text, isEmpty);
    expect(find.byIcon(Icons.clear_rounded), findsNothing);
  });

  testWidgets('Samsung Galaxy A15 DataExportSheet renders cleanly without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const Scaffold(
          body: DataExportSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'DataExportSheet should render cleanly without overflow');
    expect(find.text('Export Data'.tr), findsOneWidget);
    expect(find.text('Transactions (CSV)'.tr), findsOneWidget);

    // Scroll to Backup button, tap it and verify loader spinner renders while generating
    await tester.scrollUntilVisible(
      find.text('Backup'.tr),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Backup'.tr));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets('Samsung Galaxy A15 DataExportSheet multi-tab Excel and tab-switching work cleanly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('bn'),
        theme: AppTheme.light,
        home: const Scaffold(
          body: DataExportSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Tab 0 (All in One) has Multi-Tab Excel Workbook
    expect(find.text('Multi-Tab Excel Workbook (.xlsx)'.tr), findsOneWidget);
    expect(find.text('Share Excel'.tr), findsAtLeastNWidgets(1));

    // Tap Transactions tab chip (by icon to distinguish from summary header)
    await tester.tap(find.byIcon(Icons.table_chart_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Transactions (Excel .xlsx)'.tr), findsOneWidget);

    // Tap Notes & Debts tab chip
    await tester.tap(find.byIcon(Icons.note_alt_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Notes & Debts (Excel .xlsx)'.tr), findsOneWidget);

    // Tap Zikir tab chip
    await tester.ensureVisible(find.byIcon(Icons.fingerprint_rounded).first);
    await tester.tap(find.byIcon(Icons.fingerprint_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Zikir & Tasbih (Excel .xlsx)'.tr), findsOneWidget);

    // Switch back to All in One
    await tester.ensureVisible(find.byIcon(Icons.layers_rounded).first);
    await tester.tap(find.byIcon(Icons.layers_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Multi-Tab Excel Workbook (.xlsx)'.tr), findsOneWidget);

    // Tap Preview Tabs icon
    await tester.tap(find.byTooltip('Preview Tabs'.tr));
    await tester.pumpAndSettle();
    expect(find.text('Worksheet Tabs'.tr), findsOneWidget);
    expect(find.text('Tab 1: Transactions'.tr), findsOneWidget);
    expect(find.text('Tab 2: Notes & Debts'.tr), findsOneWidget);
    expect(find.text('Tab 3: Zikir & Tasbih'.tr), findsOneWidget);
  });
}
