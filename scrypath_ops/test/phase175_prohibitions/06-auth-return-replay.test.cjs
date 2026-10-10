'use strict';
require('../support/phase175_prohibitions/runner.cjs').runProhibition({
  name: 'refreshing an unconfirmed promotion must not replay a swap',
  fixture: 'test/phase175_prohibitions/06-bad.json',
  target: 'test/scrypath_ops_web/live/sync_drift_live_test.exs:1311',
  exunitName: 'refresh after an unconfirmed promotion checks state without submitting another swap',
});
