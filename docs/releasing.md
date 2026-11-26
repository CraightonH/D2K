# Release setup

D2K uses the template's reusable workflows at `workflows-v1.0.1` and its pinned BigWigs packager. Both `addon.json` and `D2K.toc` identify CurseForge project **1831997** (WoW Forever version type **88568**).

The repository is configured with `RELEASE_ENABLED=true`, `CURSEFORGE_ENABLED=true`, and a `curseforge` environment. Add the author upload token as **`CF_API_TOKEN`** in repository secrets or that environment's secrets. Do not commit tokens.

Branch pushes and pull requests run checks and create validated candidate ZIP artifacts. They do not publish a release. Upstream monitoring is opt-in through `WATCH_UPSTREAM=true`.

After reviewing a commit and verifying its packaged build in game, publish an annotated version tag:

```sh
git tag -a v0.2.1 -m 'D2K 0.2.1'
git push origin v0.2.1
```

Use an unused version tag. Tagging runs checks, assigns the TOC version, validates the ZIP, creates a GitHub release, and uploads the same archive to CurseForge. The MIT license is included in the addon package. Alpha/beta versions use `vX.Y.Z-alpha.N` or `vX.Y.Z-beta.N`.

The manual CurseForge workflow can retry deployment of an existing GitHub release without rebuilding. Inspect ambiguous uploads before retrying; see [shared workflow details](reusable-workflows.md).

Repository creation does not create an addon release or upload to CurseForge. No release tag is created as part of this initial integration.
