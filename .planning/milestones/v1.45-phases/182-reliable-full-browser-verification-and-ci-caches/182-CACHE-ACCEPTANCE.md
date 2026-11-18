---
phase: "182"
plan: "08"
status: accepted
source_sha: 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8
current_warm_source_sha: 1c72637038f2c225d56e2311678b05f912b014f3
repository: szTheory/scrypath
branch: worktree-agent-p182-final-review-repair
session_id: phase182-review-repair-0b7fe128-20261027T201345Z
probe_namespace: candidate-556416f7
---

# Phase 182 — Cache acceptance

## Supplemental current-source warm proof

The only non-planning change from `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` to `1c72637038f2c225d56e2311678b05f912b014f3` is the WR-02 settings assertion line in `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts` (fix `30becbc4`). It now uses an actual RegExp for both rendered status strings; it cannot pass by locating numeric text. The source-derived RED/GREEN logs and 115 passing Node checks are retained outside the checkout.

PROJECT's named-invalidator policy reuses passing evidence within its source/scenario boundaries. Cache implementation/configuration, Dockerfiles, dependencies/locks and BEAM graph inputs are unchanged. An exact file-tree comparison excluding only that spec passed; rebuilding the original hosted BEAM identity from current input bytes produced the identical manifest, lock and source digests (this is input parity at the original tuple, not a new hosted BEAM run). The spec is outside all four BEAM source graphs. The changed browser image input is covered by the new strict warm receipt; local and hosted full execution cover the stronger assertion.

The complete five-mode cache aggregate remains valid at `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` with seven recorded invocations (six eligible). The new two-invocation session at `1c72637038f2c225d56e2311678b05f912b014f3` has a strict eligible warm receipt and a valid full aggregate. No five-mode cache aggregate at the newer SHA is claimed, no receipts cross source/session identities, and no acceptance predicate was changed. Earlier full passes are not relabeled as proof of the corrected assertion.

