import 'dart:io';
import 'package:path/path.dart' as pathHelper;

import 'package:args/args.dart';
import 'package:auto_core/auto_core.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();
  parser.addOption('auto',
      abbr: 'a', help: 'Path of auto file', valueHelp: 'test/test.auto');
  parser.addOption('out',
      abbr: 'o', help: 'The output path', valueHelp: 'test/test.autor');
  parser.addOption('host', abbr: 'h', help: 'Host', valueHelp: '127.0.0.1');
  parser.addOption('port',
      abbr: 'p', help: 'Port', valueHelp: '7001', defaultsTo: '7001');


  parser.addOption('android-package',
      help: 'Android package', valueHelp: 'com.example.auto');

  parser.addFlag('android-restart',
      help: 'Restart the application before playback (Need adb)',
      defaultsTo: false);

  parser.addOption('android-serialno',
      help: 'Use device with given serial', valueHelp: 'emulator-5554');

  parser.addFlag('force',
      abbr: 'f', help: 'Force start playback', defaultsTo: false);

  parser.addOption('threshold',
      abbr: 't',
      help: 'Image matching threshold',
      valueHelp: '0.8',
      defaultsTo: '0.8');

  parser.addFlag('help', hide: true, negatable: false);
  final result = parser.parse(arguments);


  if (result.wasParsed('help')||result.arguments.isEmpty) {
    stdout.writeln("exitCode: 0(OK) 2(ERROR)\n${parser.usage}");
    exit(0);
  }

  return _handle(await resolve(result));
}

Future<Args> resolve(ArgResults results) async {
  T? get<T>(String name) {
    if(results[name]!=null){
      return results[name] as T;
    } else {
      return null;
    }
  }

  String? auto = get<String>('auto');
  String? out = get<String>('out');
  String? host = get<String>('host');
  int port = int.parse(get<String>('port')!);
  String? androidPackage = get<String?>('android-package');
  String? androidSerialno = get<String?>('android-serialno');
  bool androidRestart = get<bool>('android-restart')!;
  bool force = get<bool>('force')!;
  double threshold = double.parse(get<String>('threshold')!);

  if (auto == null) {
    stderr.writeln('error: the parameter auto is not specified');
    exit(2);
  }

  if (!File(auto).existsSync()) {
    stderr.writeln('$auto not found');
    exit(2);
  }

  if (host == null) {
    stderr.writeln('error: the parameter host is not specified');
    exit(2);
  }

  if ( androidRestart) {
    await _checkCommand(adb);

    if (androidPackage == null) {
      stderr.writeln('error: the parameter androidPackage is not specified');
      exit(2);
    }

    final devices = await AndroidUtil.listAllDevices(cmd: adb);
    if (androidSerialno == null) {
      if (devices.length > 1) {
        stderr.writeln('error: more than one device/emulator.\nPlease specify the android-serialno parameter\n${devices.join('\n')}');
        exit(2);
      }
    }else{
      if(devices.every((element) => element.serialno!=androidSerialno)){
        stderr.writeln('error: serialno does not match\n${devices.join('\n')}');
        exit(2);
      }
    }

  }

  await _checkCommand(autoUtil,helpText: 'See: https://github.com/auto-flutter/auto_util');

  return Args(
      auto: auto,
      out: out,
      host: host,
      port: port,
      androidPackage: androidPackage,
      androidRestart: androidRestart,
      androidSerialno: androidSerialno,
      force: force,
      threshold: threshold);
}

class Args {
  final String host;
  final int port;
  final String auto;
  final String? out;
  final String? androidPackage;
  final bool androidRestart;
  final String? androidSerialno;
  final bool force;
  final double threshold;

  Args(
      {required this.host,
      required this.port,
      required this.auto,
      this.out,
      this.androidPackage,
      required this.androidRestart,
      this.androidSerialno,
      required this.force,
      required this.threshold});
}

const String adb = 'adb';
const String autoUtil = 'auto_util';

void _handle(Args args) async {
  if(args.androidRestart){
    final result = await AndroidUtil.restartApp(
        package: args.androidPackage!, serialno: args.androidSerialno!, cmd: adb);
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      stdout.writeln(result.stdout);
      exit(2);
    }
  }


  final app = RemoteApp(host: args.host, port: args.port);
  final requestResult =
      await app.replayWithTarFile(args.auto, force: args.force);
  if (!requestResult.ok) {
    stderr.writeln(requestResult.error);
    exit(2);
  }

  final autoScript = await AutoScript.load(args.auto);
  final report = await MatchUtil.match(autoScript, requestResult.result!,threshold: args.threshold);

  if (args.out == null) {
    final savePath = pathHelper.setExtension(args.auto, '.autor');
    await report.save(savePath);
  } else {
    await report.save(args.out!);
  }

  if(!report.basicInfo.ok){
    stderr.writeln('Match failed');
    exit(2);
  }else{
    exit(0);
  }
}

Future<void> _checkCommand(String command,{String? helpText}) async {
  final exist = await CommandUtil.checkCommandIsExist(command);
  if (!exist) {
    stderr.writeln('$command command not found ${helpText??''}');
    exit(2);
  }
}
