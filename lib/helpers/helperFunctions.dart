import 'dart:typed_data';

double getWavDuration(Uint8List byteData) {
  int sampleRate = byteData.buffer.asByteData().getUint32(24, Endian.little);
  int byteRate = byteData.buffer.asByteData().getUint32(28, Endian.little);

  int dataSize = byteData.buffer.asByteData().getUint32(40, Endian.little);
  int numChannels = byteData.buffer.asByteData().getUint16(22, Endian.little);
  int bitsPerSample = byteData.buffer.asByteData().getUint16(34, Endian.little);

  int totalSamples = dataSize ~/ (numChannels * (bitsPerSample ~/ 8));
  double durationInSeconds = totalSamples / sampleRate;

  print('total Samples $totalSamples');
  // print('sample rate $sampleRate');
  // print('byte rate $byteRate');
  print('byte rate $numChannels');

  print('byte per second ${calculateBytesPerSecond(44100, 16, 2)}');

  return durationInSeconds; // duration in milliseconds
}

Uint8List getAudioDataSegment(
    Uint8List fullAudioData, double startTime, double endTime) {
  int sampleRate =
      fullAudioData.buffer.asByteData().getUint32(24, Endian.little);

  int numChannels =
      fullAudioData.buffer.asByteData().getUint16(22, Endian.little);

  int startOffset = (calculateBytesPerSecond(44100, 16, 2) * startTime).toInt();
  int endOffset = (calculateBytesPerSecond(44100, 16, 2) * endTime).toInt();

  endOffset = endOffset.clamp(0, fullAudioData.length);

  Uint8List segment = fullAudioData.sublist(startOffset, endOffset);

  return segment;
}

int calculateBytesPerSecond(int sampleRate, int bitDepth, int numChannels) {
  return (sampleRate * numChannels * (bitDepth ~/ 8));
}
