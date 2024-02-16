import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';

import 'package:path_provider/path_provider.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  bool recording = false;
  late RecorderController recorderController;
  String path = '';
  AudioPlayer audioPlayer = AudioPlayer();
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;

  @override
  void initState() {
    getSavedpaths();
    initRecorder();
  }

  getSavedpaths() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/recording.m4a";
    isLoading = false;
    setState(() {});
  }

  initRecorder() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  controlReorder() async {
    try {
      if (recording) {
        recorderController.reset();

        final path = await recorderController.stop(false);

        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size: ${File(path).lengthSync()}");
        }
        recording = false;
      } else {
        await recorderController.record(path: path!);

        recording = true;
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  controlAudioPlayer() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      await initAudio(path);
    }
  }

  initAudio(String path) async {
    try {
      await audioPlayer.stop();
      await audioPlayer.setLoopMode(LoopMode.one);
      await audioPlayer.setAudioSource(AudioSource.file(path));
      await audioPlayer.play();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          recording
              ? const SizedBox()
              : Text(
                  path.split('/').last,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: controlReorder,
                  icon: recording
                      ? const Icon(Icons.stop_rounded)
                      : const Icon(Icons.mic)),
              StreamBuilder<dynamic>(
                  stream: audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final playing = playerState?.playing;
                    debugPrint(playing.toString());
                    return (!recording && path.isNotEmpty)
                        ? IconButton(
                            onPressed: controlAudioPlayer,
                            icon: playing ?? false
                                ? const Icon(Icons.pause, color: Colors.blue)
                                : const Icon(Icons.play_arrow,
                                    color: Colors.blue))
                        : const SizedBox();
                  }),
            ],
          )
        ],
      ),
    );
  }
}
