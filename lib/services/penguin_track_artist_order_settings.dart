import 'dart:typed_data';

import 'package:hive_ce/hive.dart';

import '../models/finamp_models.dart';

/// Persistence for the native artist-order backport, separate from Finamp's
/// original settings schema. Builds without this feature simply ignore this box.
abstract final class PenguinTrackArtistOrderSettings {
  static const boxName = 'PenguinTrackArtistOrderSettings';
  static const modeKey = 'mode';

  /// Call after the normal settings box has been opened and populated, before
  /// settings providers start. Only mutates the cached object, never its payload.
  /// [bytes] is used by widget-test fixtures; production uses native Hive storage.
  static Future<void> openAndRestore({Uint8List? bytes}) async {
    final box = await Hive.openBox<int>(boxName, bytes: bytes);
    final mode = switch (box.get(modeKey)) {
      0 => TrackArtistOrder.albumArtistsFirst,
      1 => TrackArtistOrder.metadata,
      2 => TrackArtistOrder.firstArtistFirst,
      3 => TrackArtistOrder.alphabetical,
      _ => DefaultSettings.trackArtistOrder,
    };
    Hive.box<FinampSettings>('FinampSettings').get('FinampSettings')!.trackArtistOrder = mode;
  }

  static Future<void> save(TrackArtistOrder order) {
    // Stable IDs, deliberately independent of enum declaration order/adapters.
    final mode = switch (order) {
      TrackArtistOrder.albumArtistsFirst => 0,
      TrackArtistOrder.metadata => 1,
      TrackArtistOrder.firstArtistFirst => 2,
      TrackArtistOrder.alphabetical => 3,
    };
    return Hive.box<int>(boxName).put(modeKey, mode);
  }
}