Current run [40597095307](https://github.com/szTheory/scrypath/actions/runs/40597095307) / attempt 1 at `1c72637038f2c225d56e2311678b05f912b014f3`: [12777840996](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12777840996) `sha256:bf200d90ae10a58885c2c3a301c9238ee7df0d64ce87bd9e80ca73eed2ef8eaa`. Receipt SHA-256 `0b36049c9f184f12d77847649cd3f1013c8fdcd5581b388c1cdbb96c3cd9cf17`; raw cache log SHA-256 `2e9290658b10605fb3cc052d3d743862d06037c456526d8f50f900bc2f0dee1a`. The canonical collector accepted actual GHA imports, useful cached vertices and completed exports for all three targets, with checked recipe/image attribution and normal verifier success.

```json
{
  "source_sha": "1c72637038f2c225d56e2311678b05f912b014f3",
  "run_id": "40597095307",
  "target_scopes": {
    "browser": "scrypath-ecommerce-browser-v1-phase182-candidate-556416f7",
    "standalone_ops": "scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7",
    "web": "scrypath-ecommerce-app-v1-phase182-candidate-556416f7"
  },
  "recipe_ids": {
    "browser": "sha256:2631878451eecd4439035da289b3ce22e195773bbf462b2f7a4afd0bc9b50495",
    "standalone_ops": "sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85",
    "web": "sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85"
  },
  "image_ids": {
    "browser": "sha256:027c5767bb099b6ce408840a28cd12285f1abf16a13c75b2ae9373914dd53744",
    "standalone_ops": "sha256:da86d633cf25c4620cc17cc3f4bce12c8f5f40823207e517f11320482e54c74a",
    "web": "sha256:da86d633cf25c4620cc17cc3f4bce12c8f5f40823207e517f11320482e54c74a"
  },
  "progress": {
    "browser": {
      "imports": [
        {
          "id": "10",
          "outcome": "DONE"
        }
      ],
      "cached_steps": [
        "17",
        "18",
        "19"
      ],
      "shared_cached_steps": [],
      "exports": [
        {
          "id": "42",
          "outcome": "DONE"
        }
      ]
    },
    "standalone_ops": {
      "imports": [
        {
          "id": "15",
          "outcome": "DONE"
        }
      ],
      "cached_steps": [
        "20",
        "21",
        "22",
        "23",
        "24",
        "25"
      ],
      "shared_cached_steps": [],
      "exports": [
        {
          "id": "34",
          "outcome": "DONE"
        }
      ]
    },
    "web": {
      "imports": [
        {
          "id": "16",
          "outcome": "DONE"
        }
      ],
      "cached_steps": [],
      "shared_cached_steps": [
        {
          "from": "standalone_ops",
          "steps": [
            "20",
            "21",
            "22",
            "23",
            "24",
            "25"
          ]
        }
      ],
      "exports": [
        {
          "id": "35",
          "outcome": "DONE"
        }
      ]
    }
  }
}
```

The following unchanged five-mode record retains its original source and aggregate command.

Frozen implementation: `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` on `worktree-agent-p182-final-review-repair`. All six accepted invocations join this repository, source, branch, session and namespace. These records do not relabel implementation evidence for later documentation or root commits. Terminal closeout receipts are kept outside the checkout after all tracked writes.

Session root: `/private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session`. Authority is the manifest-listed receipt set, not loose files or a green workflow conclusion.

| Mode / run | Receipt SHA-256 | Cache artifact / digest | Raw cache log SHA-256 |
| --- | --- | --- | --- |
| `docker-warm` [40579526346](https://github.com/szTheory/scrypath/actions/runs/40579526346) attempt 1 | `2b3d0fc303a9dd9a4f6ef4535e63960ffdec644fb145e80a51389702a4a9dccb` | [12769242943](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12769242943) `sha256:ad173c608857f86529eb46846c04d6271dfd3af33675631f34b9e454d3ae52ff` | `69784960c6e227b82b0bca0608319a3d08d7b573c2dac00e65ea4584aba2149b` |
| `docker-cold` [40581822603](https://github.com/szTheory/scrypath/actions/runs/40581822603) attempt 1 | `fa9f99de11a30ccd10f0070ba9c1087cc26983be5983f017854435405e382f4e` | [12769698838](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12769698838) `sha256:9f8f7704c77ab449e762554da988700739ef262b801ba485b3d467c532aa7ba0` | `c2c2d0f4f71983837c7422a5e6a72a3dae7646d2662536bd347c1f7a978efff3` |
| `beam-fallback` [40583923065](https://github.com/szTheory/scrypath/actions/runs/40583923065) attempt 1 | `18a37dadad86ceb6c59682bbfc19dd739f2a5cfd30538002be36933598d34ef7` | [12771065695](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12771065695) `sha256:e0cfd08160baa1fc74c493af12c8801e2036c44ad6fc14ec640b80f4f65a02dc` | `a2ffe3f623501a16b9753530812dd967392de5486af8d0a15f68dbc8040b0a7c` |
| `beam-lock-change` [40586263728](https://github.com/szTheory/scrypath/actions/runs/40586263728) attempt 1 | `d82a227eaac928df78f0f6fb3fb6289035f7d15baaa62eb703f9b37baba0a848` | [12772537028](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12772537028) `sha256:f6719449cd46aae18d7646ed0bdef163fdf00ddafe8c0401e70a716b08fcda28` | `40fdbeb36467d22edb5f68d7e4d9052a66e68adc9f5bc98b9124b38aa1211460` |
| `beam-cold` [40588198343](https://github.com/szTheory/scrypath/actions/runs/40588198343) attempt 1 | `ddd3e94e1fbcc1b6b44e6330cbef08247b7080ddc629345e0a80d33d0cf92754` | [12772534177](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12772534177) `sha256:81ddfb7e09c941c84c99b0dc25093e9c6d9dac37b8db9530c9bfcda1e98f9b5b` | `6c8489bdf071579d5e964996f118382fce9231384516e1d7cd4da3c9eb2500d5` |

The current branch was populated by [40576150719](https://github.com/szTheory/scrypath/actions/runs/40576150719) at the same frozen source. That initial no-hit run failed warm acceptance but completed all three exports and populated the actual branch-scoped Docker/BEAM caches. Its ineligible receipt is preserved in this candidate session; current warm acceptance uses the following independently dispatched consumer, with useful cache hits required. The older 556416f7 producer remains historical evidence for its earlier branch only.

Docker warm requires real GHA imports, useful cached vertices and completed exports for browser, web and standalone_ops. Shared vertices count only for identical checked recipe/image IDs. Docker cold records a new nonpersistent docker-container builder with no configured/imported cache and successful mounted verification. BEAM fallback uses a compatible download prefix and a separate forced primary miss. Lock-change uses a run-bound comment-only byte change in an owned checkout, with exact before/after bytes bound to canonical identities and different natural lock-derived keys. Its resolved key has no forced run suffix; normal compatible download fallback remains available. Source lock and dependency versions are unchanged. BEAM cold disables both restores on a fresh hosted runner and still executes deps.get, compile and core verification. Lock-change before/after hashes are raw lock measurements; identity.locks_digest is the separate canonical planner digest and is not conflated with them.

## docker-warm

Job `ecommerce-e2e (advisory)` / `122454850880` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "builder": null,
  "configuration": {
    "kind": "buildkit",
    "imports_enabled": true,
    "actual_import": true,
    "actual_export": true,
    "imported_digest": "sha256:9ef0ea053050fdad4c00c5d657b583192b375adfbb24a46054dcadf4fd8a0919",
    "exported_digest": "sha256:7298d28b9ee9849b447ffc9c16bdd43520a52293ce4c4638392a5086f14f3f4e",
    "importer": "gha",
    "exporter": "gha",
    "scope": "full",
    "expected_targets": [
      "browser",
      "standalone_ops",
      "web"
    ],
    "target_scopes": {
      "browser": "scrypath-ecommerce-browser-v1-phase182-candidate-556416f7",
      "standalone_ops": "scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7",
      "web": "scrypath-ecommerce-app-v1-phase182-candidate-556416f7"
    },
    "target_cache_settings": {
      "browser": {
        "import": [
          "type=gha,scope=scrypath-ecommerce-browser-v1-phase182-candidate-556416f7,version=2,timeout=120s"
        ],
        "export": [
          "type=gha,scope=scrypath-ecommerce-browser-v1-phase182-candidate-556416f7,version=2,mode=max,timeout=120s"
        ]
      },
      "standalone_ops": {
        "import": [
          "type=gha,scope=scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7,version=2,timeout=120s"
        ],
        "export": [
          "type=gha,scope=scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7,version=2,mode=max,timeout=120s"
        ]
      },
      "web": {
        "import": [
          "type=gha,scope=scrypath-ecommerce-app-v1-phase182-candidate-556416f7,version=2,timeout=120s"
        ],
        "export": [
          "type=gha,scope=scrypath-ecommerce-app-v1-phase182-candidate-556416f7,version=2,mode=max,timeout=120s"
        ]
      }
    },
    "recipe_digest": "sha256:850a07a283daf5c5e2bb29cdd38dda7843f074e86c6bad6b30afe36adf6e1b95",
    "recipe_ids": {
      "browser": "sha256:2631878451eecd4439035da289b3ce22e195773bbf462b2f7a4afd0bc9b50495",
      "standalone_ops": "sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85",
      "web": "sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85"
    },
    "image_ids": {
      "browser": "sha256:a1b1226eba071842f3cc69e9a4566bb2d2974eb1e418a3cc7037d2115e5d7379",
      "standalone_ops": "sha256:2824c2ad0c16179d2124632af4f829c62011a9e4af90d227ebb8d7e1f0e1ac17",
      "web": "sha256:2824c2ad0c16179d2124632af4f829c62011a9e4af90d227ebb8d7e1f0e1ac17"
    },
    "import_scopes": [
      "scrypath-ecommerce-app-v1-phase182-candidate-556416f7",
      "scrypath-ecommerce-browser-v1-phase182-candidate-556416f7",
      "scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7"
    ],
    "export_scopes": [
      "scrypath-ecommerce-app-v1-phase182-candidate-556416f7",
      "scrypath-ecommerce-browser-v1-phase182-candidate-556416f7",
      "scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7"
    ],
    "cached_steps_digest": "sha256:03ef5c8ed76cd88515ed370cf2e1371bfd3b2cfe35bf83bc2edb154687618dcf",
    "cache_binding_digest": "sha256:5421f8d6122559afed1c2da48d97b25eaedc063f2c66468e580295e2ee5a7439",
    "progress": {
      "browser": {
        "imports": [
          {
            "id": "13",
            "outcome": "DONE"
          }
        ],
        "cached_steps": [
          "17",
          "18",
          "19",
          "20",
          "21"
        ],
        "shared_cached_steps": [],
        "exports": [
          {
            "id": "42",
            "outcome": "DONE"
          }
        ]
      },
      "standalone_ops": {
        "imports": [
          {
            "id": "15",
            "outcome": "DONE"
          }
        ],
        "cached_steps": [],
        "shared_cached_steps": [
          {
            "from": "web",
            "steps": [
              "22",
              "23",
              "24",
              "25",
              "26",
              "27",
              "28",
              "29"
            ]
          }
        ],
        "exports": [
          {
            "id": "40",
            "outcome": "DONE"
          }
        ]
      },
      "web": {
        "imports": [
          {
            "id": "16",
            "outcome": "DONE"
          }
        ],
        "cached_steps": [
          "22",
          "23",
          "24",
          "25",
          "26",
          "27",
          "28",
          "29"
        ],
        "shared_cached_steps": [],
        "exports": [
          {
            "id": "38",
            "outcome": "DONE"
          }
        ]
      }
    },
    "log_sha256": "69784960c6e227b82b0bca0608319a3d08d7b573c2dac00e65ea4584aba2149b"
  },
  "commands": {
    "primary_verification": "success"
  }
}
```

## docker-cold

Job `ecommerce-mounted (required)` / `122462933006` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "builder": {
    "id": "scrypath-mounted-40581822603-1",
    "created_for_run_id": "40581822603",
    "created_for_attempt": 1,
    "created_at": "2026-10-27T20:56:46.965Z",
    "driver": "docker-container",
    "cache_from": [],
    "fresh": true,
    "persistent": false,
    "baseline_names": [
      "default",
      "default"
    ]
  },
  "configuration": {
    "kind": "buildkit",
    "imports_enabled": false,
    "actual_import": false,
    "actual_export": false,
    "imported_digest": null,
    "exported_digest": null,
    "importer": null,
    "exporter": null,
    "scope": "focused",
    "expected_targets": [
      "browser",
      "web"
    ],
    "target_scopes": {
      "browser": "scrypath-ecommerce-browser-v1",
      "web": "scrypath-ecommerce-app-v1"
    },
    "target_cache_settings": {
      "browser": {
        "import": [],
        "export": []
      },
      "web": {
        "import": [],
        "export": []
      }
    },
    "recipe_digest": "sha256:f8e7252726b191801b97fbb443763841bbc1c675ff4a9ed88eb5ee77901a25c8",
    "recipe_ids": {
      "browser": "sha256:2631878451eecd4439035da289b3ce22e195773bbf462b2f7a4afd0bc9b50495",
      "web": "sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85"
    },
    "image_ids": {
      "browser": "sha256:b26d9a02f92e030cb330b481452ba4fe5cbc37ec05d15b3db89c7da5c9bf186d",
      "web": "sha256:5322954e3e672c2c8f60cbc8326f0b3b6a268becbd620e4a6876cf8591315f28"
    },
    "import_scopes": [],
    "export_scopes": [],
    "miss_reason": "fresh builder with BuildKit cache imports disabled",
    "cached_steps_digest": null,
    "cache_binding_digest": null,
    "progress": {
      "browser": {
        "imports": [],
        "cached_steps": [],
        "shared_cached_steps": [],
        "exports": []
      },
      "web": {
        "imports": [],
        "cached_steps": [],
        "shared_cached_steps": [],
        "exports": []
      }
    },
    "log_sha256": "c2c2d0f4f71983837c7422a5e6a72a3dae7646d2662536bd347c1f7a978efff3"
  },
  "commands": {
    "primary_verification": "success"
  }
}
```

## beam-fallback

Job `core (required)` / `122470283106` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "identity": {
    "cache_schema": "beam-v1",
    "graph": "root",
    "runner_image": "ubuntu24/20261026.354.1",
    "os": "Linux",
    "arch": "X64",
    "elixir": "1.19.0",
    "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
    "mix_env": "test",
    "mix_target": "host",
    "profile": "root-test",
    "manifests_digest": "98b7f18c837f9cd074d6e8259e213db1e57169cceb846554ff563755a731560c",
    "locks_digest": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
    "source_digest": "cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6"
  },
  "runtime": {
    "runner_image": "ubuntu24/20261026.354.1",
    "os": "Linux",
    "arch": "X64",
    "elixir": "1.19.0",
    "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
    "mix_env": "test",
    "mix_target": "host",
    "profile": "root-test"
  },
  "downloads_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-40583923065-1",
  "downloads_restore_prefix": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-",
  "downloads_restore_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "downloads_hit": false,
  "downloads_restored": true,
  "resolved_key": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6-phase182-40583923065-1",
  "resolved_restore_prefix": "",
  "resolved_restore_key": null,
  "resolved_hit": false,
  "fallback": true,
  "lock_before": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "lock_after": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "runner": {
    "fresh": true,
    "id": "GitHub Actions 1000206792 40583923065/1",
    "created_for_run_id": "40583923065",
    "created_for_attempt": 1
  },
  "commands": {
    "deps_get": "success",
    "compile": "success",
    "verify": "success",
    "primary_verification": "success"
  }
}
```

## beam-lock-change

Job `core (required)` / `122478333594` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "identity": {
    "cache_schema": "beam-v1",
    "graph": "root",
    "runner_image": "ubuntu24/20261026.354.1",
    "os": "Linux",
    "arch": "X64",
    "elixir": "1.19.0",
    "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
    "mix_env": "test",
    "mix_target": "host",
    "profile": "root-test",
    "manifests_digest": "98b7f18c837f9cd074d6e8259e213db1e57169cceb846554ff563755a731560c",
    "locks_digest": "3aed20c3af2a3170c0dfe9ec4dee751626d1870650da6d401550423a8d134db9",
    "source_digest": "cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6"
  },
  "runtime": {
    "runner_image": "ubuntu24/20261026.354.1",
    "os": "Linux",
    "arch": "X64",
    "elixir": "1.19.0",
    "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
    "mix_env": "test",
    "mix_target": "host",
    "profile": "root-test"
  },
  "downloads_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-3aed20c3af2a3170c0dfe9ec4dee751626d1870650da6d401550423a8d134db9",
  "downloads_restore_prefix": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-",
  "downloads_restore_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-40583923065-1",
  "downloads_hit": false,
  "downloads_restored": true,
  "resolved_key": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-3aed20c3af2a3170c0dfe9ec4dee751626d1870650da6d401550423a8d134db9-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6",
  "resolved_restore_prefix": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-3aed20c3af2a3170c0dfe9ec4dee751626d1870650da6d401550423a8d134db9-phase182-candidate-556416f7-",
  "resolved_restore_key": null,
  "resolved_hit": false,
  "fallback": true,
  "lock_before": "bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8",
  "lock_after": "f9428aca8750f010eb2e18bb882f4bc1eced7860d136219a6e7cf98839b79015",
  "lock_probe": {
    "owned_copy": true,
    "source_lock_unchanged": true,
    "versions_unchanged": true,
    "baseline_identity": {
      "cache_schema": "beam-v1",
      "graph": "root",
      "runner_image": "ubuntu24/20261026.354.1",
      "os": "Linux",
      "arch": "X64",
      "elixir": "1.19.0",
      "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
      "mix_env": "test",
      "mix_target": "host",
      "profile": "root-test",
      "manifests_digest": "98b7f18c837f9cd074d6e8259e213db1e57169cceb846554ff563755a731560c",
      "locks_digest": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
      "source_digest": "cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6"
    },
    "changed_identity": {
      "cache_schema": "beam-v1",
      "graph": "root",
      "runner_image": "ubuntu24/20261026.354.1",
      "os": "Linux",
      "arch": "X64",
      "elixir": "1.19.0",
      "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
      "mix_env": "test",
      "mix_target": "host",
      "profile": "root-test",
      "manifests_digest": "98b7f18c837f9cd074d6e8259e213db1e57169cceb846554ff563755a731560c",
      "locks_digest": "3aed20c3af2a3170c0dfe9ec4dee751626d1870650da6d401550423a8d134db9",
      "source_digest": "cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6"
    },
    "baseline_resolved_key": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6",
    "changed_resolved_key": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-3aed20c3af2a3170c0dfe9ec4dee751626d1870650da6d401550423a8d134db9-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6"
  },
  "runner": {
    "fresh": true,
    "id": "GitHub Actions 1000206808 40586263728/1",
    "created_for_run_id": "40586263728",
    "created_for_attempt": 1
  },
  "commands": {
    "deps_get": "success",
    "compile": "success",
    "verify": "success",
    "primary_verification": "success"
  }
}
```

## beam-cold

Job `core (required)` / `122485208685` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "identity": {
    "cache_schema": "beam-v1",
    "graph": "root",
    "runner_image": "ubuntu24/20261023.334.3",
    "os": "Linux",
    "arch": "X64",
    "elixir": "1.19.0",
    "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
    "mix_env": "test",
    "mix_target": "host",
    "profile": "root-test",
    "manifests_digest": "98b7f18c837f9cd074d6e8259e213db1e57169cceb846554ff563755a731560c",
    "locks_digest": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
    "source_digest": "cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6"
  },
  "runtime": {
    "runner_image": "ubuntu24/20261023.334.3",
    "os": "Linux",
    "arch": "X64",
    "elixir": "1.19.0",
    "otp": "Erlang/OTP 28 [erts-16.1.1] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [jit:ns]",
    "mix_env": "test",
    "mix_target": "host",
    "profile": "root-test"
  },
  "downloads_key": "beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "downloads_restore_prefix": "beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-",
  "downloads_restore_key": null,
  "downloads_hit": false,
  "downloads_restored": false,
  "resolved_key": "beam-v1-resolved-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6",
  "resolved_restore_prefix": "beam-v1-resolved-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-",
  "resolved_restore_key": null,
  "resolved_hit": false,
  "fallback": false,
  "lock_before": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "lock_after": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "runner": {
    "fresh": true,
    "id": "GitHub Actions 1000206832 40588198343/1",
    "created_for_run_id": "40588198343",
    "created_for_attempt": 1
  },
  "commands": {
    "deps_get": "success",
    "compile": "success",
    "verify": "success",
    "primary_verification": "success"
  }
}
```

## Machine authority

```sh
node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session
```

Result: valid and eligible, seven recorded invocations (six eligible). Aggregate SHA-256: `2a11084ef3e14c7a7f689be19a715d40dd1190082dcd09a5dd399a32feab4e3e`.

## Preserved history and limits

Initial corrected-source run [40576150719](https://github.com/szTheory/scrypath/actions/runs/40576150719) passed browser189/189 but failed warm acceptance because all three imports had zero useful cached vertices. All three exports completed without warnings; actual cache inventory binds the resulting Docker and BEAM caches to the new repair branch. [GitHub cache branch restrictions](https://docs.docker.com/build/cache/backends/gha/#scope) prevented the older worktree branch from seeding this branch. After checking that changed cache state, a new warm consumer was collected in the SAME candidate session. The first ineligible receipt remains in the manifest and atomic attempt history; it is a cache producer, never clean warm acceptance. No browser retry or acceptance predicate was changed.

The EC cohort and final child [40569345202](https://github.com/szTheory/scrypath/actions/runs/40569345202) at f2226d12 passed their recorded predicates and full189/189. Final review then exposed three source-level predicate gaps and a redirect-readiness warning. RED/GREEN commits a64f15d2..01d1f871 fixed loopback refusal, exact required UI identities, canonical changed-lock identity/natural-key proof and 2xx readiness; correction review found zero open findings. Those prior receipts are not proof for the corrected source. The current six-mode cohort below was collected after all four fixes, at one frozen source. Original EC documents remain in Git at f2226d12; original manifests, archives and failed attempts remain outside the checkout.

Earlier candidates and failures remain in `/private/tmp/scrypath-phase182-acceptance` and `/private/tmp/scrypath-phase182-local-e2e-failures`. The earlier e37 six-mode set remains valid only for e37; its recorded documents are preserved at [8b34f545](https://github.com/szTheory/scrypath/tree/8b34f5452e254d9aeda6bc2ed0394304bb5e91b6/.planning/phases/182-reliable-full-browser-verification-and-ci-caches).

Closeout [40551292192](https://github.com/szTheory/scrypath/actions/runs/40551292192) passed its five required jobs, coverage and attestation at 8b34f545, but its full advisory job failed after browser success: the producer wrongly required exports under an ordinary import-only branch policy. Regression `851c0456` reproduced it; `7f8c4592` lets observation generation honor the checked policy while strict warm acceptance still requires actual imports and exports. The immutable old handoff replay reproduces the old failure and corrected behavior; it is not new-source hosted acceptance. The later EC receipts established that correction at their own source.

Older metadata lag, whole-run log ZIP transport failures, selector/handoff repairs, incomplete 900-second local attempts and their later source revisions are not rewritten as clean stability evidence. Source-bound history and failures remain visible in the prior documents and runtime directories. The known deep-quality dependency audit debt remains Phase 184; this report does not say every advisory CI job is green.

No paid judge, retry/skip masking, automatic baseline rewrite, UI redesign, new dependency, required-lane change or retained-preview mutation was used. This is representative maintainer/demo evidence at the stated source and toolchain, not outside-adopter or universal production reliability evidence. Descriptor-less/unclassified planning assumptions remain flagged as such; no human approval or design review is fabricated.
