"""Read-only replay against a disposable Jellyfin server containing fixtures/."""
import json
import os
from pathlib import Path
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

base = os.environ['JELLYFIN_URL'].rstrip('/')
assert urlparse(base).hostname in {'127.0.0.1', 'localhost'}, 'Use a disposable loopback server'
user = os.environ['JELLYFIN_USER_ID']
token = os.environ['JELLYFIN_TOKEN']
expected = json.loads(Path(__file__).with_name('jellyfin-api-probe.json').read_text())


def get(path, **params):
    request = Request(base + path + ('?' + urlencode(params) if params else ''), headers={
        'Authorization': f'MediaBrowser Client="Finamp1832Probe", Device="Fixture", '
                         f'DeviceId="1832", Version="1", Token="{token}"',
    })
    with urlopen(request, timeout=20) as response:
        return json.load(response)


all_tracks = get(f'/Users/{user}/Items', Recursive='true', IncludeItemTypes='Audio')
assert sorted(item['Name'] for item in all_tracks['Items']) == sorted(
    item['title'] for item in expected['fixture_tracks']), 'Unexpected fixture library'
views = get(f'/Users/{user}/Views')['Items']
library = next(item['Id'] for item in views if item['Name'] == 'Probe main')
artist = next(item['Id'] for item in get('/Artists', UserId=user)['Items'] if item['Name'] == 'Probe Target')
genres = {item['Name']: item['Id'] for item in get('/MusicGenres', UserId=user)['Items']}
recorded = {check['label']: check for check in expected['checks']}
mapping = {
    recorded['union']['query']['ArtistIds']: artist,
    recorded['union']['query']['ParentId']: library,
    recorded['genre-scoped union']['query']['GenreIds']: genres['Rock'],
    recorded['empty valid-filter count']['query']['GenreIds']: genres['Jazz'],
}
results = []
for check in expected['checks']:
    params = {key: mapping.get(value, value) for key, value in check['query'].items()}
    result = get(f'/Users/{user}/Items', **params)
    assert result['TotalRecordCount'] == check['total'], (check['label'], result)
    if 'Limit' not in params:
        assert sorted(item['Name'] for item in result['Items']) == check['names'], check['label']
    else:
        assert len(result['Items']) <= int(params['Limit']), check['label']
    results.append({'label': check['label'], 'total': result['TotalRecordCount'], 'returned': len(result['Items'])})
print(json.dumps({'version': get('/System/Info/Public')['Version'], 'checks': results}, indent=2))
