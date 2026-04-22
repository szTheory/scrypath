# Playbook JSON fixtures (optional)

This directory holds **optional** golden or negative JSON fixtures for **`ScrypathOps.Playbook.V1`**
tests. Most coverage builds maps **in-code** in **`test/scrypath_ops/playbook/v1_test.exs`** so
CI stays fast and deterministic.

When you add raw `*.json` files here, document whether each file is **valid** or **invalid**
per **`playbook-schema-v1.md`**, and reference them from the test that reads them.
