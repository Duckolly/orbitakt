import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dvizh/screens/reports_screen.dart';
import 'package:dvizh/services/progress_reports.dart';
import 'package:dvizh/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUpAll(() async {
    sqfliteFfiInit();databaseFactory=databaseFactoryFfi;
    dir=await Directory.systemTemp.createTemp('orbitakt-audit-');
    await databaseFactory.setDatabasesPath(dir.path);
  });
  setUp(() async {SharedPreferences.setMockInitialValues({});await StorageService.database;});
  tearDown(() async {await StorageService.deleteAllData();});
  tearDownAll(() async {await dir.delete(recursive:true);});
  testWidgets('AUDIT: selected historical year invalid after its history disappears', (tester) async {
    final now=DateTime.now();final old=now.year-1;
    var rows=<Object>[{'day':'$old-12-31','steps':10000,'estimated':false}];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      ProgressReports.channel,(call)async=>{'steps':rows,'water':<Object>[]});
    Future<void> settle()async{
      await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:200)));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const MaterialApp(home:ReportsScreen()));
    for(var i=0;i<15 && find.text('0 стаканов').evaluate().isEmpty;i++){await settle();}
    await tester.tap(find.text('${now.year} год'));await tester.pumpAndSettle();
    await tester.tap(find.text('$old год').last);await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    rows=<Object>[];
    await tester.tap(find.byTooltip('Обновить отчёт'));await settle();
    final error=tester.takeException();
    expect(error,isNotNull);
    expect(error.toString(),contains('DropdownButton'));
    print('AUDIT REPRO CONFIRMED: history disappears while the deleted year remains selected.');
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
}
