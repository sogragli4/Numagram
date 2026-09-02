// Copies Isar's native library for the current host platform into the
// project root, where `flutter test` / `dart test` look for it when
// running outside a full app build. Re-run after `flutter pub upgrade`
// touches isar_community_flutter_libs.
import 'dart:io';
import 'dart:isolate';

Future<void> main() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:isar_community_flutter_libs/isar_flutter_libs.dart'),
  );
  if (uri == null) {
    stderr.writeln('Could not resolve isar_community_flutter_libs.');
    exit(1);
  }

  final packageRoot = File.fromUri(uri).parent.parent;

  final String platformDir;
  final String libName;
  if (Platform.isWindows) {
    platformDir = 'windows';
    libName = 'libisar.dll';
  } else if (Platform.isMacOS) {
    platformDir = 'macos';
    libName = 'libisar.dylib';
  } else if (Platform.isLinux) {
    platformDir = 'linux';
    libName = 'libisar.so';
  } else {
    stderr.writeln('Unsupported host platform for Isar test setup.');
    exit(1);
  }

  final source = File('${packageRoot.path}/$platformDir/$libName');
  if (!source.existsSync()) {
    stderr.writeln('Native library not found at ${source.path}');
    exit(1);
  }

  await source.copy(libName);
  // ignore: avoid_print
  print('Copied ${source.path} -> ./$libName');
}
