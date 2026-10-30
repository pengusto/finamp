import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:finamp/components/AlbumScreen/download_button.dart';
import 'package:finamp/components/AlbumScreen/download_dialog.dart';
import 'package:finamp/components/ArtistScreen/artist_screen_content.dart';
import 'package:finamp/hive_registrar.g.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/models/locale_adapter.dart';
import 'package:finamp/models/theme_mode_adapter.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';

import 'artist_screen_loading_test.dart' show settings;

final artist = BaseItemDto(
  id: const BaseItemId('artist'),
  name: 'Test artist',
  type: 'MusicArtist',
  userData: UserItemDataDto(playbackPositionTicks: 0, playCount: 0, isFavorite: false, played: false),
);

final library = BaseItemDto(id: const BaseItemId('library'), type: 'CollectionFolder', name: 'Music');
final ownAlbum = BaseItemDto(id: const BaseItemId('own-album'), name: 'Own album', type: 'MusicAlbum', childCount: 3);

class CountApi extends Fake implements JellyfinApiHelper {
  late Completer<QueryResult_BaseItemDto> count;
  final calls = <Invocation>[];
  List<BaseItemDto> albums = [ownAlbum];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    if (invocation.memberName == #getItemsWithTotalRecordCount) return count.future;
    if (invocation.memberName == #getItems && invocation.namedArguments[#includeItemTypes] == 'MusicAlbum') {
      return Future<List<BaseItemDto>?>.value(albums);
    }
    return super.noSuchMethod(invocation);
  }
}

class DownloadStatusFixture extends Fake implements DownloadsService {
  final childCounts = <int?>[];

  @override
  Stream<void> get offlineDeletesStream => const Stream.empty();

  @override
  late final statusProvider = Provider.family.autoDispose<DownloadItemStatus, (DownloadStub, int?)>((ref, args) {
    childCounts.add(args.$2);
    return DownloadItemStatus.notNeeded;
  });

  @override
  final stateProvider = StreamProvider.family.autoDispose<DownloadItemState?, DownloadStub>(
    (ref, stub) => Stream.value(null),
  );
}

class UserFixture extends Fake implements FinampUserHelper {
  @override
  final currentUser = FinampUser(
    id: 'fixture',
    publicAddress: 'http://fixture.invalid',
    localAddress: 'http://fixture.invalid',
    preferLocalNetwork: false,
    isLocal: false,
    accessToken: 'fixture',
    serverId: 'fixture',
    currentViewId: library.id,
    views: {library.id: library},
  );
}

class QueueFixture extends Fake implements QueueService {}

const fontDirectory = String.fromEnvironment('FONT_DIR', defaultValue: '../flutter/bin/cache/artifacts/material_fonts');

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(File('$fontDirectory/Roboto-Regular.ttf').readAsBytesSync())));
    await fonts.load();
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    for (final family in manifest) {
      final loader = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List<dynamic>) { loader.addFont(rootBundle.load(font['asset'] as String)); }
      await loader.load();
    }
  });
  late Directory directory;
  late CountApi api;
  late DownloadStatusFixture downloads;
  late ProviderContainer scope;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('finamp-artist-count-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapters();
      Hive.registerAdapter(ThemeModeAdapter());
      Hive.registerAdapter(ColorAdapter());
      Hive.registerAdapter(LocaleAdapter());
    }
    final box = await Hive.openBox<FinampSettings>('FinampSettings', bytes: Uint8List(0));
    final config = settings(showTracks: false)
      ..artistItemSectionsOrder = []
      ..downloadSizeWarningCutoff = 4;
    config.downloadLocationsMap['fixture'] = DownloadLocation(
      name: 'Fixture storage',
      relativePath: null,
      id: 'fixture',
      baseDirectory: DownloadLocationType.internalSupport,
    );
    config.defaultDownloadLocation = 'fixture';
    await box.put('FinampSettings', config);
    api = CountApi();
    downloads = DownloadStatusFixture();
    GetIt.instance.registerSingleton<JellyfinApiHelper>(api);
    GetIt.instance.registerSingleton<DownloadsService>(downloads);
    GetIt.instance.registerSingleton<FinampUserHelper>(UserFixture());
    GetIt.instance.registerSingleton<QueueService>(QueueFixture());
  });

  tearDown(() async {
    scope.dispose();
    await GetIt.instance.reset();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester) async {
    api.count = Completer<QueryResult_BaseItemDto>();
    scope = ProviderContainer(overrides: [QueueService.queueProvider.overrideWithValue(null)]);
    await scope.read(finampSettingsProvider.future);
    GetIt.instance.registerSingleton<ProviderContainer>(scope);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ArtistScreenContent(parent: artist, library: library),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('capture real artist metadata before and after review', (tester) async {
    const stage = String.fromEnvironment('CAPTURE_STAGE');
    const output = String.fromEnvironment('CAPTURE_DIR');
    await mount(tester);
    expect(find.text('Loading…', findRichText: true), stage == 'before' ? findsNothing : findsOneWidget);
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(Uri.file('$output/artist-$stage-loading.png')));
    api.count.complete(QueryResult_BaseItemDto(items: [], totalRecordCount: 4, startIndex: 0));
    await tester.pump(); await tester.pumpAndSettle();
    expect(find.text('4 Tracks', findRichText: true), findsOneWidget);
    if (stage == 'after') await expectLater(find.byType(Scaffold).first, matchesGoldenFile(Uri.file('$output/artist-after-loaded.png')));
    expect(tester.takeException(), isNull);
  });
}
