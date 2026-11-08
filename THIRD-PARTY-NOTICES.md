# Third-party code and asset review

Relay-owned source code and documentation are licensed under the [MIT License](LICENSE). This does not replace dependency licenses or establish rights to branding, photographs, presentation slides, recordings or third-party assets. Those assets require their own ownership and redistribution review.

## Notices retained

- `packages/sip_ua/LICENSE`: original MIT / CloudWebRTC notice, unchanged.
- `packages/sip_ua/lib/src/grammar_parser.dart`: upstream generated-code header, unchanged. The generated parser and grammar are part of the published SIP package; do not remove them merely because they are generated.
- [Collected notices](THIRD-PARTY-NOTICES.txt): full license/NOTICE texts read from the existing resolved direct dependency files, the Flutter SDK, and the identified MPL transitive packages. This is a source-notice collection, not proof of a complete binary license inventory.

The inspected direct dependencies group as follows:

| License | Dependencies |
| --- | --- |
| MIT | `flutter_riverpod`, `sentry_flutter`, `flutter_svg`, `permission_handler`, `flutter_webrtc`, `sip_ua`, `flutter_dotenv`, `cue` |
| BSD-3-Clause | Flutter SDK, `go_router`, `flutter_secure_storage`, `shared_preferences`, `package_info_plus`, `device_info_plus`, `connectivity_plus`, `wakelock_plus`, `intl`, `flex_color_scheme`, `material_ui`, `url_launcher` |

`flutter_webrtc` also has a NOTICE carrying Apache-2.0/MIT material. Preserve it in addition to its main MIT license. Its Android manifest of native dependencies includes WebRTC SDK Android `150.7871.04` and an AudioSwitch revision; those native artifacts and iOS equivalents need a complete distribution-specific notice/source review before releasing binaries.

Transitive `dbus` and `nm` use MPL-2.0. Assess whether they are included in the platforms/artifacts actually distributed. If covered executable code is distributed, preserve notices and provide covered source as required; a top-level MIT declaration does not replace those obligations. See the [Mozilla license](https://www.mozilla.org/en-US/MPL/2.0/).

The collected notices do not cover every development/transitive/native artifact. Before distributing an APK/IPA, inspect its complete resolved dependencies, native WebRTC/Sentry components, fonts and bundled assets, and supply all required license/source notices. No APK/IPA was built or inspected in this cleanup.

## Asset provenance and unresolved rights

| Asset group | Evidence | Publication status |
| --- | --- | --- |
| `assets/images/logo.png` | Existing tracked source asset; no ownership/license record found | Owner must confirm redistribution rights |
| `assets/launcher/*.png` | Existing tracked branding inputs; no separate ownership record found | Owner must confirm redistribution rights |
| Android/iOS generated icons and splash images | Derived platform resources already tracked | Keep provenance tied to their source assets; ownership unresolved |
| Root `flutter_*.png` captures | Local/untracked preview-era application screenshots | Preserved and ignored; obtain current captures and review identities/content |
| `output/` slides, PDFs, QR images, ZIPs and recordings | Local/untracked conference output | Preserved and ignored; inspect embedded media, permissions, external links and notes before any separate publication |
| `tmp/` decks, source models, scripts, photos and video | Presentation working material, including final/draft decks | Preserved except confirmed render/log caches; ignored, not part of Relay source |
| `relay-designs/` | Ignored local design references | Not covered by Relay's source-code MIT license; separate permission required |

Git authorship or receipt of a file is not evidence of copyright ownership. No asset was relabeled as MIT, no photos/recordings/final decks were deleted, and no generated replacement screenshots were introduced.

## Release gates

1. Obtain logo/icon source and redistribution evidence or decide an authorized replacement in a separate task.
2. Review conference assets independently before publishing them.
3. Complete the transitive/native notice inventory for each binary distribution.

These asset and third-party obligations remain separate from the approved MIT license for Relay-owned source code and documentation.
