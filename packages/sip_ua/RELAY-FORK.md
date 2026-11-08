# Relay's vendored SIP UA

This directory is a local copy of the published `sip_ua` **1.1.0** package, originating from [Dart SIP UA / CloudWebRTC](https://github.com/flutter-webrtc/dart-sip-ua). The package homepage historically uses the `cloudwebrtc/dart-sip-ua` organization path. The [upstream MIT license](LICENSE), including its 2019 CloudWebRTC copyright, is retained unchanged.

## Reproducible provenance

The readiness assessment compared the included files against the published archive:

- Archive: `https://pub.dev/api/archives/sip_ua-1.1.0.tar.gz`
- Published: 2025-12-10, per package metadata.
- SHA-256: `09b107901365d25779a9dbdb7d8396cdd76d1c48dc367155a3dc9021126fbab7`.
- Relay introduction: commit `3bfd646ce1aa432c8210e89e15c8db448e0c83a0`.
- Subsequent committed changes: `203b9ae` and `c6888b0`.

Before the open-source cleanup, only `lib/src/rtc_session.dart` and `pubspec.yaml` differed among the included upstream files. Upstream examples/tests/support files were omitted; a local package lockfile was added. This is a release-archive comparison, not a claim of an independently identified upstream source commit.

## Functional patches to preserve

1. Await `addTrack` sequentially before generating the initial SDP, for incoming and outgoing Unified Plan paths.
2. Add a dormant `recvonly` video transceiver when Relay opts into `videoReady` and supplies no local video. An audio call can then upgrade using its existing video sender.
3. Interpret incoming re-INVITE video activity using media port and effective SDP direction, including session-level fallback. A video media section or track alone does not establish active video intent.
4. Avoid automatic camera acquisition when accepting a remote video re-INVITE; local capture intent remains under application control.
5. Correct `succeeded != null` to `succeeded` in re-INVITE/UPDATE response guards. The first successful response must be processed, while duplicate responses remain guarded.
6. Preserve the associated dormant-video diagnostics.

Local manifest constraints also differ: `sdp_transform` is `^0.4.0`, `text` is `^1.0.0`, and development lints are `^6.1.0`.

## Privacy-only cleanup

The open-source cleanup does not modify `rtc_session.dart`, SDP processing, timers, media transitions or transceiver behavior. It changes the default logger to emit reviewed fixed labels and generic warning/error summaries. It removes raw transport payload/header logs and parser-input prints. Exception values and stack traces are not emitted by the default printer.

Affected fork files: `lib/src/logger.dart`, `grammar.dart`, `socket_transport.dart`, and `transports/{tcp_socket_impl,websocket_dart_impl,websocket_web_impl}.dart`. Parser failure still throws `FormatException`; network payloads still flow through their original handlers. Generated grammar code is unchanged.

`SIPUAHelper(customLogger: ...)` can replace the default printer. Any such logger is the caller's responsibility and must not emit payloads, auth headers, SDP/ICE secrets or arbitrary exception data. Relay uses the privacy-safe default.

## Maintenance and verification

Do not remove the root `dependency_overrides.sip_ua` path or replace this directory with a hosted dependency without verifying every functional patch above.

The root analyzer excludes `packages/**`; root checks alone are insufficient for fork edits. When checks are authorized, review the package separately and exercise registration, incoming/outgoing audio and direct video, repeated audio/video transitions, rejected renegotiation, Android sharing from both modes and every stop/restoration path. Inspect sanitized logs for privacy regressions. See [manual validation](../../docs/cleanup-validation.md).

No Flutter commands or tests were run during this cleanup.
