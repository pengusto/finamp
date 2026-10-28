import 'package:finamp/components/LayoutSettingsScreen/track_artist_order_selector.dart';
import 'package:finamp/components/PlayerScreen/artist_chip.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contribution_evidence_test.dart' as fixture;

void main() {
  fixture.main();
  testWidgets('artist order remains a selectable setting', (tester) async {
    final scope = await fixture.container();
    await fixture.mount(
      tester,
      scope,
      ListView(
        children: [
          const TrackArtistOrderSelector(),
          const Padding(padding: EdgeInsets.fromLTRB(16, 28, 16, 8), child: Text('Example song')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ArtistChips(baseItem: fixture.song),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Actual Finamp setting and ArtistChips widgets.\nSynthetic metadata; no live server.'),
          ),
        ],
      ),
      title: 'Layout & Theme · fixture',
    );
    await tester.tap(find.byType(DropdownMenu<TrackArtistOrder>));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Metadata order').hitTestable(), findsOneWidget);
    expect(find.text('Alphabetical').hitTestable(), findsOneWidget);
    await fixture.capture(tester, 'artist-order-settings');
  });
}
