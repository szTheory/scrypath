'use strict';
require('../support/phase175_prohibitions/runner.cjs').runProhibition({
  name: 'a task with a different UID must not replace the accepted swap task',
  fixture: 'test/phase175_prohibitions/04-bad.json',
  target: 'test/scrypath_ops_web/live/sync_drift_live_test.exs:733',
  exunitName: 'rendered promotion checks map exact terminal and unconfirmed responses',
});
