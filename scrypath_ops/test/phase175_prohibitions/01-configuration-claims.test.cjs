'use strict';
require('../support/phase175_prohibitions/runner.cjs').runProhibition({
  name: 'configuration agreement must not claim document freshness',
  fixture: 'test/phase175_prohibitions/01-bad.json',
  target: 'test/scrypath_ops_web/live/sync_drift_live_test.exs:270',
  exunitName: 'matching configuration keeps comparison details optional and does not claim freshness',
});
