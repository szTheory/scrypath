'use strict';
require('../support/phase175_prohibitions/runner.cjs').runProhibition({
  name: 'server-side promotion handling must enforce the host authorization gate',
  fixture: 'test/phase175_prohibitions/05-bad.json',
  target: 'test/scrypath_ops_web/live/sync_drift_live_test.exs:1337',
  exunitName: 'swap live blocks impersonation before any refresh',
});
