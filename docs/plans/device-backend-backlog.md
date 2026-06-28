# Device & Backend Validation Backlog

The house style ships a **deterministic, headless-tested core first and defers the live edge** — the
parts that can only be *done* or *validated* with physical hardware or an external service. Those
deferred pieces are real work, but they are **not unfinished code**: the shipped cores are complete and
green. This doc tracks them in one place so a 🚧 plan status is read correctly — "core done, live edge
awaiting hardware/infra" — rather than mistaken for code debt.

Nothing here is buildable headlessly. Buildable leftovers are caught up in their own sub-plan PRs (see
each plan doc); when one lands, its line moves out of this backlog.

**Legend:** 🔴 blocked · ⏳ partially validated · the **Validate with** column is the gate.

## Hardware-pending (glasses · mic · camera · on-device model · audio routing)

| Plan | Shipped core | Live edge remaining | Validate with |
|---|---|---|---|
| [AP](audio-session-resilience-p2.md) | `AudioInterruptionPolicy` + `AudioRoutePolicy` + permanent engine + generation counters (20 tests) | Recovery actually firing on OS interruptions + route flips; phone-speaker fallback selection | A real phone call / Siri interruption + Bluetooth↔speaker route change on device |
| [AS](audio-session-lease-coordinator.md) | `AudioSessionLedger` + `AudioSessionCoordinator` seam; all exclusive owners + coexisting riders (13 tests) | Trim `AppState.switchMode`'s hardware-settling `sleep` | On-device timing: confirm no audio glitch with a shorter/zero settle delay across mode switches |
| [AJ](additional-capabilities.md) — shared `DeviceSession` | `DeviceSessionOwnership` / `DeviceSessionCoordinator` ref-counting (tested) | Adopt one shared camera+display `DeviceSession` (camera + HUD at once) | On-glasses: camera stream + HUD render sharing a session without contention |
| [AJ](additional-capabilities.md) — alt triggers | Gate + service + shake detector + Settings (16 tests) | Acoustic (SoundAnalysis) threshold tuning; AirPod stem AppIntent (entitlement) | On-device mic tuning; AirPods + entitlement |
| [AJ](additional-capabilities.md) — on-device ASR/TTS | SenseVoice + Kokoro selection chains, model stores, real inference behind flags (Debug+Release green) | SenseVoice streaming/VAD endpointing + accuracy; Kokoro audio-output quality | On-device audio in/out (no simulator audio path) |
| [AD](structured-vision-assessment.md) | Structured-vision substrate + `vision_assess` + consumers (46 tests) | Assessment **accuracy** on real camera frames (the schema/parse path is buildable and tracked in the plan) | On-glasses camera against real instruments/scenes |
| [AQ](speaker-diarization.md) | Parser/merger/registry + `DiarizationProvider` seam (24 tests) | Speaker-naming-from-chip accuracy on real multi-speaker audio | On-device mic with multiple speakers |

## Backend / service-pending (gateway · relay · external API)

| Plan | Shipped core | Live edge remaining | Unblocked by |
|---|---|---|---|
| [N](N-remote-agent-harness.md) | `AgentHarness`/`OpenClawAgentHarness`/`CustomAgentHarness` + registry + tools (48 tests) | Gateway `agent.*` (start/status/cancel) + live event stream; Codex-cloud / Claude-remote adapters | OpenClaw gateway implementing `agent.*` + live events; a reachable Codex/Claude programmatic endpoint |
| [AR](gateway-device-pairing.md) | `SetupCode`/`GatewayAuthSelector`/`PairingResponseInterpreter` + pairing UI (23 tests) | Live approval round-trip (bootstrap → approve → per-device token) | Gateway implementing the v3 pairing handshake (degrades to shared-token today) |
| [T](T-offline-field-queue-and-sync.md) | `OfflineQueue` + `Reachability` + `SyncEngine` over a pluggable sink + `ConflictResolver` (13 tests) | A real **networked** sync sink (today's sink is local/export-only) | An external endpoint that accepts queued op uploads |
| [AQ](speaker-diarization.md) | Batch path + parser (24 tests) | Live diarized caption **WebSocket** stream | Deepgram live streaming (cloud) |
| [V](V-mcp-catalogue-and-transport-breadth.md) | `MCPCatalog` + transport parsing + `SSEEventParser` (37 tests) | SSE `initialize` handshake against a real server; OAuth device-code/PKCE token exchange + refresh | A reachable MCP server with SSE; a real IdP for the OAuth exchange |
| [M](M-webrtc-infra-and-audio.md) | App-side WebRTC + audio coordinator; M1/M2 reference impls (`docs/webrtc/`) | Deploy signaling relay + TURN; host the expert web client; on-device echo/precedence | Self-hosted signaling + TURN infrastructure |

## How to use this

- A 🚧 plan with **all** its remaining work in this table is **complete to the extent verifiable** — treat
  it as done for code purposes; the entry is the validation/integration checklist.
- When hardware or a backend becomes available, work the relevant rows and update the originating plan
  doc's status. Most rows are an afternoon of wiring + validation once the dependency exists.
- Buildable leftovers are **not** here — they live as sub-plans in their plan docs and get their own PRs.
