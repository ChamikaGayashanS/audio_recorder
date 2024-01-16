import 'dart:io';
import 'package:audio_player/widgets/rounded_buton.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  bool recording = false;
  bool playing = false;
  Record recorder = Record();
  AudioPlayer audioPlayer = AudioPlayer();
  String recorderPath = '';

  Future getDirectory() async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    return "${appDirectory.path}/recording.aac";
  }

  startRecorder() async {
    await getDirectory().then((path) async {
      recorderPath = path;
      if (await recorder.hasPermission()) {
        setState(() {
          recording = true;
        });
        await recorder.start(
          path: path,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
        );
      }
    });
  }

  stopRecorder() async {
    await recorder.stop();
    await initializeAudioPlayer();
    setState(() {
      recording = false;
    });
  }

  initializeAudioPlayer() async {
    await audioPlayer.setLoopMode(LoopMode.one);
    await audioPlayer.setAudioSource(AudioSource.file(recorderPath));
  }

  playPauseAudio() async {
    if (playing) {
      playing = false;
      setState(() {});
      await audioPlayer.pause();
    } else {
      playing = true;
      setState(() {});
      await audioPlayer.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 100,
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 255, 245, 211)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // RoundedButton(
                //   radius: 50,
                //   icon: const Icon(Icons.mic, color: Colors.white),
                //   backgroundColor: Colors.red,
                //   borderColors: Colors.black45,
                //   onTap: () {},
                // ),
                const Gap(70),
                RoundedButton(
                  radius: 60,
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
                ((recorderPath.isNotEmpty) && (!recording))
                    ? RoundedButton(
                        radius: 50,
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                            color: Colors.white),
                        backgroundColor: Colors.red,
                        borderColors: Colors.black45,
                        onTap: () => playPauseAudio(),
                      )
                    : const Gap(50)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
