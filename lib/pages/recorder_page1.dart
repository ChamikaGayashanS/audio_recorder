import 'dart:io';
import 'package:audio_player/widgets/rounded_buton.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class RecorderPage1 extends StatefulWidget {
  const RecorderPage1({super.key});

  @override
  State<RecorderPage1> createState() => _RecorderPage1State();
}

class _RecorderPage1State extends State<RecorderPage1> {
  bool recording = false;
  bool playing = false;
  Record recorder = Record();
  AudioPlayer audioPlayer = AudioPlayer();
  String recorderPath = '';
  String trimmedAudioPath = '';
  String firstSegmentPath = '';
  String secondSegmentPath = '';

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

  trimAndPlayAudio(int start, int end) async {
    final trimmedPath = await trimAudio(start, end);
    trimmedAudioPath = trimmedPath; // Store the path for future playback
    await initializeAudioPlayerWithTrimmedAudio();
    print(trimmedAudioPath);
    playPauseAudio();
  }

  Future<String> trimAudio(int start, int end) async {
    final trimmedPath =
        await getDirectory().then((path) => path + '.trimmed.aac');
    await FFmpegKit.executeAsync(
      '-i $recorderPath -ss $start -to $end $trimmedPath',
    );
    return trimmedPath;
  }

  initializeAudioPlayerWithTrimmedAudio() async {
    await audioPlayer.setLoopMode(LoopMode.one);
    await audioPlayer.setAudioSource(AudioSource.file(trimmedAudioPath));
  }

  Future<void> concatenateAndPlayAudio(
      String file1Path, String file2Path) async {
    // 1. Get the path for the concatenated file
    String concatenatedPath =
        await getDirectory().then((path) => path + '.concatenated.aac');

    // 2. Use FFmpeg to concatenate the files
    await FFmpegKit.executeAsync(
      '-i $file1Path -i $file2Path -filter_complex "[0:0][1:0]concat=n=2:v=0:a=1[out]" -map "[out]" $concatenatedPath',
    );

    // 3. Initialize and play the concatenated audio
    await initializeAudioPlayerWithPath(concatenatedPath);
    playPauseAudio();
    print("concat1path = $file1Path + concat2path= $file2Path");
  }

  Future<void> initializeAudioPlayerWithPath(String audioPath) async {
    await audioPlayer.setLoopMode(LoopMode.one);
    await audioPlayer.setAudioSource(AudioSource.file(audioPath));
  }

  Future<void> splitAndPlayAudio(int splitPoint) async {
    // 1. Get paths for split audio segments
    firstSegmentPath =
        await getDirectory().then((path) => path + '.segment1.aac');
    secondSegmentPath =
        await getDirectory().then((path) => path + '.segment2.aac');

    // 2. Use FFmpeg to split the audio
    await FFmpegKit.executeAsync(
        '-i $recorderPath -ss 0 -to $splitPoint $firstSegmentPath -c copy'
        //'-i $recorderPath -ss 0 -to $splitPoint $firstSegmentPath -ss $splitPoint -to $recorderPath.duration $secondSegmentPath',
        );
    await initializeAudioPlayerWithPath(firstSegmentPath);
    playPauseAudio();
    print(firstSegmentPath);

    // // 3. Choose which segment to play
    // bool playFirstSegment = false; // Change this depending on your logic

    // // 4. Initialize and play the chosen segment
    // if (playFirstSegment) {
    //   await initializeAudioPlayerWithPath(firstSegmentPath);
    // } else {
    //   await initializeAudioPlayerWithPath(secondSegmentPath);
    // }
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
                    ? Row(
                        children: [
                          RoundedButton(
                            radius: 50,
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            backgroundColor: Colors.red,
                            borderColors: Colors.black45,
                            onTap: () => playPauseAudio(),
                          ),
                          RoundedButton(
                            radius: 50,
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            backgroundColor: Colors.red,
                            borderColors: Colors.black45,
                            onTap: () => trimAndPlayAudio(5, 8),
                          ),
                          RoundedButton(
                            radius: 50,
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            backgroundColor: Colors.red,
                            borderColors: Colors.black45,
                            onTap: () => concatenateAndPlayAudio(
                                recorderPath, trimmedAudioPath),
                          ),
                          RoundedButton(
                            radius: 50,
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            backgroundColor: Colors.red,
                            borderColors: Colors.black45,
                            onTap: () => splitAndPlayAudio(5),
                          ),
                        ],
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
