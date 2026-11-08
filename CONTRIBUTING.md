# Contributing to Relay

Relay is an educational Flutter SIP/WebRTC reference application. Read the [README](README.md), [SIP fork notes](packages/sip_ua/RELAY-FORK.md) and [validation checklist](docs/cleanup-validation.md) before making changes.

## Keep changes focused

- Preserve SIP registration, call handling, dormant video-transceiver reuse, Android MediaProjection consent/foreground-service order, sharing restoration and notification Stop behavior.
- Keep dependency upgrades separate from behavior changes. Preserve the local `sip_ua` override and its documented patches.
- Never commit passwords, TURN credentials, tokens, signing material, raw signaling, local recordings, generated build reports or `tmp/` files.
- Use your own SIP/backend configuration and disposable accounts for verification. Review RTC Lab output for account/network information before attaching it to an issue.

## Validation

For code changes, run `flutter analyze` and `flutter test` when command execution is authorized, then complete the relevant physical-device scenarios in the [manual checklist](docs/cleanup-validation.md). Root analysis excludes `packages/**`, so vendored-package changes also require focused review/checks. Report commands and device scenarios actually executed; do not infer passing results from source inspection.

Licensing/documentation-only changes require consistency, link and whitespace review; no runtime behavior change is intended. No Flutter commands, builds or tests were executed during license finalization.

The generated Android report is currently tracked because the owner requested a clean index for personal staging. Before a public-release commit, the owner must remove it from tracking while preserving the local file, as documented in the validation checklist. Ignore rules protect it only after it is untracked.

## License and third-party material

Relay-owned source code and documentation use the [MIT License](LICENSE). Submit original code under those project terms only when you have the right to do so. Retain upstream license/copyright notices and identify any new third-party material and its terms.

The Relay logo/icons, conference photographs, presentation slides, recordings and third-party assets are not automatically covered by the source-code MIT license. Document their separate provenance and redistribution permission before including or publishing them. Existing unresolved obligations remain listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md); the project license does not discharge those obligations.
