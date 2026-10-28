import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/hive_registrar.g.dart';
import 'package:finamp/models/theme_mode_adapter.dart';
import 'package:finamp/models/locale_adapter.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:finamp/menus/track_menu.dart';
import 'package:finamp/menus/output_menu.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/audio_service_helper.dart';
import 'package:finamp/services/current_track_metadata_provider.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/music_player_background_task.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/radio_service_helper.dart';
import 'package:finamp/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

final song = BaseItemDto(
  id: const BaseItemId('output-fixture-track'),
  name: 'Output fixture',
  type: 'Audio',
  userData: UserItemDataDto(playbackPositionTicks: 0, playCount: 0, isFavorite: false, played: false),
);

class FixtureQueue extends Fake implements QueueService {
  final order = BehaviorSubject<FinampPlaybackOrder>.seeded(FinampPlaybackOrder.linear);
  final loop = BehaviorSubject<FinampLoopMode>.seeded(FinampLoopMode.none);
  final speed = BehaviorSubject<double>.seeded(1);
  @override
  FinampQueueItem? getCurrentTrack() => null;
  @override
  BehaviorSubject<FinampPlaybackOrder> getPlaybackOrderStream() => order;
  @override
  BehaviorSubject<FinampLoopMode> getLoopModeStream() => loop;
  @override
  BehaviorSubject<double> getPlaybackSpeedStream() => speed;
}

class FixtureAudio extends Fake implements MusicPlayerBackgroundTask {
  @override
  final ValueNotifier<SleepTimer?> timer = ValueNotifier<SleepTimer?>(null);
  @override
  final mediaItem = BehaviorSubject<MediaItem?>.seeded(null);
  @override
  final playbackState = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
  @override
  final fadeState = BehaviorSubject<FadeState>.seeded(FadeState(fadeVolume: 1));
}

class FixtureUser extends Fake implements FinampUserHelper {
  @override
  FinampUser? get currentUser => null;
}

class FixtureDownloads extends Fake implements DownloadsService {
  @override
  DownloadItemStatus getStatus(DownloadStub stub, int? recursive) => DownloadItemStatus.notNeeded;
  @override
  final statusProvider = Provider.family.autoDispose<DownloadItemStatus, (DownloadStub, int?)>(
    (ref, arguments) => DownloadItemStatus.notNeeded,
  );
}

class FixtureAudioHelper extends Fake implements AudioServiceHelper {}

class FixtureApi extends Fake implements JellyfinApiHelper {}

Future<void> mount(WidgetTester tester, {required bool playerMenu, bool hideBottomActions = true}) async {
  tester.view.physicalSize = const Size(700, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final audio = FixtureAudio();
  GetIt.instance.registerSingleton<MusicPlayerBackgroundTask>(audio);
  final queue = FixtureQueue();
  GetIt.instance.registerSingleton<QueueService>(queue);
  GetIt.instance.registerSingleton<FinampUserHelper>(FixtureUser());
  GetIt.instance.registerSingleton<DownloadsService>(FixtureDownloads());
  GetIt.instance.registerSingleton<AudioServiceHelper>(FixtureAudioHelper());
  GetIt.instance.registerSingleton<JellyfinApiHelper>(FixtureApi());
  final settings = FinampSettings(
    downloadLocations: [],
    downloadLocationsMap: {},
    tabSortBy: {},
    tabSortOrder: {},
    homeScreenConfiguration: const FinampHomeScreenConfiguration(actions: [], sections: []),
    gridImageSize: 160,
    homeScreenImageSize: 160,
    deviceId: 'output-menu-test',
    isOffline: true,
    hidePlayerBottomActions: hideBottomActions,
    useCoverAsBackground: false,
    enableVibration: false,
  );
  settings.disableGesture = true;
  await Hive.box<FinampSettings>("FinampSettings").put("FinampSettings", settings);
  final container = ProviderContainer(
    overrides: [
      localThemeProvider.overrideWithValue(ColorScheme.fromSeed(seedColor: Colors.blue)),
      finampSettingsProvider.overrideWith((ref) => Stream.value(settings)),
      currentTrackMetadataProvider.overrideWithValue(const AsyncValue.data(null)),
      currentTrackProvider.overrideWith((ref) => Stream.value(null)),
      QueueService.queueProvider.overrideWithValue(null),
      currentRadioAvailabilityStatusProvider.overrideWithValue(RadioModeAvailabilityStatus.disabled),
      radioStateProvider.overrideWithValue(null),
    ],
  );
  GetIt.instance.registerSingleton<ProviderContainer>(container);
  await container.read(finampSettingsProvider.future);
  addTearDown(() async {
    container.dispose();
    audio.timer.dispose();
    await queue.order.close();
    await queue.loop.close();
    await queue.speed.close();
    await audio.mediaItem.close();
    await audio.playbackState.close();
    await audio.fadeState.close();
    await GetIt.instance.reset();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Open track menu'),
              onPressed: () => showModalTrackMenu(context: context, item: song, showPlaybackControls: playerMenu),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open track menu'));
  await tester.pumpAndSettle();
}

void main() {
  final nativeTarget = TargetPlatformVariant.only(Platform.isMacOS ? TargetPlatform.macOS : TargetPlatform.android);
  late Directory directory;
  setUp(() async {
    if (Platform.isMacOS) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (call) async => null,
      );
    }
    directory = await Directory.systemTemp.createTemp('finamp-output-test-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapters();
      Hive.registerAdapter(ThemeModeAdapter());
      Hive.registerAdapter(ColorAdapter());
      Hive.registerAdapter(LocaleAdapter());
    }
    await Hive.openBox<FinampSettings>('FinampSettings', bytes: Uint8List(0));
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      null,
    );
    await Hive.close();
    await directory.delete(recursive: true);
  });
  testWidgets('hidden bottom actions retain Output through the real player menu', (tester) async {
    await mount(tester, playerMenu: true);
    expect(find.text('Output'), findsOneWidget);
  }, variant: nativeTarget);
  testWidgets('visible bottom actions keep the same player-menu Output entry', (tester) async {
    await mount(tester, playerMenu: true, hideBottomActions: false);
    expect(find.text('Output'), findsOneWidget);
  }, variant: nativeTarget);
  testWidgets('ordinary library track menus do not gain player Output controls', (tester) async {
    await mount(tester, playerMenu: false);
    expect(find.text('Output'), findsNothing);
  }, variant: nativeTarget);
  testWidgets('Output replaces the track sheet and closes back to its surviving player route', (tester) async {
    await mount(tester, playerMenu: true);
    await tester.tap(find.text('Output'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackMenu), findsNothing);
    expect(find.byType(OutputMenuHeader), findsOneWidget);
    expect(find.byType(VolumeSlider), findsOneWidget);
    final context = tester.element(find.byType(OutputMenuHeader));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.byType(OutputMenuHeader), findsNothing);
    expect(find.text('Open track menu'), findsOneWidget);
  }, variant: nativeTarget);
}
