import 'dart:io';

Future<void> main() async {
  final project = File('ios/Runner.xcodeproj/project.pbxproj');
  final original = await project.readAsString();
  if (!original.contains('ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')) {
    throw StateError('Configure the AppIcon catalog before generating icons.');
  }

  try {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'flutter_launcher_icons',
      '-f',
      'pubspec.yaml',
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exitCode = result.exitCode;
  } finally {
    // Version 0.14.4 rewrites unrelated ASSETCATALOG settings. AppIcon is
    // already selected, so only the generated image assets need to change.
    if (await project.readAsString() != original) {
      await project.writeAsString(original);
    }
  }
}
