import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
