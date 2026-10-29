// Renders the example UI frame by frame (no device, no emulator) and writes
// PNG frames to build/demo_frames plus the screenshots to doc/.
//
//   flutter test tool/demo/generate_demo_test.dart
//   tool/make_gif.sh
//
// Note: this is a Flutter test render of the real widgets with real fonts,
// not a screen recording of a physical device.
// ignore_for_file: avoid_relative_lib_imports
@Tags(<String>['demo'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../example/lib/contacts_demo.dart';
import '../../example/lib/main.dart';

const Size _logical = Size(390, 760);
const double _capture = 2;

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String f) async =>
      ByteData.sublistView(File('tool/fonts/$f').readAsBytesSync());
  final FontLoader roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'));
  await roboto.load();
  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(bytes('MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  final GlobalKey shot = GlobalKey();
  int frame = 0;

  Future<void> capture(WidgetTester tester, {String? path}) async {
    await tester.runAsync(() async {
      final RenderRepaintBoundary b =
          shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image img = await b.toImage(pixelRatio: _capture);
      final ByteData? data =
          await img.toByteData(format: ui.ImageByteFormat.png);
      final String out = path ??
          'build/demo_frames/f${(frame++).toString().padLeft(4, '0')}.png';
      File(out)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> setup(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = _logical;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _loadFonts();
    await tester.pumpWidget(RepaintBoundary(key: shot, child: app));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('demo gif frames', (WidgetTester tester) async {
    if (Directory('build/demo_frames').existsSync()) {
      for (final FileSystemEntity f
          in Directory('build/demo_frames').listSync()) {
        f.deleteSync();
      }
    }
    await setup(tester, const ExampleApp());
    Finder bar(String l) =>
        find.descendant(of: find.byType(AzIndexBar), matching: find.text(l));
    final double x = tester.getCenter(bar('A')).dx;
    final double yA = tester.getCenter(bar('A')).dy;
    final double yM = tester.getCenter(bar('M')).dy;
    final double yT = tester.getCenter(bar('T')).dy;

    Future<void> tick() async {
      await tester.pump(const Duration(milliseconds: 66));
      await capture(tester);
    }

    for (int i = 0; i < 8; i++) {
      await tick();
    }
    final TestGesture g = await tester.startGesture(Offset(x, yA));
    await tick();
    Future<void> glide(double from, double to, int steps) async {
      for (int i = 1; i <= steps; i++) {
        final double t = Curves.easeInOut.transform(i / steps);
        await g.moveTo(Offset(x, from + (to - from) * t));
        await tick();
      }
    }

    await glide(yA, yM, 28);
    for (int i = 0; i < 8; i++) {
      await tick();
    }
    await glide(yM, yT, 16);
    for (int i = 0; i < 8; i++) {
      await tick();
    }
    await glide(yT, yA, 24);
    await tick();
    await g.up();
    for (int i = 0; i < 8; i++) {
      await tick();
    }
    // ignore: avoid_print
    print('frames: $frame');
  }, tags: 'demo');

  testWidgets('screenshots', (WidgetTester tester) async {
    for (final Brightness br in Brightness.values) {
      final bool dark = br == Brightness.dark;
      final AzSectionedListController c = AzSectionedListController();
      addTearDown(c.dispose);
      final Color seed =
          dark ? const Color(0xFFE91E63) : const Color(0xFF3F51B5);
      await setup(
        tester,
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              colorSchemeSeed: seed, brightness: br, useMaterial3: true),
          home: Scaffold(
            appBar: AppBar(title: const Text('Contacts')),
            body: ContactsDemo(
              controller: c,
              theme: dark
                  ? AzIndexBarThemeData(
                      backgroundColor: seed.withValues(alpha: 0.18),
                      bubbleShape: const CircleBorder(),
                      bubbleSize: 64,
                    )
                  : null,
            ),
          ),
        ),
      );
      Finder bar(String l) =>
          find.descendant(of: find.byType(AzIndexBar), matching: find.text(l));
      final double x = tester.getCenter(bar('A')).dx;
      final TestGesture g =
          await tester.startGesture(Offset(x, tester.getCenter(bar('A')).dy));
      await g.moveTo(Offset(x, tester.getCenter(bar(dark ? 'S' : 'M')).dy));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await capture(tester,
          path: 'doc/screenshot_${dark ? 'dark' : 'light'}.png');
      await g.up();
      await tester.pump();
    }
  }, tags: 'demo');
}
