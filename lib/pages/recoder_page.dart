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
  late RecorderController recorderController;
  String audioPath = '';
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    getSavedAudioPaths();
    initRecorder();
  }

  getSavedAudioPaths() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final path = preferences.getString("audioPath");
    audioPath = path ?? "";
    setState(() {});
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
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString("audioPath", path!);
      audioPath = path ?? "";
      recording = false;
    } else {
      await recorderController.record();
      recording = true;
    }
    setState(() {});
  }

  controlAudioPlayer() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      await initAudio(audioPath);
    }
  }

  initAudio(String audioPath) async {
    try {
      await audioPlayer.stop();
      await audioPlayer.setLoopMode(LoopMode.one);
      await audioPlayer.setAudioSource(AudioSource.file(audioPath));
      await audioPlayer.play();
    } catch (e) {
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
              StreamBuilder<dynamic>(
                  stream: audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final playing = playerState?.playing;
                    debugPrint(playing.toString());
                    return (!recording && audioPath.isNotEmpty)
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
