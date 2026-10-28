import 'dart:io';
import 'dart:typed_data';

import 'package:finamp/hive_registrar.g.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/models/locale_adapter.dart';
import 'package:finamp/models/theme_mode_adapter.dart';
import 'package:finamp/services/penguin_track_artist_order_settings.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:flutter/material.dart';

FinampSettings artistOrderSettings() => FinampSettings(
  downloadLocations: [],
  downloadLocationsMap: {},
  tabSortBy: {},
  tabSortOrder: {},
  homeScreenConfiguration: const FinampHomeScreenConfiguration(actions: [], sections: []),
  gridImageSize: 160,
  homeScreenImageSize: 160,
  deviceId: 'artist-order-test-device',
  showArtistChipImage: false,
);

Future<Directory> setUpArtistOrderSettings({bool inMemory = false}) async {
  final directory = await Directory.systemTemp.createTemp('finamp-artist-order-');
  Hive.init(directory.path);
  if (!Hive.isAdapterRegistered(28)) {
    Hive.registerAdapters();
    Hive.registerAdapter(ThemeModeAdapter());
    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(LocaleAdapter());
  }
  final box = await Hive.openBox<FinampSettings>('FinampSettings', bytes: inMemory ? Uint8List(0) : null);
  await box.put('FinampSettings', artistOrderSettings());
  await PenguinTrackArtistOrderSettings.openAndRestore(bytes: inMemory ? Uint8List(0) : null);
  return directory;
}

Future<void> tearDownArtistOrderSettings(Directory directory) async {
  await Hive.close();
  await directory.delete(recursive: true);
}

// Verbatim release 1.0.1 settings adapter from 65c1a78b1d04dd8525825ecdf2cf39c7442b51e9,
// lib/models/finamp_models.g.dart; only the class name is changed.
// Keep this fixture independent of the production adapter to test patch removal.
// dart format off
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, strict_raw_type
class OriginalFinampSettingsAdapter extends TypeAdapter<FinampSettings> {
  @override
  final typeId = 28;

