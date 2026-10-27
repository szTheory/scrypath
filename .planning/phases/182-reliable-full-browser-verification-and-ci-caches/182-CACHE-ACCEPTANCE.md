---
phase: "182"
plan: "08"
status: accepted
source_sha: ec248fd2f7eea9314e600bcc10262729d2cce69e
repository: szTheory/scrypath
branch: worktree-agent-p182-08-1793071051075
session_id: phase182-08-ec248fd2-20261027T175951Z
probe_namespace: candidate-556416f7
---

# Phase 182 — Cache acceptance

**Final-review repair checkpoint (2026-10-27):** This record preserves the prior EC source evidence. The later final review found three source-level blockers and one readiness warning; eight test/fix commits now correct them at `01d1f871`. Those earlier runs do not prove the corrected source. New local/hosted acceptance and final-root closeout remain pending; no phase completion is claimed. See 182-REVIEW-REPAIR.md.

Frozen implementation: `ec248fd2f7eea9314e600bcc10262729d2cce69e` on `worktree-agent-p182-08-1793071051075`. All six accepted invocations join this repository, source, branch, session and namespace. These records do not relabel implementation evidence for later documentation or root commits. Terminal closeout receipts are kept outside the checkout after all tracked writes.

Session root: `/private/tmp/scrypath-phase182-acceptance/ec248fd2f7eea9314e600bcc10262729d2cce69e/phase182-08-ec248fd2-20261027T175951Z/collector-session`. Authority is the manifest-listed receipt set, not loose files or a green workflow conclusion.

