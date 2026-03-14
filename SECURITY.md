# Security

Aurora Ledger takes security seriously. All data is end-to-end encrypted and never leaves user devices.

## Scope

- Cryptographic identity and key management
- CRDT operation signing and verification
- Sync payload encryption / decryption
- Secure key storage (Keychain / Android Keystore)
- QR frame integrity (Reed-Solomon + CRC32)

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Email: security@your-domain.com (TODO: update)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (optional)

We will acknowledge within 48 hours and aim to ship a fix within 14 days for critical issues.

## Out of scope

- Vulnerabilities requiring physical device access (we assume the device OS is trusted)
- Social engineering attacks
