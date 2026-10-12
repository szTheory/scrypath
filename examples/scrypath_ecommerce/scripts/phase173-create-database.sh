#!/bin/sh
set -eu

createdb -U "${POSTGRES_USER:-postgres}" scrypath_ops_phase173_test
