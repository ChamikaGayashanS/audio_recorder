import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  bool recording = false;
  bool audioPlaying = false;
  late RecorderController recorderController;
  String audioPath = '';
  AudioPlayer audioPlayer = AudioPlayer();
  late SharedPreferences preferences;

  @override
  void initState() {
    // TODO: implement initState
    initSharedPreference();
    initRecorder();
    getSavedAudioPaths();
  }

  getSavedAudioPaths() async {
    final path = preferences.getString('audioPath');
    audioPath = path ?? "";
    initAudio(audioPath);
  }

  initSharedPreference() async {
    preferences = await SharedPreferences.getInstance();
  }

  initRecorder() {
    super.initState();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }

  controlReorder() async {
    if (recording) {
      final path = await recorderController.stop();
      debugPrint(path);
      preferences.setString("audioPath", audioPath);
      audioPath = path ?? "";
      recording = false;
    } else {
      await recorderController.record();
      recording = true;
    }
    setState(() {});
  }

  controlAudioPlayer() async {
    if (audioPlaying) {
      audioPlaying = false;
      await audioPlayer.pause();
    } else {
      audioPlaying = true;
      await initAudio(audioPath);
    }

    setState(() {});
  }

  initAudio(String audioPath) async {
    try {
      await audioPlayer.stop();
      await audioPlayer.setLoopMode(LoopMode.off);
      await audioPlayer.setAudioSource(AudioSource.file(audioPath));
      await audioPlayer.play();
    } catch (e) {
      audioPlaying = false;
      debugPrint(e.toString());
    }
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
                  audioPath.split('/').last,
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
              (!recording && audioPath.isNotEmpty)
                  ? IconButton(
                      onPressed: controlAudioPlayer,
                      icon: audioPlaying
                          ? const Icon(Icons.stop, color: Colors.blue)
                          : const Icon(Icons.play_arrow, color: Colors.blue))
                  : const SizedBox(),
            ],
          )
        ],
      ),
    );
  }
}
