// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:audio_player/helpers/helperFunctions.dart';
import 'package:audio_player/pages/recorder_controller.dart';
import 'package:audio_player/widgets/rounded_buton.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

class RecorderPage extends ConsumerStatefulWidget {
  const RecorderPage({super.key});

  @override
  ConsumerState<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends ConsumerState<RecorderPage> {
  bool recording = false;
  bool playing = false;
  Record recorder = Record();
  AudioPlayer audioPlayer = AudioPlayer();
  String recorderPath = '';
  int duration = 0;
  String selectedAudio = '';
  List<String> audioPaths = [];
  List<String> selectedPaths = [];

  late RecorderController recorderController;
  late PlayerController playerController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initRecorder();
  }

  initRecorder() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }

  Future getDirectory() async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    // Directory appDirectory = await getApplicationDocumentsDirectory();
    return appDirectory.path;
  }

  startRecorder() async {
    await getDirectory().then((path) async {
      String key = DateTime.now().toString();
      print(path);
      recorderPath = '$path/recording$key';
      if (await recorder.hasPermission()) {
        setState(() {
          recording = true;
        });
        await recorderController.record(path: recorderPath);

        // await recorder.start(
        //   path: recorderPath,
        //   encoder: AudioEncoder.wav,
        //   bitRate: 32000,
        // );
      }
    });
  }

  stopRecorder() async {
    final path = await recorderController.stop();
    // await recorder.stop();
    audioPaths.add(path!);
    await initializeAudioPlayer(path: path);
    setState(() {
      recording = false;
    });
  }

  initializeAudioPlayer({required String path}) async {
    try {
      selectedAudio = path;
      playerController = PlayerController();
      playerController.preparePlayer(path: path);
      final _duration = await playerController.getDuration();
      duration = _duration;

      // selectedAudio = await getIosDevicePath(path);
      // await audioPlayer.setLoopMode(LoopMode.all);
      // await audioPlayer.setFilePath(File(path).path);
      // // audioPlayer = AudioPlayer()..setAsset('assets/audio.wav');
      // await audioPlayer.setAudioSource(AudioSource.file(path));
      // Duration _duration = await audioPlayer.load() ?? const Duration();
      // duration = _duration;

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  getIosDevicePath(String path) async {
    // if (Platform.isIOS) {
    var file = File(path);

    Uint8List bytes = file.readAsBytesSync();

    var buffer = bytes.buffer;

    var unit8 = buffer.asUint8List(32, bytes.lengthInBytes - 32);
    Directory dir = await getApplicationDocumentsDirectory();

    var tmpFile = "${dir.path}/tmp.mp3";
    File(tmpFile).writeAsBytesSync(unit8);
    return tmpFile;
    // }
    // return path;
  }

  playPauseAudio() async {
    if (playing) {
      playing = false;
      setState(() {});
      playerController.pausePlayer();
      // await audioPlayer.pause();
    } else {
      playing = true;
      setState(() {});
      playerController.startPlayer(finishMode: FinishMode.loop);
      // await audioPlayer.play();
    }
  }

  Future<String> trimAudioFile(
      {required String inputFile,
      required double startTime,
      required double endTime}) async {
    try {
      String key = DateTime.now().toString();

      String outputPath =
          await getDirectory().then((path) => '$path/trim_audio$key');

      double trimDuration = endTime - startTime;
      String command =
          "-i $inputFile -ss $startTime -t $trimDuration -c copy $outputPath";

      FFmpegSession session = await FFmpegKit.execute(command);
      print("Audio trimmed successfully! ${session..getAllLogs()}");
      audioPaths.add(outputPath);
      setState(() {});
      return outputPath;
    } catch (e) {
      print("Error trimming audio : $e");
      return '';
    }
  }

  Future<String> concatenateAudioFile() async {
    try {
      String key = DateTime.now().toString();

      String outputPath =
          await getDirectory().then((path) => '$path/concatenate_audio$key');

      String command =
          '-i ${selectedPaths[0]} -i ${selectedPaths[1]} -filter_complex "[0:0][1:0]concat=n=2:v=0:a=1[out]" -map "[out]" $outputPath';

      FFmpegSession session = await FFmpegKit.execute(command);
      print("Audio concatenate successfully! ${session..getAllLogs()}");
      audioPaths.add(outputPath);
      selectedPaths.clear();
      setState(() {});
      return outputPath;
    } catch (e) {
      print("Error concatenate audio : $e");
      return '';
    }
  }

  clearTempDirectories() async {
    Directory dir = await getTemporaryDirectory();
    dir.deleteSync(recursive: true);
    print('Cleaned all directories');
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    clearTempDirectories();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(recorderPageControllerProvider);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
            child: Column(
              children: audioPaths.map((e) {
                return GestureDetector(
                  onDoubleTap: () {
                    audioPaths.remove(e);
                    setState(() {});
                  },
                  onTap: () async {
                    playing = false;
                    // await audioPlayer.stop();
                    setState(() {});
                    initializeAudioPlayer(path: e);
                  },
                  onLongPress: () {
                    if (selectedPaths.contains(e)) {
                      selectedPaths.remove(e);
                    } else {
                      if (selectedPaths.length < 2) {
                        selectedPaths.add(e);
                      }
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 100.w,
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                    decoration: BoxDecoration(
                        color: selectedPaths.contains(e)
                            ? Colors.blueAccent[100]
                            : Colors.amber[50],
                        border: const Border(
                            bottom: BorderSide(color: Colors.black38))),
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
            ),
          )),
          Column(
            children: [
              AudioWaveforms(
                size: const Size(double.infinity, 80.0),
                recorderController: recorderController,
              ),
              selectedAudio.isNotEmpty
                  ? Text(
                      selectedAudio.split('/').last,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w400),
                    )
                  : const SizedBox(),
              Container(
                height: 92,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 255, 245, 211)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundedButton(
                      radius: 62,
                      icon: Icon(recording ? Icons.stop : Icons.mic,
                          color: Colors.white),
                      backgroundColor: Colors.red,
                      borderColors: Colors.black45,
                      onTap: () async {
                        if (recording) {
                          await stopRecorder();
                        } else {
                          await startRecorder();
                        }
                      },
                    ),
                    const Gap(40),
                    RoundedButton(
                      radius: 50,
                      label: 'Trim',
                      icon:
                          const Icon(Icons.track_changes, color: Colors.white),
                      backgroundColor: Colors.red,
                      borderColors: Colors.black45,
                      onTap: () async {
                        await showDialog<void>(
                          context: context,
                          barrierDismissible: false, // user must tap button!
                          builder: (BuildContext context) {
                            TextEditingController startController =
                                TextEditingController();
                            TextEditingController endController =
                                TextEditingController();
                            return AlertDialog(
                              title: const Text('Trim Audio Duration'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    Text(
                                      'Duration in Second ${duration.toString()}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const Gap(10),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: startController,
                                      decoration: const InputDecoration(
                                          label: Text('Start Time'),
                                          border: OutlineInputBorder()),
                                    ),
                                    const Gap(10),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      controller: endController,
                                      decoration: const InputDecoration(
                                          label: Text('End Time'),
                                          border: OutlineInputBorder()),
                                    ),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Trim Audio'),
                                  onPressed: () async {
                                    if (startController.text.isNotEmpty &&
                                        endController.text.isNotEmpty) {
                                      String trimAudioFilePath =
                                          await trimAudioFile(
                                              inputFile: selectedAudio,
                                              startTime: 2,
                                              endTime: 8);

                                      if (trimAudioFilePath.isNotEmpty) {
                                        initializeAudioPlayer(
                                            path: trimAudioFilePath);
                                      }
                                    }
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const Gap(40),
                    ((recorderPath.isNotEmpty) && (!recording))
                        ? RoundedButton(
                            label: playing ? 'Pause' : 'Play',
                            radius: 50,
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            backgroundColor: Colors.red,
                            borderColors: Colors.black45,
                            onTap: () => playPauseAudio(),
                          )
                        : const Gap(50),
                    const Gap(40),
                    ((selectedPaths.length == 2))
                        ? RoundedButton(
                            label: 'Concatenate',
                            radius: 50,
                            icon: const Icon(Icons.join_full_outlined,
                                color: Colors.white),
                            backgroundColor: Colors.red,
                            borderColors: Colors.black45,
                            onTap: () => concatenateAudioFile(),
                          )
                        : const Gap(50)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
