'use strict';
require('../support/phase175_prohibitions/runner.cjs').runProhibition({
  name: 'read-only observations must not submit a mutation',
  fixture: 'test/phase175_prohibitions/02-bad.json',
  target: 'test/scrypath_ops_web/live/sync_drift_live_test.exs:167',
  exunitName: 'rendered selection scopes both observations without submitting a mutation',
});