| Mode / run | Receipt SHA-256 | Cache artifact / digest | Raw cache log SHA-256 |
| --- | --- | --- | --- |
| `docker-warm` [40555796347](https://github.com/szTheory/scrypath/actions/runs/40555796347) attempt 1 | `17af6da379877c5c606a7f8b56a971d812fe6f865b0c33b7fab137338b808e01` | [12758366037](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12758366037) `sha256:b3991db7d363a47a70c4496492b12285678efc247b9b08465e368c1d2bea5fea` | `b200d298f4ed23a3b6f121d9ad5c44ccdb835924898ec5a97dbbc6a6276faaa1` |
| `docker-cold` [40557917007](https://github.com/szTheory/scrypath/actions/runs/40557917007) attempt 1 | `281649045a7ac20d7a29bac58af178e663b1391f00c4318c86cecd850e6511a6` | [12758441328](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12758441328) `sha256:f8b32dcc735098ebb2a8d28221eec042196d26f2cd12b180514561ae8d594dbe` | `088c4f98ad0ccfee18ed0db8a6f37c4012312796d6b2d4db90c8cb74f582ffab` |
| `beam-fallback` [40560404622](https://github.com/szTheory/scrypath/actions/runs/40560404622) attempt 1 | `de83311f5ba475ac8c5bd3f2c5d648aed3afcb271e7449767d4dee9acef1c230` | [12761705064](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12761705064) `sha256:755644174077f2e5d843b7573e05b47b79c00aecbbda7cac4710744ab1ac8393` | `c23c5eb7b33d860646a41ac4b056b48d21470710372ae7d6a04e1e02fb766f92` |
| `beam-lock-change` [40562897988](https://github.com/szTheory/scrypath/actions/runs/40562897988) attempt 1 | `a8580e79f46673024cd029fc3f076f4189eaf8e597d0889db38717b84f49d789` | [12761028651](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12761028651) `sha256:6108c6191dccace7ce6cbf52440a1511d47d52a21a9d13c51dd1a837c94c432d` | `a3c8a5cc8a44b6be29d9e4ffceeba8afd4ed1c57bf96b09d82b1ed28e20cbad6` |
| `beam-cold` [40565218236](https://github.com/szTheory/scrypath/actions/runs/40565218236) attempt 1 | `de00b71cc28633077da9dc4c06654bbf01bf11544ad52f5c30227312345b6b86` | [12762797114](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12762797114) `sha256:d3b9106207b8ad4bc5462f6c8aa7f10ff7540769810bcda0ff9f5fb50b0320ee` | `3e3668816c037a4c98c3ba4469c0f750ac00b135eb5e24362f3c34697e3d4a53` |

The isolated namespace was originally populated by successful normal run [40530439125](https://github.com/szTheory/scrypath/actions/runs/40530439125) at source 556416f7. Its three exports are confirmed by the actual handoff/raw log replay, but its collector log-transport failure remains ineligible. Later consumers must bind their own source, recipes, image IDs and runtime; the seed is not acceptance for EC.

Docker warm requires real GHA imports, useful cached vertices and completed exports for browser, web and standalone_ops. Shared vertices count only for identical checked recipe/image IDs. Docker cold records a new nonpersistent docker-container builder with no configured/imported cache and successful mounted verification. BEAM fallback/lock probes use compatible download prefixes and forced unique compiled misses; lock-change uses an owned comment-only byte change, leaving source lock and dependency versions unchanged. BEAM cold disables both restores on a fresh hosted runner and still executes deps.get, compile and core verification. Lock-change before/after hashes are raw lock measurements; identity.locks_digest is the separate canonical planner digest and is not conflated with them.

## docker-warm

Job `ecommerce-e2e (advisory)` / `122371413699` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "builder": null,
  "configuration": {
    "kind": "buildkit",
    "imports_enabled": true,
    "actual_import": true,
    "actual_export": true,
    "imported_digest": "sha256:4833f4de6834d76469ec237db29be87656b788575224d82e8ca1c05a8f534b8d",
    "exported_digest": "sha256:09c2b365a4b140670de6db868ebe0290e84f64b019905b5abe62c880d0868cb9",
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
      "browser": "sha256:314c18788c267889d90c8c5ab574414d4f47ccc296cf01c46738eaeda2e93b6f",
      "standalone_ops": "sha256:6e4c34741f6d80118249c2c0b082acb6f06b40a84156e8f45429bd7356121b71",
      "web": "sha256:6e4c34741f6d80118249c2c0b082acb6f06b40a84156e8f45429bd7356121b71"
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
    "cached_steps_digest": "sha256:d2bc12b25ccde1ec96da91bccb530bb15d8a187c575496cc97262815e95408dc",
    "cache_binding_digest": "sha256:8ccaaa07ef3eb7d1ce659b80b805e22cf7316d5499317650ead8335f3d2af5ee",
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
          "19"
        ],
        "shared_cached_steps": [],
        "exports": [
          {
            "id": "38",
            "outcome": "DONE"
          }
        ]
      },
      "standalone_ops": {
        "imports": [
          {
            "id": "16",
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
            "id": "39",
            "outcome": "DONE"
          }
        ]
      },
      "web": {
        "imports": [
          {
            "id": "15",
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
            "id": "40",
            "outcome": "DONE"
          }
        ]
      }
    },
    "log_sha256": "b200d298f4ed23a3b6f121d9ad5c44ccdb835924898ec5a97dbbc6a6276faaa1"
  },
  "commands": {
    "primary_verification": "success"
  }
}
```

## docker-cold

Job `ecommerce-mounted (required)` / `122378842507` completed successfully; the ordinary verification command outcome was `success`.

```json
{
  "builder": {
    "id": "scrypath-mounted-40557917007-1",
    "created_for_run_id": "40557917007",
    "created_for_attempt": 1,
    "created_at": "2026-10-27T18:19:00.452Z",
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
      "browser": "sha256:385c06d2adde0528e32e0ec7162a1bf60509e74c33a20b2a6d8b22a8db7e2dd0",
      "web": "sha256:2dfd062cd8caff0694e9771515a7da7d8d6a3129078db5033be53fa658edfab5"
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
    "log_sha256": "088c4f98ad0ccfee18ed0db8a6f37c4012312796d6b2d4db90c8cb74f582ffab"
  },
  "commands": {
    "primary_verification": "success"
  }
}
```

## beam-fallback

Job `core (required)` / `122387575380` completed successfully; the ordinary verification command outcome was `success`.

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
  "downloads_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-40560404622-1",
  "downloads_restore_prefix": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-",
  "downloads_restore_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "downloads_hit": false,
  "downloads_restored": true,
  "resolved_key": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6-phase182-40560404622-1",
  "resolved_restore_prefix": "",
  "resolved_restore_key": null,
  "resolved_hit": false,
  "fallback": true,
  "lock_before": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "lock_after": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "runner": {
    "fresh": true,
    "id": "GitHub Actions 1000206494 40560404622/1",
    "created_for_run_id": "40560404622",
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

Job `core (required)` / `122396413316` completed successfully; the ordinary verification command outcome was `success`.

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
    "locks_digest": "b54667e33bdf3c5c5fdc527d209d3d479fcebe7ba5f8160e241dce5c8cb68a32",
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
  "downloads_key": "beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-b54667e33bdf3c5c5fdc527d209d3d479fcebe7ba5f8160e241dce5c8cb68a32-phase182-40562897988-1",
  "downloads_restore_prefix": "beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-",
  "downloads_restore_key": "beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-b234711300128b0e0757dc6e4f89e6ca40314bbcd6672be3ec72581544841fd5-phase182-40540687164-1",
  "downloads_hit": false,
  "downloads_restored": true,
  "resolved_key": "beam-v1-resolved-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-b54667e33bdf3c5c5fdc527d209d3d479fcebe7ba5f8160e241dce5c8cb68a32-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6-phase182-40562897988-1",
  "resolved_restore_prefix": "",
  "resolved_restore_key": null,
  "resolved_hit": false,
  "fallback": true,
  "lock_before": "bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8",
  "lock_after": "7da9d0ee73dc6a0e43d60f28a5a473c32e89f78b45664e81fd748fd2e25937b3",
  "lock_probe": {
    "owned_copy": true,
    "source_lock_unchanged": true,
    "versions_unchanged": true
  },
  "runner": {
    "fresh": true,
    "id": "GitHub Actions 1000206541 40562897988/1",
    "created_for_run_id": "40562897988",
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

Job `core (required)` / `122404560725` completed successfully; the ordinary verification command outcome was `success`.

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
  "downloads_key": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "downloads_restore_prefix": "beam-v1-downloads-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-phase182-candidate-556416f7-",
  "downloads_restore_key": null,
  "downloads_hit": false,
  "downloads_restored": false,
  "resolved_key": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6",
  "resolved_restore_prefix": "beam-v1-resolved-9cab62e409f6455b317d4f9d2c433907f954fca4f8aae3f49486d0842d20e670-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-candidate-556416f7-",
  "resolved_restore_key": null,
  "resolved_hit": false,
  "fallback": false,
  "lock_before": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "lock_after": "587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6",
  "runner": {
    "fresh": true,
    "id": "GitHub Actions 1000206563 40565218236/1",
    "created_for_run_id": "40565218236",
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
node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha ec248fd2f7eea9314e600bcc10262729d2cce69e --session-id phase182-08-ec248fd2-20261027T175951Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/ec248fd2f7eea9314e600bcc10262729d2cce69e/phase182-08-ec248fd2-20261027T175951Z/collector-session
```

Result: valid and eligible, six invocations. Aggregate SHA-256: `313ae26f764185be4b637cba327c5063e357448a4bcc22e339c8039169f853ba`.

## Preserved history and limits

Earlier candidates and failures remain in `/private/tmp/scrypath-phase182-acceptance` and `/private/tmp/scrypath-phase182-local-e2e-failures`. The earlier e37 six-mode set remains valid only for e37; its recorded documents are preserved at [8b34f545](https://github.com/szTheory/scrypath/tree/8b34f5452e254d9aeda6bc2ed0394304bb5e91b6/.planning/phases/182-reliable-full-browser-verification-and-ci-caches).

Closeout [40551292192](https://github.com/szTheory/scrypath/actions/runs/40551292192) passed its five required jobs, coverage and attestation at 8b34f545, but its full advisory job failed after browser success: the producer wrongly required exports under an ordinary import-only branch policy. Regression `851c0456` reproduced it; `7f8c4592` lets observation generation honor the checked policy while strict warm acceptance still requires actual imports and exports. The immutable old handoff replay reproduces the old failure and corrected behavior; it is not new-source hosted acceptance. Current EC receipts below were obtained after the repair.

Older metadata lag, whole-run log ZIP transport failures, selector/handoff repairs, incomplete 900-second local attempts and their later source revisions are not rewritten as clean stability evidence. Source-bound history and failures remain visible in the prior documents and runtime directories. The known deep-quality dependency audit debt remains Phase 184; this report does not say every advisory CI job is green.

No paid judge, retry/skip masking, automatic baseline rewrite, UI redesign, new dependency, required-lane change or retained-preview mutation was used. This is representative maintainer/demo evidence at the stated source and toolchain, not outside-adopter or universal production reliability evidence. Descriptor-less/unclassified planning assumptions remain flagged as such; no human approval or design review is fabricated.
