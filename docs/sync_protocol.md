# Sync Protocol

## Overview

Aurora Ledger synchronises via encrypted, compressed, error-corrected animated QR sequences.

## Pipeline (sender side)

1. Collect operations peer is missing (diff of known operation ID sets)
2. Serialise to MessagePack binary
3. Compress with Zstandard (level 3, pre-trained dictionary)
4. Derive sync key: `HKDF(group_key, "aurora-sync-v1")`
5. Encrypt with XChaCha20-Poly1305 (fresh nonce prepended)
6. Prepend 1-byte protocol version header
7. Split into chunks of ~1480 bytes
8. Apply Reed-Solomon RS(32,24) error correction per chunk
9. Wrap each chunk in frame envelope (index, total, CRC32)
10. Display as animated QR sequence at 4 fps

## Pipeline (receiver side)

1. Scan QR frames into decoder
2. Verify CRC32 per frame
3. Apply RS error correction
4. Reassemble chunks in order
5. Strip protocol version header
6. Decrypt with XChaCha20-Poly1305
7. Decompress with zstd
8. Deserialise from MessagePack
9. For each operation:
   - Verify Ed25519 signature
   - Check operation is not a duplicate
   - Call `HybridLogicalClock.receive(operation.hlcTimestamp)`
   - Persist to SQLite operations table
10. Update `groups.last_synced_at`

## Throughput estimates

| Method | Effective KB/frame | 50 ops sync | 200 ops sync |
|---|---|---|---|
| Standard QR (v40 medium) | ~1.5 KB | ~4s | ~14s |
| Standard QR + tiled 2×2 (v2) | ~6 KB | ~1s | ~4s |

Calculations assume 3 fps scan rate, bidirectional sync, zstd ~65% compression.

## Error recovery

Frame loss is handled by Reed-Solomon. If a frame is not decoded after `frameRepeatCount` displays:
- The scanner requests a rescan (UI shows which frames are missing)
- The sender loops the animation until all frames are confirmed
