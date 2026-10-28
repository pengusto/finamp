import 'dart:async';
import 'dart:io';

import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/penguin_track_artist_order_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// Exercise Hive's real binary codec, including adapter resolution, not a mock.
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_writer_impl.dart';

import 'support/artist_order_settings.dart';

void main() {
  late Directory directory;
  setUp(() async => directory = await setUpArtistOrderSettings());
  tearDown(() => tearDownArtistOrderSettings(directory));

  Future<Box<FinampSettings>> reopenMain({bool restoreArtistOrder = true, bool original = false}) async {
    await Hive.close();
    Hive.init(directory.path);
    Hive.registerAdapter<FinampSettings>(
      original ? OriginalFinampSettingsAdapter() : FinampSettingsAdapter(),
      override: true,
    );
    // The original/feature-off app has no enum adapter and never opens our box.
    expect(Hive.isAdapterRegistered(128), isFalse);
    final box = await Hive.openBox<FinampSettings>('FinampSettings');
    if (restoreArtistOrder) await PenguinTrackArtistOrderSettings.openAndRestore();
    return box;
  }

  test('original settings adopt the default without rewriting the main Hive file', () async {
    var box = await reopenMain(restoreArtistOrder: false, original: true);
    final original = artistOrderSettings()
      ..isOffline = true
      ..transcodeBitrate = 192000
      ..tabSortBy = {ContentType.tracks: SortBy.dateCreated}
      ..tabSortOrder = {ContentType.tracks: SortOrder.descending};
    await box.put('FinampSettings', original);
    await box.close();
    final mainFile = File('${directory.path}/finampsettings.hive');
    final originalBytes = await mainFile.readAsBytes();

    box = await reopenMain(restoreArtistOrder: false);
    await PenguinTrackArtistOrderSettings.openAndRestore();
    final restored = box.get('FinampSettings')!;
    expect(restored.trackArtistOrder, TrackArtistOrder.albumArtistsFirst);
    expect(restored.deviceId, original.deviceId);
    expect(restored.isOffline, isTrue);
    expect(restored.transcodeBitrate, 192000);
    expect(restored.tabSortBy, original.tabSortBy);
    expect(restored.tabSortOrder, original.tabSortOrder);
    expect(restored.gridImageSize, original.gridImageSize);
    expect(restored.homeScreenImageSize, original.homeScreenImageSize);
    expect(Hive.box<int>(PenguinTrackArtistOrderSettings.boxName).get(PenguinTrackArtistOrderSettings.modeKey), isNull);
    await box.close();
    expect(await mainFile.readAsBytes(), orderedEquals(originalBytes));
  });

  for (final (order, storedMode) in [
    (TrackArtistOrder.albumArtistsFirst, 0),
    (TrackArtistOrder.metadata, 1),
    (TrackArtistOrder.firstArtistFirst, 2),
    (TrackArtistOrder.alphabetical, 3),
  ]) {
    test('$order persists as an int, notifies providers and survives original/feature-off use', () async {
      // Start with a different value so even selecting the default must notify.
      await FinampSettingsHelper.setTrackArtistOrder(
        order == TrackArtistOrder.alphabetical ? TrackArtistOrder.metadata : TrackArtistOrder.alphabetical,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(finampSettingsProvider.future);
      final notified = Completer<void>();
      container.listen(finampSettingsProvider.trackArtistOrder, (_, next) {
        if (next == order && !notified.isCompleted) notified.complete();
      });
      await FinampSettingsHelper.setTrackArtistOrder(order);
      await notified.future.timeout(const Duration(seconds: 5));
      expect(container.read(finampSettingsProvider.trackArtistOrder), order);
      container.dispose();

      final settings = FinampSettingsHelper.finampSettings;
      final nativeWriter = BinaryWriterImpl(Hive);
      FinampSettingsAdapter().write(nativeWriter, settings);
      final payload = nativeWriter.toBytes();
      final originalWriter = BinaryWriterImpl(Hive);
      OriginalFinampSettingsAdapter().write(originalWriter, settings);
      // Exact original payload: neither field 161 nor any other schema change.
      expect(payload, orderedEquals(originalWriter.toBytes()));
      expect(Hive.isAdapterRegistered(128), isFalse);
      final originalReader = BinaryReaderImpl(payload, Hive);
      expect(OriginalFinampSettingsAdapter().read(originalReader).deviceId, settings.deviceId);
      expect(originalReader.availableBytes, 0);

      // Real native files, completely closed/reopened; no in-memory box bytes.
      var box = await reopenMain(restoreArtistOrder: false, original: true);
      expect(Hive.isBoxOpen(PenguinTrackArtistOrderSettings.boxName), isFalse);
      expect(box.get('FinampSettings')!.trackArtistOrder, DefaultSettings.trackArtistOrder);
      expect(box.get('FinampSettings')!.deviceId, 'artist-order-test-device');
      final auxFile = File('${directory.path}/${PenguinTrackArtistOrderSettings.boxName.toLowerCase()}.hive');
      final savedBytes = await auxFile.readAsBytes();
      expect(savedBytes, isNotEmpty);

      // A session in the original APK can change normal settings without losing
      // the feature's stored choice or touching the auxiliary file.
      final featureOffSettings = box.get('FinampSettings')!..transcodeBitrate = 256000;
      await box.put('FinampSettings', featureOffSettings);
      box = await reopenMain(restoreArtistOrder: false, original: true);
      expect(box.get('FinampSettings')!.transcodeBitrate, 256000);
      expect(await auxFile.readAsBytes(), orderedEquals(savedBytes));

      box = await reopenMain(restoreArtistOrder: false);
      expect(box.get('FinampSettings')!.trackArtistOrder, DefaultSettings.trackArtistOrder);
      await PenguinTrackArtistOrderSettings.openAndRestore();
      expect(box.get('FinampSettings')!.trackArtistOrder, order);
      expect(box.get('FinampSettings')!.transcodeBitrate, 256000);
      expect(
        Hive.box<int>(PenguinTrackArtistOrderSettings.boxName).get(PenguinTrackArtistOrderSettings.modeKey),
        storedMode,
      );
    });
  }

  test('layout reset persists the default, notifies providers and preserves unrelated settings', () async {
    await FinampSettingsHelper.setTrackArtistOrder(TrackArtistOrder.alphabetical);
    FinampSetters.setIsOffline(true);
    FinampSetters.setTranscodeBitrate(192000);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(finampSettingsProvider.future);
    final notified = Completer<void>();
    container.listen(finampSettingsProvider.trackArtistOrder, (_, next) {
      if (next == DefaultSettings.trackArtistOrder && !notified.isCompleted) notified.complete();
    });
    await FinampSettingsHelper.resetLayoutSettings();
    await notified.future.timeout(const Duration(seconds: 5));
    expect(container.read(finampSettingsProvider.trackArtistOrder), DefaultSettings.trackArtistOrder);
    container.dispose();

    final box = await reopenMain();
    final restored = box.get('FinampSettings')!;
    expect(restored.trackArtistOrder, DefaultSettings.trackArtistOrder);
    expect(restored.isOffline, isTrue);
    expect(restored.transcodeBitrate, 192000);
    expect(restored.deviceId, 'artist-order-test-device');
    expect(Hive.box<int>(PenguinTrackArtistOrderSettings.boxName).get(PenguinTrackArtistOrderSettings.modeKey), 0);
  });

  for (final unknownMode in [-1, 4, 1000]) {
    test('unknown auxiliary mode $unknownMode falls back without rewriting settings', () async {
      await Hive.box<int>(
        PenguinTrackArtistOrderSettings.boxName,
      ).put(PenguinTrackArtistOrderSettings.modeKey, unknownMode);
      final box = await reopenMain();
      expect(box.get('FinampSettings')!.trackArtistOrder, DefaultSettings.trackArtistOrder);
      expect(box.get('FinampSettings')!.deviceId, 'artist-order-test-device');
      expect(
        Hive.box<int>(PenguinTrackArtistOrderSettings.boxName).get(PenguinTrackArtistOrderSettings.modeKey),
        unknownMode,
      );
    });
  }
}
