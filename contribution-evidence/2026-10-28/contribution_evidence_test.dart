// Reproducible UI captures. Only fixture data and service boundaries are fake.
// Kept outside the three upstream PRs; see the evidence README for revisions.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:finamp/components/ArtistScreen/artist_screen_content.dart';
import 'package:finamp/components/Buttons/cta_medium.dart';
import 'package:finamp/components/HomeScreen/home_section_editor.dart';
import 'package:finamp/components/PlayerScreen/artist_chip.dart';
import 'package:finamp/hive_registrar.g.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/models/locale_adapter.dart';
import 'package:finamp/models/theme_mode_adapter.dart';
import 'package:finamp/services/current_album_image_provider.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/music_providers.dart';
import 'package:finamp/services/music_player_background_task.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:rxdart/rxdart.dart';

const after = bool.fromEnvironment('EVIDENCE_AFTER');
const stage = after ? 'after' : 'before';
const fontDirectory = String.fromEnvironment(
  'FLUTTER_FONT_DIR',
  defaultValue: '../flutter/bin/cache/artifacts/material_fonts',
);
const captureKey = ValueKey('capture');
final output = Directory(const String.fromEnvironment('EVIDENCE_DIR', defaultValue: '../finamp-evidence'));

final library = BaseItemDto(id: const BaseItemId('library'), type: 'CollectionFolder', name: 'Fixture Music');
UserItemDataDto userData() => UserItemDataDto(playbackPositionTicks: 0, playCount: 1, isFavorite: false, played: false);
final artist = BaseItemDto(
  id: const BaseItemId('artist'),
  type: 'MusicArtist',
  name: 'Fixture Artist',
  userData: userData(),
);
final song = BaseItemDto(
  id: const BaseItemId('song'),
  name: 'Example song',
  type: 'Audio',
  artists: ['B Guest', 'Z Lead', 'A Guest'],
  artistItems: [
    NameIdPair(id: const BaseItemId('b'), name: 'B Guest'),
    NameIdPair(id: const BaseItemId('z'), name: 'Z Lead'),
    NameIdPair(id: const BaseItemId('a'), name: 'A Guest'),
  ],
  albumArtists: [NameIdPair(id: const BaseItemId('z'), name: 'Z Lead')],
);

class FixtureUser extends Fake implements FinampUserHelper {
  @override
  final currentUser = FinampUser(
    id: 'fixture-user',
    publicAddress: 'http://fixture.invalid',
    localAddress: 'http://fixture.invalid',
    preferLocalNetwork: false,
    isLocal: false,
    accessToken: 'not-a-real-token',
    serverId: 'fixture-server',
    currentViewId: const BaseItemId('library'),
    views: {const BaseItemId('library'): library},
  );
}

class FixtureDownloads extends Fake implements DownloadsService {
  @override
  final stateProvider = StreamProvider.family.autoDispose<DownloadItemState?, DownloadStub>(
    (ref, stub) => Stream.value(null),
  );
  @override
  Stream<void> get offlineDeletesStream => const Stream.empty();
  @override
  final statusProvider = Provider.family.autoDispose<DownloadItemStatus, (DownloadStub, int?)>(
    (ref, args) => DownloadItemStatus.notNeeded,
  );
}

class FixtureQueue extends Fake implements QueueService {}

class FixtureAudio extends Fake implements MusicPlayerBackgroundTask {
  @override
  final mediaItem = BehaviorSubject<MediaItem?>.seeded(null);
  @override
  final playbackState = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
  @override
  final fadeState = BehaviorSubject<FadeState>.seeded(FadeState(fadeVolume: 1.0));
}

