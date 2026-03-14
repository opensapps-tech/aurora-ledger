# Aurora Ledger — Architecture

## Layer dependency rules

```
presentation → domain ← data
                ↑
           infrastructure
```

- `presentation` depends on `domain` only (use cases + entities)
- `data` implements `domain` repository interfaces
- `infrastructure` provides technical services (crypto, CRDT, sync)
- `core` has no dependencies on any other layer

## CRDT merge policy

| Situation | Policy |
|---|---|
| Concurrent ADD_EXPENSE | Both valid — unique IDs, no conflict |
| Concurrent EDIT_EXPENSE | Last-writer-wins by HLC timestamp |
| DELETE vs EDIT (any order) | Delete wins, expense removed |
| Duplicate operation ID | Idempotent — second arrival is no-op |
| SETTLE_PAYMENT | Idempotent — second settlement on same pair/amount is ignored |

## Sync protocol

```
Phase 1 — Device A sends:
  A collects operations B does not have
  → MessagePack → zstd (dict) → XChaCha20-Poly1305 → RS(32,24) frames → QR animation

Phase 2 — Device B sends:
  B collects operations A does not have
  → same pipeline → QR animation

Both devices: apply → verify signatures → HLC receive() → persist → update lastSyncedAt
```

## HLC timestamp format

Each operation carries `HlcTimestamp(physicalMs: int, logical: int)`.

Ordering: compare `physicalMs` first; break ties with `logical`.

On `receive(remote)`: advance the clock past both local and remote, increment logical if same physical ms.

## QR frame envelope

```
[1 byte]  protocol version
[2 bytes] frame index (little-endian)
[2 bytes] total frames (little-endian)
[N bytes] Reed-Solomon encoded data chunk
[4 bytes] CRC32 checksum
```