  @override
  FinampSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinampSettings(
        isOffline: fields[0] == null ? false : fields[0] as bool,
        shouldTranscode: fields[1] == null ? false : fields[1] as bool,
        transcodeBitrate: fields[2] == null
            ? 320000
            : (fields[2] as num).toInt(),
        downloadLocations: (fields[3] as List).cast<DownloadLocation>(),
        androidStopForegroundOnPause: fields[4] == null
            ? true
            : fields[4] as bool,
        showTabs: fields[5] == null
            ? DefaultSettings.showTabs
            : (fields[5] as Map).cast<ContentType, bool>(),
        onlyShowFavorites: fields[6] == null ? false : fields[6] as bool,
        trackShuffleItemCount: fields[9] == null
            ? 250
            : (fields[9] as num).toInt(),
        volumeNormalizationActive: fields[29] == null
            ? true
            : fields[29] as bool,
        volumeNormalizationIOSBaseGain: fields[30] == null
            ? 6.0
            : (fields[30] as num).toDouble(),
        volumeNormalizationMode: fields[33] == null
            ? VolumeNormalizationMode.hybrid
            : fields[33] as VolumeNormalizationMode,
        playbackSpeedVisibility: fields[57] == null
            ? PlaybackSpeedVisibility.automatic
            : fields[57] as PlaybackSpeedVisibility,
        contentGridViewCrossAxisCountPortrait: (fields[11] as num?)?.toInt(),
        contentGridViewCrossAxisCountLandscape: (fields[12] as num?)?.toInt(),
        showTextOnGridView: fields[13] == null ? true : fields[13] as bool,
        downloadLocationsMap: fields[15] == null
            ? {}
            : (fields[15] as Map).cast<String, DownloadLocation>(),
        useCoverAsBackground: fields[16] == null ? true : fields[16] as bool,
        playerScreenCoverMinimumPadding: fields[48] == null
            ? 1.5
            : (fields[48] as num).toDouble(),
        showArtistsTracksSection: fields[54] == null
            ? true
            : fields[54] as bool,
        bufferDisableSizeConstraints: fields[78] == null
            ? false
            : fields[78] as bool,
        bufferDurationSeconds: fields[18] == null
            ? 600
            : (fields[18] as num).toInt(),
        bufferSizeMegabytes: fields[79] == null
            ? 50
            : (fields[79] as num).toInt(),
        tabSortBy: fields[20] == null
            ? {}
            : (fields[20] as Map).cast<ContentType, SortBy>(),
        tabSortOrder: fields[21] == null
            ? {}
            : (fields[21] as Map).cast<ContentType, SortOrder>(),
        loopMode: fields[27] == null
            ? FinampLoopMode.none
            : fields[27] as FinampLoopMode,
        playbackSpeed: fields[56] == null
            ? 1.0
            : (fields[56] as num).toDouble(),
        playbackPitch: fields[118] == null
            ? 1.0
            : (fields[118] as num).toDouble(),
        syncPlaybackSpeedAndPitch: fields[119] == null
            ? false
            : fields[119] as bool,
        tabOrder: fields[22] == null
            ? [
                ContentType.home,
                ContentType.albums,
                ContentType.genericArtists,
                ContentType.albumArtists,
                ContentType.performingArtists,
                ContentType.playlists,
                ContentType.tracks,
                ContentType.genres,
              ]
            : (fields[22] as List).cast<ContentType>(),
        autoloadLastQueueOnStartup: fields[28] == null
            ? true
            : fields[28] as bool,
        hasCompletedDownloadsServiceMigration: fields[34] == null
            ? false
            : fields[34] as bool,
        requireWifiForDownloads: fields[35] == null ? true : fields[35] as bool,
        onlyShowFullyDownloaded: fields[36] == null
            ? false
            : fields[36] as bool,
        showDownloadsWithUnknownLibrary: fields[37] == null
            ? true
            : fields[37] as bool,
        maxConcurrentDownloads: fields[38] == null
            ? 5
            : (fields[38] as num).toInt(),
        downloadWorkers: fields[39] == null ? 1 : (fields[39] as num).toInt(),
        resyncOnStartup: fields[40] == null ? true : fields[40] as bool,
        preferQuickSyncs: fields[41] == null ? true : fields[41] as bool,
        hasCompletedIsarUserMigration: fields[42] == null
            ? false
            : fields[42] as bool,
        downloadTranscodingCodec: fields[43] as FinampTranscodingCodec?,
        downloadTranscodeBitrate: (fields[45] as num?)?.toInt(),
        shouldTranscodeDownloads: fields[44] == null
            ? TranscodeDownloadsSetting.ask
            : fields[44] as TranscodeDownloadsSetting,
        multichannelHandlingSetting: fields[144] == null
            ? MultichannelHandlingSetting.stereoDownmixLossy
            : fields[144] as MultichannelHandlingSetting,
        shouldRedownloadTranscodes: fields[46] == null
            ? false
            : fields[46] as bool,
        itemSwipeActionLeftToRight: fields[90] == null
            ? ItemSwipeActions.nothing
            : fields[90] as ItemSwipeActions,
        itemSwipeActionRightToLeft: fields[91] == null
            ? ItemSwipeActions.addToNextUp
            : fields[91] as ItemSwipeActions,
        useFixedSizeGridTiles: fields[59] as bool?,
        fixedGridTileSize: (fields[60] as num?)?.toInt(),
        allowSplitScreen: fields[61] == null ? true : fields[61] as bool,
        splitScreenPlayerWidth: fields[62] == null
            ? 400.0
            : (fields[62] as num).toDouble(),
        enableVibration: fields[47] == null ? true : fields[47] as bool,
        prioritizeCoverFactor: fields[49] == null
            ? 8.0
            : (fields[49] as num).toDouble(),
        suppressPlayerPadding: fields[50] == null ? false : fields[50] as bool,
        hidePlayerBottomActions: fields[51] == null
            ? false
            : fields[51] as bool,
        reportQueueToServer: fields[52] == null ? false : fields[52] as bool,
        periodicPlaybackSessionUpdateFrequencySeconds: fields[53] == null
            ? 150
            : (fields[53] as num).toInt(),
        playOnStaleDelay: fields[94] == null ? 90 : (fields[94] as num).toInt(),
        playOnReconnectionDelay: fields[95] == null
            ? 5
            : (fields[95] as num).toInt(),
        enablePlayon: fields[96] == null ? true : fields[96] as bool,
        currentVolume: fields[93] == null
            ? 1.0
            : (fields[93] as num).toDouble(),
        showArtistChipImage: fields[55] == null ? true : fields[55] as bool,
        trackOfflineFavorites: fields[63] == null ? true : fields[63] as bool,
        showProgressOnNowPlayingBar: fields[64] == null
            ? true
            : fields[64] as bool,
        startInstantMixForIndividualTracks: fields[65] == null
            ? false
            : fields[65] as bool,
        showLyricsTimestamps: fields[66] == null ? true : fields[66] as bool,
        lyricsAlignment: fields[67] == null
            ? LyricsAlignment.start
            : fields[67] as LyricsAlignment,
        lyricsFontSize: fields[70] == null
            ? LyricsFontSize.medium
            : fields[70] as LyricsFontSize,
        showLyricsScreenAlbumPrelude: fields[71] == null
            ? true
            : fields[71] as bool,
        showStopButtonOnMediaNotification: fields[68] == null
            ? false
            : fields[68] as bool,
        showShuffleButtonOnMediaNotification: fields[98] == null
            ? true
            : fields[98] as bool,
        showFavoriteButtonOnMediaNotification: fields[99] == null
            ? true
            : fields[99] as bool,
        showSeekControlsOnMediaNotification: fields[69] == null
            ? true
            : fields[69] as bool,
        keepScreenOnOption: fields[72] == null
            ? KeepScreenOnOption.whileLyrics
            : fields[72] as KeepScreenOnOption,
        keepScreenOnWhilePluggedIn: fields[73] == null
            ? false
            : fields[73] as bool,
        featureChipsConfiguration: fields[76] == null
            ? DefaultSettings.featureChipsConfiguration
            : fields[76] as FinampFeatureChipsConfiguration,
        showCoversOnAlbumScreen: fields[77] == null
            ? false
            : fields[77] as bool,
        hasDownloadedPlaylistInfo: fields[74] == null
            ? false
            : fields[74] as bool,
        transcodingStreamingFormat: fields[75] == null
            ? FinampTranscodingStreamingFormat.aacFragmentedMp4
            : fields[75] as FinampTranscodingStreamingFormat,
        downloadSizeWarningCutoff: fields[80] == null
            ? 150
            : (fields[80] as num).toInt(),
        allowDeleteFromServer: fields[81] == null ? false : fields[81] as bool,
        oneLineMarqueeTextButton: fields[82] == null
            ? false
            : fields[82] as bool,
        showAlbumReleaseDateOnPlayerScreen: fields[83] == null
            ? false
            : fields[83] as bool,
        releaseDateFormat: fields[84] == null
            ? ReleaseDateFormat.year
            : fields[84] as ReleaseDateFormat,
        defaultArtistType: fields[92] == null
            ? ArtistType.albumArtist
            : fields[92] as ArtistType,
        autoOffline: fields[88] == null
            ? AutoOfflineOption.disconnected
            : fields[88] as AutoOfflineOption,
        autoOfflineListenerActive: fields[89] == null
            ? true
            : fields[89] as bool,
        audioFadeOutDuration: fields[86] == null
            ? Duration.zero
            : fields[86] as Duration,
        audioFadeInDuration: fields[87] == null
            ? Duration.zero
            : fields[87] as Duration,
        autoReloadQueue: fields[97] == null ? false : fields[97] as bool,
        screenSize: fields[100] as ScreenSize?,
        genreCuratedItemSelectionTypeTracks: fields[101] == null
            ? CuratedItemSelectionType.mostPlayed
            : fields[101] as CuratedItemSelectionType,
        genreCuratedItemSelectionTypeAlbums: fields[102] == null
            ? CuratedItemSelectionType.latestReleases
            : fields[102] as CuratedItemSelectionType,
        genreCuratedItemSelectionTypeArtists: fields[103] == null
            ? CuratedItemSelectionType.favorites
            : fields[103] as CuratedItemSelectionType,
        genreItemSectionsOrder: fields[104] == null
            ? [
                GenreItemSections.tracks,
                GenreItemSections.albums,
                GenreItemSections.artists,
              ]
            : (fields[104] as List).cast<GenreItemSections>(),
        genreFilterArtistScreens: fields[105] == null
            ? true
            : fields[105] as bool,
        genreListsInheritSorting: fields[106] == null
            ? true
            : fields[106] as bool,
        genreItemSectionFilterChipOrder: fields[107] == null
            ? [
                CuratedItemSelectionType.mostPlayed,
                CuratedItemSelectionType.favorites,
                CuratedItemSelectionType.random,
                CuratedItemSelectionType.latestReleases,
                CuratedItemSelectionType.recentlyAdded,
                CuratedItemSelectionType.recentlyPlayed,
              ]
            : (fields[107] as List).cast<CuratedItemSelectionType>(),
        applyFilterOnGenreChipTap: fields[108] == null
            ? false
            : fields[108] as bool,
        artistCuratedItemSelectionType: fields[109] == null
            ? CuratedItemSelectionType.mostPlayed
            : fields[109] as CuratedItemSelectionType,
        artistItemSectionFilterChipOrder: fields[110] == null
            ? [
                CuratedItemSelectionType.mostPlayed,
                CuratedItemSelectionType.favorites,
                CuratedItemSelectionType.random,
                CuratedItemSelectionType.latestReleases,
                CuratedItemSelectionType.recentlyAdded,
                CuratedItemSelectionType.recentlyPlayed,
              ]
            : (fields[110] as List).cast<CuratedItemSelectionType>(),
        artistItemSectionsOrder: fields[111] == null
            ? [
                ArtistItemSections.tracks,
                ArtistItemSections.albums,
                ArtistItemSections.appearsOn,
              ]
            : (fields[111] as List).cast<ArtistItemSections>(),
        autoSwitchItemCurationType: fields[112] == null
            ? true
            : fields[112] as bool,
        genreFilterPlaylists: fields[115] == null ? false : fields[115] as bool,
        clearQueueOnStopEvent: fields[117] == null
            ? false
            : fields[117] as bool,
        useHighContrastColors: fields[120] == null
            ? false
            : fields[120] as bool,
        hasCompletedDownloadsFileOwnerMigration: fields[121] == null
            ? false
            : fields[121] as bool,
        tileAdditionalInfoType: fields[122] == null
            ? {
                ContentType.tracks: TileAdditionalInfoType.adaptive,
                ContentType.albums: TileAdditionalInfoType.adaptive,
                ContentType.performingArtists: TileAdditionalInfoType.adaptive,
                ContentType.albumArtists: TileAdditionalInfoType.adaptive,
                ContentType.playlists: TileAdditionalInfoType.adaptive,
                ContentType.genres: TileAdditionalInfoType.adaptive,
              }
            : (fields[122] as Map).cast<ContentType, TileAdditionalInfoType>(),
        rpcEnabled: fields[123] == null ? false : fields[123] as bool,
        rpcIcon: fields[124] == null
            ? DiscordRpcIcon.transparent
            : fields[124] as DiscordRpcIcon,
        preferAddingToFavoritesOverPlaylists: fields[126] == null
            ? false
            : fields[126] as bool,
        previousTracksExpanded: fields[127] == null
            ? false
            : fields[127] as bool,
        autoplayRestoredQueue: fields[128] == null
            ? false
            : fields[128] as bool,
        preferNextUpPrepending: fields[129] == null
            ? true
            : fields[129] as bool,
        rememberLastUsedPlaybackActionRowPage: fields[130] == null
            ? true
            : fields[130] as bool,
        lastUsedPlaybackActionRowPage: fields[131] == null
            ? PlaybackActionRowPage.newQueue
            : fields[131] as PlaybackActionRowPage,
        lastUsedPlaybackActionRowPageForQueueMenu: fields[139] == null
            ? PlaybackActionRowPage.moveWithinQueue
            : fields[139] as PlaybackActionRowPage,
        accentColor: fields[132] == null
            ? DefaultSettings.accentColor
            : fields[132] as Color?,
        themeMode: fields[133] == null
            ? ThemeMode.system
            : fields[133] as ThemeMode,
        amoledTheme: fields[148] == null ? false : fields[148] as bool,
        locale: fields[134] == null
            ? DefaultSettings.locale
            : fields[134] as Locale?,
        hasCompletedThemeModeLocaleMigration: fields[135] == null
            ? false
            : fields[135] as bool,
        systemAccentColor: fields[136] == null
            ? DefaultSettings.accentColor
            : fields[136] as Color?,
        useSystemAccentColor: fields[137] == null ? false : fields[137] as bool,
        useMonochromeIcon: fields[138] == null ? false : fields[138] as bool,
        duckOnAudioInterruption: fields[142] == null
            ? true
            : fields[142] as bool,
        forceAudioOffloadingOnAndroid: fields[143] == null
            ? false
            : fields[143] as bool,
        verboseLogging: fields[158] == null ? false : fields[158] as bool,
        previousTracksPersistenceMode: fields[145] == null
            ? PreviousTracksPersistenceMode.persistent
            : fields[145] as PreviousTracksPersistenceMode,
        homeScreenConfiguration: fields[146] == null
            ? const FinampHomeScreenConfiguration(actions: [], sections: [])
            : fields[146] as FinampHomeScreenConfiguration,
        gridImageSize: fields[147] == null ? 130 : (fields[147] as num).toInt(),
        homeScreenImageSize: fields[150] == null
            ? 90
            : (fields[150] as num).toInt(),
        useAndroidGainEffect: fields[149] == null ? true : fields[149] as bool,
        deviceId: fields[152] == null ? 'unset' : fields[152] as String,
        clientCertificate: fields[151] == null
            ? DefaultSettings.clientCertificate
            : fields[151] as ClientCertificate?,
        showQuickActionsBanner: fields[159] == null
            ? true
            : fields[159] as bool,
        perTabContentViewType: fields[160] == null
            ? {
                ContentType.albums: ContentViewType.grid,
                ContentType.genericArtists: ContentViewType.list,
                ContentType.albumArtists: ContentViewType.list,
                ContentType.performingArtists: ContentViewType.list,
                ContentType.playlists: ContentViewType.list,
                ContentType.genres: ContentViewType.list,
              }
            : (fields[160] as Map).cast<ContentType, ContentViewType>(),
      )
      ..sortBy = fields[7] as SortBy?
      ..sortOrder = fields[8] as SortOrder?
      ..contentViewType = fields[10] as ContentViewType?
      ..disableGesture = fields[19] == null ? false : fields[19] as bool
      ..showFastScroller = fields[25] == null ? true : fields[25] as bool
      ..defaultDownloadLocation = fields[58] as String?
      ..lastUsedDownloadLocationId = fields[85] as String?
      ..playlistTracksSortBy = fields[113] as SortBy?
      ..playlistTracksSortOrder = fields[114] as SortOrder?
      ..sleepTimer = fields[116] as SleepTimer?
      ..autoExpandPlayerScreen = fields[125] == null
          ? false
          : fields[125] as bool
      ..radioEnabled = fields[140] == null ? false : fields[140] as bool
      ..radioMode = fields[141] == null
          ? RadioMode.similar
          : fields[141] as RadioMode;
  }

  @override
  void write(BinaryWriter writer, FinampSettings obj) {
    writer
      ..writeByte(149)
      ..writeByte(0)
      ..write(obj.isOffline)
      ..writeByte(1)
      ..write(obj.shouldTranscode)
      ..writeByte(2)
      ..write(obj.transcodeBitrate)
      ..writeByte(3)
      ..write(obj.downloadLocations)
      ..writeByte(4)
      ..write(obj.androidStopForegroundOnPause)
      ..writeByte(5)
      ..write(obj.showTabs)
      ..writeByte(6)
      ..write(obj.onlyShowFavorites)
      ..writeByte(7)
      ..write(obj.sortBy)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.trackShuffleItemCount)
      ..writeByte(10)
      ..write(obj.contentViewType)
      ..writeByte(11)
      ..write(obj.contentGridViewCrossAxisCountPortrait)
      ..writeByte(12)
      ..write(obj.contentGridViewCrossAxisCountLandscape)
      ..writeByte(13)
      ..write(obj.showTextOnGridView)
      ..writeByte(15)
      ..write(obj.downloadLocationsMap)
      ..writeByte(16)
      ..write(obj.useCoverAsBackground)
      ..writeByte(18)
      ..write(obj.bufferDurationSeconds)
      ..writeByte(19)
      ..write(obj.disableGesture)
      ..writeByte(20)
      ..write(obj.tabSortBy)
      ..writeByte(21)
      ..write(obj.tabSortOrder)
      ..writeByte(22)
      ..write(obj.tabOrder)
      ..writeByte(25)
      ..write(obj.showFastScroller)
      ..writeByte(27)
      ..write(obj.loopMode)
      ..writeByte(28)
      ..write(obj.autoloadLastQueueOnStartup)
      ..writeByte(29)
      ..write(obj.volumeNormalizationActive)
      ..writeByte(30)
      ..write(obj.volumeNormalizationIOSBaseGain)
      ..writeByte(33)
      ..write(obj.volumeNormalizationMode)
      ..writeByte(34)
      ..write(obj.hasCompletedDownloadsServiceMigration)
      ..writeByte(35)
      ..write(obj.requireWifiForDownloads)
      ..writeByte(36)
      ..write(obj.onlyShowFullyDownloaded)
      ..writeByte(37)
      ..write(obj.showDownloadsWithUnknownLibrary)
      ..writeByte(38)
      ..write(obj.maxConcurrentDownloads)
      ..writeByte(39)
      ..write(obj.downloadWorkers)
      ..writeByte(40)
      ..write(obj.resyncOnStartup)
      ..writeByte(41)
      ..write(obj.preferQuickSyncs)
      ..writeByte(42)
      ..write(obj.hasCompletedIsarUserMigration)
      ..writeByte(43)
      ..write(obj.downloadTranscodingCodec)
      ..writeByte(44)
      ..write(obj.shouldTranscodeDownloads)
      ..writeByte(45)
      ..write(obj.downloadTranscodeBitrate)
      ..writeByte(46)
      ..write(obj.shouldRedownloadTranscodes)
      ..writeByte(47)
      ..write(obj.enableVibration)
      ..writeByte(48)
      ..write(obj.playerScreenCoverMinimumPadding)
      ..writeByte(49)
      ..write(obj.prioritizeCoverFactor)
      ..writeByte(50)
      ..write(obj.suppressPlayerPadding)
      ..writeByte(51)
      ..write(obj.hidePlayerBottomActions)
      ..writeByte(52)
      ..write(obj.reportQueueToServer)
      ..writeByte(53)
      ..write(obj.periodicPlaybackSessionUpdateFrequencySeconds)
      ..writeByte(54)
      ..write(obj.showArtistsTracksSection)
      ..writeByte(55)
      ..write(obj.showArtistChipImage)
      ..writeByte(56)
      ..write(obj.playbackSpeed)
      ..writeByte(57)
      ..write(obj.playbackSpeedVisibility)
      ..writeByte(58)
      ..write(obj.defaultDownloadLocation)
      ..writeByte(59)
      ..write(obj.useFixedSizeGridTiles)
      ..writeByte(60)
      ..write(obj.fixedGridTileSize)
      ..writeByte(61)
      ..write(obj.allowSplitScreen)
      ..writeByte(62)
      ..write(obj.splitScreenPlayerWidth)
      ..writeByte(63)
      ..write(obj.trackOfflineFavorites)
      ..writeByte(64)
      ..write(obj.showProgressOnNowPlayingBar)
      ..writeByte(65)
      ..write(obj.startInstantMixForIndividualTracks)
      ..writeByte(66)
      ..write(obj.showLyricsTimestamps)
      ..writeByte(67)
      ..write(obj.lyricsAlignment)
      ..writeByte(68)
      ..write(obj.showStopButtonOnMediaNotification)
      ..writeByte(69)
      ..write(obj.showSeekControlsOnMediaNotification)
      ..writeByte(70)
      ..write(obj.lyricsFontSize)
      ..writeByte(71)
      ..write(obj.showLyricsScreenAlbumPrelude)
      ..writeByte(72)
      ..write(obj.keepScreenOnOption)
      ..writeByte(73)
      ..write(obj.keepScreenOnWhilePluggedIn)
      ..writeByte(74)
      ..write(obj.hasDownloadedPlaylistInfo)
      ..writeByte(75)
      ..write(obj.transcodingStreamingFormat)
      ..writeByte(76)
      ..write(obj.featureChipsConfiguration)
      ..writeByte(77)
      ..write(obj.showCoversOnAlbumScreen)
      ..writeByte(78)
      ..write(obj.bufferDisableSizeConstraints)
      ..writeByte(79)
      ..write(obj.bufferSizeMegabytes)
      ..writeByte(80)
      ..write(obj.downloadSizeWarningCutoff)
      ..writeByte(81)
      ..write(obj.allowDeleteFromServer)
      ..writeByte(82)
      ..write(obj.oneLineMarqueeTextButton)
      ..writeByte(83)
      ..write(obj.showAlbumReleaseDateOnPlayerScreen)
      ..writeByte(84)
      ..write(obj.releaseDateFormat)
      ..writeByte(85)
      ..write(obj.lastUsedDownloadLocationId)
      ..writeByte(86)
      ..write(obj.audioFadeOutDuration)
      ..writeByte(87)
      ..write(obj.audioFadeInDuration)
      ..writeByte(88)
      ..write(obj.autoOffline)
      ..writeByte(89)
      ..write(obj.autoOfflineListenerActive)
      ..writeByte(90)
      ..write(obj.itemSwipeActionLeftToRight)
      ..writeByte(91)
      ..write(obj.itemSwipeActionRightToLeft)
      ..writeByte(92)
      ..write(obj.defaultArtistType)
      ..writeByte(93)
      ..write(obj.currentVolume)
      ..writeByte(94)
      ..write(obj.playOnStaleDelay)
      ..writeByte(95)
      ..write(obj.playOnReconnectionDelay)
      ..writeByte(96)
      ..write(obj.enablePlayon)
      ..writeByte(97)
      ..write(obj.autoReloadQueue)
      ..writeByte(98)
      ..write(obj.showShuffleButtonOnMediaNotification)
      ..writeByte(99)
      ..write(obj.showFavoriteButtonOnMediaNotification)
      ..writeByte(100)
      ..write(obj.screenSize)
      ..writeByte(101)
      ..write(obj.genreCuratedItemSelectionTypeTracks)
      ..writeByte(102)
      ..write(obj.genreCuratedItemSelectionTypeAlbums)
      ..writeByte(103)
      ..write(obj.genreCuratedItemSelectionTypeArtists)
      ..writeByte(104)
      ..write(obj.genreItemSectionsOrder)
      ..writeByte(105)
      ..write(obj.genreFilterArtistScreens)
      ..writeByte(106)
      ..write(obj.genreListsInheritSorting)
      ..writeByte(107)
      ..write(obj.genreItemSectionFilterChipOrder)
      ..writeByte(108)
      ..write(obj.applyFilterOnGenreChipTap)
      ..writeByte(109)
      ..write(obj.artistCuratedItemSelectionType)
      ..writeByte(110)
      ..write(obj.artistItemSectionFilterChipOrder)
      ..writeByte(111)
      ..write(obj.artistItemSectionsOrder)
      ..writeByte(112)
      ..write(obj.autoSwitchItemCurationType)
      ..writeByte(113)
      ..write(obj.playlistTracksSortBy)
      ..writeByte(114)
      ..write(obj.playlistTracksSortOrder)
      ..writeByte(115)
      ..write(obj.genreFilterPlaylists)
      ..writeByte(116)
      ..write(obj.sleepTimer)
      ..writeByte(117)
      ..write(obj.clearQueueOnStopEvent)
      ..writeByte(118)
      ..write(obj.playbackPitch)
      ..writeByte(119)
      ..write(obj.syncPlaybackSpeedAndPitch)
      ..writeByte(120)
      ..write(obj.useHighContrastColors)
      ..writeByte(121)
      ..write(obj.hasCompletedDownloadsFileOwnerMigration)
      ..writeByte(122)
      ..write(obj.tileAdditionalInfoType)
      ..writeByte(123)
      ..write(obj.rpcEnabled)
      ..writeByte(124)
      ..write(obj.rpcIcon)
      ..writeByte(125)
      ..write(obj.autoExpandPlayerScreen)
      ..writeByte(126)
      ..write(obj.preferAddingToFavoritesOverPlaylists)
      ..writeByte(127)
      ..write(obj.previousTracksExpanded)
      ..writeByte(128)
      ..write(obj.autoplayRestoredQueue)
      ..writeByte(129)
      ..write(obj.preferNextUpPrepending)
      ..writeByte(130)
      ..write(obj.rememberLastUsedPlaybackActionRowPage)
      ..writeByte(131)
      ..write(obj.lastUsedPlaybackActionRowPage)
      ..writeByte(132)
      ..write(obj.accentColor)
      ..writeByte(133)
      ..write(obj.themeMode)
      ..writeByte(134)
      ..write(obj.locale)
      ..writeByte(135)
      ..write(obj.hasCompletedThemeModeLocaleMigration)
      ..writeByte(136)
      ..write(obj.systemAccentColor)
      ..writeByte(137)
      ..write(obj.useSystemAccentColor)
      ..writeByte(138)
      ..write(obj.useMonochromeIcon)
      ..writeByte(139)
      ..write(obj.lastUsedPlaybackActionRowPageForQueueMenu)
      ..writeByte(140)
      ..write(obj.radioEnabled)
      ..writeByte(141)
      ..write(obj.radioMode)
      ..writeByte(142)
      ..write(obj.duckOnAudioInterruption)
      ..writeByte(143)
      ..write(obj.forceAudioOffloadingOnAndroid)
      ..writeByte(144)
      ..write(obj.multichannelHandlingSetting)
      ..writeByte(145)
      ..write(obj.previousTracksPersistenceMode)
      ..writeByte(146)
      ..write(obj.homeScreenConfiguration)
      ..writeByte(147)
      ..write(obj.gridImageSize)
      ..writeByte(148)
      ..write(obj.amoledTheme)
      ..writeByte(149)
      ..write(obj.useAndroidGainEffect)
      ..writeByte(150)
      ..write(obj.homeScreenImageSize)
      ..writeByte(151)
      ..write(obj.clientCertificate)
      ..writeByte(152)
      ..write(obj.deviceId)
      ..writeByte(158)
      ..write(obj.verboseLogging)
      ..writeByte(159)
      ..write(obj.showQuickActionsBanner)
      ..writeByte(160)
      ..write(obj.perTabContentViewType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OriginalFinampSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// dart format on
