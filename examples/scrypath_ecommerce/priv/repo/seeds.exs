# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ScrypathEcommerce.Repo.insert!(%ScrypathEcommerce.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# D-07: Use pure Elixir function factories (*Fixtures modules) as the single source of truth.
# Seeding will be done via `mix scrypath.seed`
