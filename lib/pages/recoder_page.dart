import 'dart:io';
import 'dart:typed_data';
import 'package:audio_player/pages/recorder_controller.dart';
import 'package:audio_player/widgets/rounded_buton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecorderPage extends ConsumerStatefulWidget {
  const RecorderPage({super.key});

  @override
  ConsumerState<RecorderPage> createState() => _RecorderPageState();
}

double getWavDuration(Uint8List byteData) {
  // Check if it's a WAV file (assuming it's PCM format)
  // if (String.fromCharCodes(byteData.sublist(0, 4)) == 'RIFF' &&
  //     String.fromCharCodes(byteData.sublist(8, 12)) == 'WAVE' &&
  //     String.fromCharCodes(byteData.sublist(20, 24)) == 'fmt ') {
  // Extract sample rate and byte rate from WAV header
  int sampleRate = byteData.buffer.asByteData().getUint32(24, Endian.little);
  int byteRate = byteData.buffer.asByteData().getUint32(28, Endian.little);

  // Calculate duration based on the number of samples
  int dataSize = byteData.buffer.asByteData().getUint32(40, Endian.little);
  int numChannels = byteData.buffer.asByteData().getUint16(22, Endian.little);
  int bitsPerSample = byteData.buffer.asByteData().getUint16(34, Endian.little);

  int totalSamples = dataSize ~/ (numChannels * (bitsPerSample ~/ 8));
  double durationInSeconds = totalSamples / sampleRate;

  return durationInSeconds * 1000;
  // } else {
  //   // Not a valid WAV file
  //   print('Not a valid WAV file.');
  //   return 0.0;
  // }
}

class _RecorderPageState extends ConsumerState<RecorderPage> {
  bool recording = false;
  bool playing = false;
  Record recorder = Record();
  AudioPlayer audioPlayer = AudioPlayer();
  String recorderPath = '';
  Duration duration = const Duration();

  Future getDirectory() async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    return "${appDirectory.path}/recording.wav";
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
          encoder: AudioEncoder.wav,
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
    Duration _duration = await audioPlayer.load() ?? const Duration();
    duration = _duration;
    print(
        'Duration in Seconds - ${duration.inMilliseconds} -------------------------------------------------------------------------------------------------');
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
    final controller = ref.read(recorderPageControllerProvider);
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
                RoundedButton(
                  radius: 50,
                  icon: const Icon(Icons.document_scanner, color: Colors.white),
                  backgroundColor: Colors.red,
                  borderColors: Colors.black45,
                  onTap: () async {
                    File file = File(recorderPath);
                    await file.readAsBytes().then((value) {
                      Uint8List originalByteArray = value;
                      print(
                          'Original Byte Array Length - ${originalByteArray.length}');
                      print(originalByteArray);

                      print(
                          'Byte Array duration ${getWavDuration(originalByteArray)}');
                      // var startIndex = (originalByteArray.length) -
                      //     (originalByteArray.length / duration.inSeconds)
                      //         .round();
                      // var endIndex = (originalByteArray.length);
                      // Uint8List trimmedArray =
                      //     originalByteArray.sublist(startIndex, endIndex);
                      // print(
                      //     'Trimmed Byte Array Length - ${originalByteArray.length}');

                      // File newFile = File.fromRawPath(trimmedArray);
                      // recorderPath = newFile.path;

                      // initializeAudioPlayer();
                    });
                  },
                ),
                const Gap(40),
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