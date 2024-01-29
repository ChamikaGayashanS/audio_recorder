// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:audio_player/helpers/helperFunctions.dart';
import 'package:audio_player/pages/recorder_controller.dart';
import 'package:audio_player/widgets/rounded_buton.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
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
  late final RecorderController recorderController;
  late final PlayerController playerController;

  bool recording = false;
  bool playing = false;
  Record recorder = Record();
  AudioPlayer audioPlayer = AudioPlayer();
  String recorderPath = '';
  Duration duration = const Duration();
  String selectedAudio = '';
  List<String> audioPaths = [];
  List<String> selectedPaths = [];

  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    getDirectory();
    _initialiseControllers();
  }

  Future getDirectory() async {
    Directory appDirectory = await getTemporaryDirectory();
    isLoading = false;
    setState(() {});
    return appDirectory.path;
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 128000;

    playerController = PlayerController();
  }

  startRecorder() async {
    // await getDirectory().then((path) async {
    //   String key = UniqueKey().toString();
    //   recorderPath = '$path/recording$key.wav';
    //   if (await recorder.hasPermission()) {
    //     setState(() {
    //       recording = true;
    //     });
    //     await recorder.start(
    //       path: recorderPath,
    //       encoder: AudioEncoder.wav,
    //       bitRate: 128000,
    //     );
    //   }
    // });
    await getDirectory().then((path) async {
      String key = UniqueKey().toString();
      recorderPath = '$path/recording$key.wav';
      try {
        if (recording) {
          recorderController.reset();

          recorderPath = (await recorderController.stop(false))!;
          audioPaths.add(recorderPath);
          await initializeAudioPlayer(path: recorderPath);

          if (recorderPath != null) {
            isRecordingCompleted = true;
            debugPrint(recorderPath);
            debugPrint(
                "Recorded file size: ${File(recorderPath).lengthSync()}");
          }
        } else {
          await recorderController.record(path: recorderPath);
        }
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        setState(() {
          recording = !recording;
        });
      }
    });
  }

  stopRecorder() async {
    await recorder.stop();
    audioPaths.add(recorderPath);
    await initializeAudioPlayer(path: recorderPath);
    setState(() {
      recording = false;
    });
  }

  initializeAudioPlayer({required String path}) async {
    selectedAudio = path;
    // await audioPlayer.setLoopMode(LoopMode.all);
    // await audioPlayer.setAudioSource(AudioSource.file(path));
    // Duration _duration = await audioPlayer.load() ?? const Duration();
    // duration = _duration;

    // setState(() {});

    playerController.preparePlayer(path: path);
  }

  playPauseAudio() async {
    if (playing) {
      playing = false;
      setState(() {});
      await playerController.pausePlayer(); // Pause audio player
    } else {
      playing = true;
      setState(() {});
      await playerController.startPlayer(
          finishMode: FinishMode.loop); // Start audio player
    }
  }

  Future<String> trimAudioFile(
      {required String inputFile,
      required double startTime,
      required double endTime}) async {
    try {
      String key = UniqueKey().toString();
      String outputPath =
          await getDirectory().then((path) => '$path/trim_audio$key.wav');

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
      String key = UniqueKey().toString();
      String outputPath = await getDirectory()
          .then((path) => '$path/concatenate_audio$key.wav');

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
    recorderController.dispose();
    super.dispose();
    clearTempDirectories();
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
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
                    await audioPlayer.stop();
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
              selectedAudio.isNotEmpty
                  ? Text(
                      selectedAudio.split('/').last,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w400),
                    )
                  : const SizedBox(),
              Row(
                children: [
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: recording
                          ? AudioWaveforms(
                              enableGesture: true,
                              size: Size(
                                  MediaQuery.of(context).size.width / 1.5, 80),
                              recorderController: recorderController,
                              shouldCalculateScrolledPosition: true,
                              waveStyle: const WaveStyle(
                                waveColor: Colors.green,
                                showDurationLabel: true,
                                spacing: 8.0,
                                showBottom: true,
                                extendWaveform: true,
                                showMiddleLine: false,
                                // gradient: ui.Gradient.linear(
                                //   const Offset(70, 50),
                                //   Offset(
                                //       MediaQuery.of(context).size.width / 2, 0),
                                //   [Colors.red, Colors.green],
                                // ),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: const Color(0xFF1E1B26),
                              ),
                              padding: const EdgeInsets.only(left: 18),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                            )
                          : playing
                              ? AudioFileWaveforms(
                                  size: Size(
                                      MediaQuery.of(context).size.width, 100.0),
                                  playerController: playerController,
                                )
                              // ? AudioFileWaveforms(
                              //     size: Size(
                              //         MediaQuery.of(context).size.width, 80.0),
                              //     playerController: playerController,
                              //     enableSeekGesture: true,
                              //     waveformType: WaveformType.long,
                              //     waveformData: [],
                              //     playerWaveStyle: const PlayerWaveStyle(
                              //       fixedWaveColor: Colors.green,
                              //       liveWaveColor: Colors.red,
                              //       spacing: 6,
                              //     ),
                              //     backgroundColor: Colors.black,
                              //   )
                              : Container())
                  //       : Container(
                  //           width: MediaQuery.of(context).size.width / 1.7,
                  //           height: 50,
                  //           decoration: BoxDecoration(
                  //             color: const Color(0xFF1E1B26),
                  //             borderRadius: BorderRadius.circular(12.0),
                  //           ),
                  //           padding: const EdgeInsets.only(left: 18),
                  //           margin: const EdgeInsets.symmetric(horizontal: 15),
                  //           child: TextField(
                  //             readOnly: true,
                  //             decoration: InputDecoration(
                  //               hintText: "Type Something...",
                  //               hintStyle:
                  //                   const TextStyle(color: Colors.white54),
                  //               contentPadding: const EdgeInsets.only(top: 16),
                  //               border: InputBorder.none,
                  //               suffixIcon: IconButton(
                  //                 onPressed: () {},
                  //                 // _pickFile,
                  //                 icon: Icon(Icons.adaptive.share),
                  //                 color: Colors.white54,
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  // ),
                  // IconButton(
                  //   onPressed: _refreshWave,
                  //   icon: Icon(
                  //     isRecording ? Icons.refresh : Icons.send,
                  //     color: Colors.white,
                  //   ),
                  // ),
                  // const SizedBox(width: 16),
                  // IconButton(
                  //   onPressed: () {},
                  //   // _startOrStopRecording,
                  //   icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  //   color: Colors.white,
                  //   iconSize: 28,
                  // ),
                ],
              ),
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
                        startRecorder();
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
                                      'Duration in Second ${duration.inSeconds.toString()}',
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