class FixtureApi extends Fake implements JellyfinApiHelper {
  @override
  List<BaseItemDto> selectedMixAlbums = [];
  @override
  List<BaseItemDto> selectedMixArtists = [];
  @override
  List<BaseItemDto> selectedMixGenres = [];
  final requests = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getItemsWithTotalRecordCount) {
      requests.add('count: Limit=1 -> TotalRecordCount=7169');
      return Future.value(QueryResult_BaseItemDto(items: [], totalRecordCount: 7169, startIndex: 0));
    }
    if (invocation.memberName == #getItems) {
      final args = invocation.namedArguments;
      if (args[#includeItemTypes] == 'MusicAlbum') {
        return Future<List<BaseItemDto>?>.value([
          BaseItemDto(
            id: const BaseItemId('album'),
            name: 'Fixture Album',
            type: 'MusicAlbum',
            productionYear: 2026,
            premiereDate: '2026-01-01T00:00:00Z',
            childCount: 12,
            userData: userData(),
          ),
        ]);
      }
      final limit = args[#limit];
      requests.add('${args[#artistType]}: Limit=$limit');
      if (limit == null) {
        // Model an outstanding large-discography response, identically for both revisions.
        return Completer<List<BaseItemDto>?>().future;
      }
      return Future<List<BaseItemDto>?>.value(
        List.generate(
          5,
          (i) => BaseItemDto(
            id: BaseItemId('track-$i'),
            name: 'Fixture song ${i + 1}',
            type: 'Audio',
            album: 'Fixture Album',
            albumId: const BaseItemId('album'),
            artists: ['Fixture Artist'],
            artistItems: [NameIdPair(id: artist.id, name: artist.name)],
            premiereDate: '2026-01-0${i + 1}T00:00:00Z',
            productionYear: 2026,
            userData: userData(),
            runTimeTicks: 1800000000,
          ),
        ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

HomeScreenSectionConfiguration configuration(String? title) => HomeScreenSectionConfiguration(
  base: TabsHomeSection(libraryId: allLibraryPlaceholder, contentType: ContentType.playlists),
  sortConfig: SortAndFilterConfiguration.defaultSort,
  customSectionTitle: title,
);

Future<ProviderContainer> container({bool editor = false}) async {
  final result = ProviderContainer(
    overrides: [
      QueueService.queueProvider.overrideWithValue(null),
      currentTrackProvider.overrideWith((ref) => Stream.value(null)),
      if (editor)
        for (final title in <String?>[null, 'Playlists'])
          resolveSectionProvider(configuration(title)).overrideWith((ref) => Completer<Never>().future),
    ],
  );
  addTearDown(result.dispose);
  await result.read(finampSettingsProvider.future);
  GetIt.instance.registerSingleton<ProviderContainer>(result);
  return result;
}

Future<void> mount(WidgetTester tester, ProviderContainer scope, Widget child, {String? title}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff28b6aa), brightness: Brightness.dark),
          ),
          home: Scaffold(
            appBar: title == null ? null : AppBar(title: Text(title)),
            body: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  await expectLater(find.byKey(captureKey), matchesGoldenFile(Uri.file('${output.absolute.path}/$name-$stage.png')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    output.createSync(recursive: true);
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(File('$fontDirectory/Roboto-Regular.ttf').readAsBytesSync())));
    await loader.load();
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    for (final family in manifest) {
      final fonts = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List<dynamic>) {
        fonts.addFont(rootBundle.load(font['asset'] as String));
      }
      await fonts.load();
    }
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('finamp-ui-evidence-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapters();
      Hive.registerAdapter(ThemeModeAdapter());
      Hive.registerAdapter(ColorAdapter());
      Hive.registerAdapter(LocaleAdapter());
    }
    final box = await Hive.openBox<FinampSettings>('FinampSettings', bytes: Uint8List(0));
    await box.put(
      'FinampSettings',
      FinampSettings(
        downloadLocations: [],
        downloadLocationsMap: {},
        tabSortBy: {},
        tabSortOrder: {},
        homeScreenConfiguration: const FinampHomeScreenConfiguration(actions: [], sections: []),
        gridImageSize: 160,
        homeScreenImageSize: 160,
        deviceId: 'ui-fixture',
        showArtistChipImage: false,
        autoSwitchItemCurationType: false,
        artistCuratedItemSelectionType: CuratedItemSelectionType.latestReleases,
      ),
    );
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('artist credit order $stage', (tester) async {
    final scope = await container();
    await mount(
      tester,
      scope,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Example song', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ArtistChips(baseItem: song),
            const SizedBox(height: 32),
            const Divider(),
            const Text('Fixture metadata', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            const Text('Song credits: B Guest, Z Lead, A Guest\nAlbum artist: Z Lead', style: TextStyle(height: 1.7)),
            const Spacer(),
            const Text(
              'Actual Finamp ArtistChips widget\nSynthetic metadata · no live server',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
      title: 'Finamp · song credits',
    );
    final names = tester.widgetList<ArtistChip>(find.byType(ArtistChip)).map((chip) => chip.artist?.name).toList();
    expect(names, after ? ['Z Lead', 'A Guest', 'B Guest'] : ['A Guest', 'B Guest', 'Z Lead']);
    await capture(tester, 'artist-order');
  });

  testWidgets('home title validation $stage', (tester) async {
    final scope = await container(editor: true);
    final drag = DraggableScrollableController();
    addTearDown(drag.dispose);
    await mount(
      tester,
      scope,
      HomeScreenSectionConfigurationMenu(
        initialState: configuration(null),
        dragController: drag,
        childBuilder: (height, slivers) => CustomScrollView(slivers: slivers),
      ),
    );
    await tester.enterText(find.byType(TextField).last, 'Playlists');
    tester.testTextInput.hide();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<CTAMedium>(find.byType(CTAMedium)).disabled, !after);
    await capture(tester, 'title-validation');
  });

  testWidgets('artist page with a pending large response $stage', (tester) async {
    final api = FixtureApi();
    GetIt.instance.registerSingleton<JellyfinApiHelper>(api);
    GetIt.instance.registerSingleton<DownloadsService>(FixtureDownloads());
    GetIt.instance.registerSingleton<FinampUserHelper>(FixtureUser());
    GetIt.instance.registerSingleton<QueueService>(FixtureQueue());
    GetIt.instance.registerSingleton<MusicPlayerBackgroundTask>(FixtureAudio());
    final scope = await container();
    await mount(tester, scope, ArtistScreenContent(parent: artist, library: library));
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('Fixture artist-page requests ($stage): ${api.requests.join('; ')}');
    if (after) {
      expect(find.text('7169 Tracks', findRichText: true), findsOneWidget);
      expect(api.requests.any((r) => r.endsWith('Limit=null')), isFalse);
    } else {
      expect(api.requests.any((r) => r.endsWith('Limit=null')), isTrue);
    }
    await capture(tester, 'artist-loading');
  });
}
