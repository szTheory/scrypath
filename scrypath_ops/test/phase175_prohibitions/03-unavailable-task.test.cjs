'use strict';
require('../support/phase175_prohibitions/runner.cjs').runProhibition({
  name: 'unavailable task observations must not be called completion',
  fixture: 'test/phase175_prohibitions/03-bad.json',
  target: 'test/scrypath_ops_web/live/phase175_fixture_live_test.exs:49',
  exunitName: 'rendered exact-UID checks keep queued, terminal, and unconfirmed task states distinct',
});
