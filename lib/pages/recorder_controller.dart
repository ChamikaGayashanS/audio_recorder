import 'dart:io';
import 'dart:typed_data';
import 'package:audio_player/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recorderPageControllerProvider =
    Provider<RecorderPageController>((ref) => RecorderPageController(ref: ref));

class RecorderPageController {
  final Ref ref;

  RecorderPageController({required this.ref});
  late final firebaseService = ref.read(firebaseServiceProvider);

  addAudioFile({required String filePath}) async {
    File file = File(filePath);
    Blob myBlob = Blob(await file.readAsBytes());
    await firebaseService.addAudioFile(file: myBlob);
  }
}
