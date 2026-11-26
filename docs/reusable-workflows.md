# Shared addon workflows

D2K consumes reusable workflows from [CraightonH/wow-addon-template](https://github.com/CraightonH/wow-addon-template). D2K includes the template’s reusable build/release/deployment entry points locally for nested release calls. The shared Python tooling is still checked out from the pinned template version; there is no separate uploader implementation.

Remote workflow references and `tooling-ref: workflows-v1.0.1` select the same immutable tooling release. The tagged release caller uses `./.github/workflows/reusable-release.yml`. To upgrade, update remote references, tooling-ref values, and the three local reusable workflow copies together, then verify candidate and tagged builds. Do not move published release tags.

## Configuration

`addon.json` identifies D2K, interface 16001, CurseForge project 1831997, and Forever version type 88568. The TOC repeats the interface and CurseForge project ID. Source is at the repository root and candidate artifacts go under `.release/`.

Checks default to `python3 scripts/check.py`. BigWigs Packager v2.7.0 assigns the TOC version from Git metadata and builds without uploading. Shared tooling validates the ZIP and records its source commit, version, interface, and destination in `release.json`.

The upstream commit inherited from the template is a research baseline. It is not a certification of D2K against that client build. Update it after reviewing and testing a specific client revision.

## Workflow callers

- `checks.yml`: branch pushes and pull requests run tests and upload a validated candidate ZIP plus manifest.
- `release.yml`: annotated addon version tags run checks, build once, create a GitHub release, and optionally deploy the checked archive to CurseForge.
- `curseforge.yml`: a manually requested retry uploads an existing validated GitHub release without rebuilding.
- `upstream.yml`: opt-in observation of the Forever UI-source mirror creates a compatibility issue and candidate run; it never changes the TOC or publishes an addon.

`RELEASE_ENABLED` and `CURSEFORGE_ENABLED` gate publishing. `WATCH_UPSTREAM` is optional. See [release setup](releasing.md) for secrets and tags.

A matching CurseForge upload receipt suppresses duplicates. When an upload response is ambiguous, inspect CurseForge before retrying; its API has no idempotency key. Successful API acceptance may still be followed by site moderation.
