import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService(ref: ref));

class FirebaseService {
  final Ref ref;
  final db = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  FirebaseService({required this.ref});

  addAudioFile({required Blob file}) async {
    Reference ref = storage.ref().child('media').child('AudioFile.m4a');
    await ref.putBlob(file);
  }
}
