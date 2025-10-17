---
title: "Hardware‑Rooted Attestation for Precision Time Protocol: Verifiable Residency and Proximity proofs"
abbrev: "PTP-Hardware‑Rooted-Attestation"
category: info
docname: draft-ramki-ptp-hardware-rooted-attestation-00
submissiontype: IETF
number: 00
consensus: true
v: 3
area: AREA
workgroup: "WG Working Group"
keywords:
  - PTP
  - Attestation
  - Time Synchronization
  - Time Provenance
  - Time Integrity
  - Time Security
  - Time Forensics
  - Time Auditing
  - Time Stamping
  - Time Distribution
  - TPM
  - HSM

venue:
  group: WG
  type: Working Group
  mail: WG@example.com
  arch: "https://example.com/WG"
  github: "USER/REPO"
  latest: "https://example.com/LATEST"

author:
  - fullname: "Ramki Krishnan"
    organization: "Vishanti Systems, Inc."
    email: "ramkri123@gmail.com"
  - fullname: "Michael Richardson"
    organization: "Sandelman Software Works Inc"
    email: "mcr+IETF@sandelman.ca"
  - ins: D. Lopez
    name: Diego R. Lopez
    org: Telefonica
    email: diego.r.lopez@telefonica.com
  - ins: A. Prasad
    name: A Prasad
    org: Oracle
    email: a.prasad@oracle.com
  - ins: S. Addepalli
    name: Srinivasa Addepalli
    org: Aryaka
    email: srinivasa.addepalli@aryaka.com


...

--- abstract

This document defines an extension to Precision Time Protocol (PTP) that provides per‑event cryptographic attestation using non‑exportable asymmetric keys resident in TPMs or HSMs, and an optional PTP‑in‑HTTPS/MTLS encapsulation mode. When combined with freshness and multi‑observer correlation, this provides defensible proof of proximity for timing events. PTP‑in‑HTTPS/MTLS adds end‑to‑end confidentiality for timing payloads across untrusted fabrics.


--- middle

<!-- Lint marker: draft-ramki-ptp-hardware-rooted-attestation-latest-latest -->

<!-- Document canonical name: draft-ramki-ptp-hardware-rooted-attestation-latest -->

# Introduction

Precise, auditable time provenance is increasingly required by regulated systems, distributed ledgers, event forensics, and safety‑critical infrastructures. Existing symmetric PTP authentication primitives provide integrity but limited non‑repudiation and fragile key distribution (e.g., https://www.ietf.org/id/draft-kumarvarigonda-ptp-auth-extension-00.html).

This draft specifies an asymmetric, TPM/HSM‑backed attestation extension for PTP events plus an optional PTP‑in‑HTTPS/MTLS encapsulation mode. Goals are per‑event provenance, replay resistance, staged deployability in heterogeneous environments, and practical offload to SmartNICs or HSMs to meet performance needs. The optional HTTPS/MTLS encapsulation adds end‑to‑end confidentiality to the integrity and provenance provided by signing.

# Conventions and Definitions

PHC: Packet Hardware Clock exposed by NIC or SmartNIC.

TPM: Trusted Platform Module supporting non‑exportable keys and Quote operations.

HSM: Hardware Security Module on SmartNIC or separate appliance.

Verifier: Service that validates signed tokens and records audit evidence.

Registrar: PKI/registry service binding signer_id to device identity, PCR profile, and revocation state.

Monotonic Counter: Non‑decreasing hardware or TPM counter used to prevent replay.

HTTPS/MTLS: HTTP over TLS 1.3 with mutual TLS (client certificates) for endpoint authentication.

SmartNIC: Programmable NIC with PHC, crypto acceleration, and optionally on‑card HSM.

# Architecture Overview
## In‑band signed PTP extension
PTP messages carry an attached signed token for each signed event. This mode preserves end‑to‑end integrity and provenance of PTP payloads (signature binds payload, PHC timestamp, nonce, seq, counter) while leaving confidentiality and in‑fabric correction semantics to the underlying network fabric.

**Hardware‑rooted signing**: PTP endpoints (masters, slaves, boundary clocks) are provisioned with non‑exportable asymmetric keys in TPMs or HSMs. Each PTP event is signed using a Quote operation that includes a nonce and monotonic counter to prevent replay. The signer_id (e.g., key hash or certificate serial) is included in the signed token to allow verifiers to fetch the corresponding public key and PCR profile from a registrar service.

**Note**: In‑band attestation preserves integrity and provenance but does not provide confidentiality; PTP payloads remain visible to in‑path observers.

## PTP‑in‑HTTPS/MTLS encapsulation
Native PTP bytes are framed inside persistent HTTPS/MTLS streams between endpoints. Signed tokens are carried inside the same MTLS connection or out‑of‑band to a verifier. This prevents in‑path modification and adds confidentiality for timing payloads and signed metadata.

## Signing Mechanism
Endpoints MUST compute event_digest over the entire PTP message as transmitted, except for fields explicitly designated as mutable by IEEE 1588 (e.g., correction field). When PTP messages are encapsulated in HTTPS/MTLS, endpoints SHOULD sign the entire PTP message without exclusions, as no in‑path modification is permitted.

## Verifier Roles
Two deployment patterns are supported for the verifier function:

Dedicated Verifier Service
* A logically separate service issues nonces, validates signed tokens, checks counters, and records audit evidence.
* Advantages: clear separation of duties, centralized audit logs, simplified revocation handling, and independence for regulatory or forensic review.
* Normative requirements:
  * The dedicated verifier MUST maintain an append‑only, tamper‑evident audit log of all tokens and validation results.
  * The verifier MUST enforce nonce freshness, monotonic counter progression, and token TTL.
  * The verifier MUST reject tokens from revoked or unregistered Signer_IDs.

Peer‑as‑Verifier
* A PTP peer (master, slave, or boundary clock) may act as verifier by issuing nonces to its counterpart and validating returned signed tokens inline with the timing exchange.
* Advantages: immediate freshness check, no extra infrastructure, lower latency.
* Risks: blurs separation of duties, reduces independence of audit evidence, and increases reliance on peer trustworthiness.
* Normative requirements:
  * A peer acting as verifier MUST log all signed tokens and validation results to an append‑only audit store or forward them to a registrar.
  * A peer acting as verifier MUST apply the same validation rules as a dedicated verifier (nonce freshness, monotonic counter, TTL, revocation).
  * Operators SHOULD prefer independent verifiers when regulatory or forensic requirements demand separation of duties.

# Signed Token Structure
The signed token is a CBOR map with the following fields. CBOR encoding (RFC 8949) is be used to ensure consistent signatures.

```text
; Signed Token (CBOR map))
{
  1 : uint,        ; version (e.g., 1)
  2 : uint,        ; event_type (PTP message type)
  3 : uint,        ; ptp_seq (SequenceID)
  4 : uint,        ; phc_timestamp_ns (nanoseconds)
  5 : bstr,        ; event_digest (SHA-256 of signed PTP fields)
  6 : bstr,        ; nonce (verifier-issued, 16 bytes recommended)
  7 : uint,        ; monotonic_counter (TPM/HSM-backed)
  8 : bstr,        ; signer_id (hash of TPM/HSM public key or cert fingerprint)
  9 : bstr / null, ; pcr_summary (optional TPM Quote or compressed PCR set)
  10: bstr         ; signature (TPM/HSM non-exportable key)
}
```
# PTP Message Signing Coverage
The following table indicates which PTP fields MUST be included in the event_digest computation. Fields marked as mutable by IEEE 1588 (e.g., CorrectionField) are excluded in in‑band mode. In PTP‑in‑HTTPS/MTLS mode, the entire PTP message MUST be signed since no in‑path modification is permitted.

| PTP Field (IEEE 1588 header) | Signed? | Rationale |
|---|:--:|---|
| TransportSpecific + MessageType | Yes | Immutable, identifies event type |
| VersionPTP | Yes | Immutable |
| MessageLength | Yes | Integrity of framing |
| DomainNumber | Yes | Integrity of domain separation |
| FlagField | Yes | Integrity of mode bits |
| CorrectionField | No | Mutable by transparent clocks; excluded in in‑band mode |
| SourcePortIdentity | Yes | Binds to originating clock |
| SequenceID | Yes | Prevents replay/reordering |
| ControlField | Yes | Immutable |
| LogMessageInterval | Yes | Immutable |
| PTP Payload (Sync, FollowUp, DelayReq, DelayResp, etc.) | Yes | Except correction sub‑fields if mutable |
| TLVs (other than Attestation) | Yes | Integrity of extensions |

**Normative rule:**
* In in‑band TLV mode, event_digest MUST be computed over the entire PTP message excluding CorrectionField (and any other fields normatively designated as mutable by IEEE 1588).
* In PTP‑in‑HTTPS/MTLS mode, the entire PTP message MUST be included in the digest, since no in‑path modification is permitted.

# Security Considerations
## Replay and relay attacks

Endpoints MUST include a verifier‑issued nonce and a monotonic counter in each token.

Verifiers MUST:

- Reject tokens with stale or missing nonces.
- Reject tokens with regressions in monotonic counters.
- Reject tokens where counters jump beyond an operator‑defined threshold.

Verifiers SHOULD log round‑trip times (RTT) for challenge/response exchanges and MAY apply policy thresholds to detect relays or anomalous delays.

## Confidentiality

In‑band attestation TLVs provide integrity and provenance but do not provide confidentiality; PTP payloads remain visible to in‑path observers.

Operators requiring confidentiality MUST use PTP‑in‑HTTPS/MTLS encapsulation, which prevents in‑path modification and protects both timing payloads and attestation metadata.

## PCR privacy

PCR values and TPM quotes may reveal sensitive configuration or software state.

Registrars MUST enforce minimal disclosure policies, requiring only the PCRs necessary for attestation policy.

Verifiers MUST validate PCR summaries against registrar policy but MUST NOT require disclosure of unrelated PCRs.

## Revocation

Verifiers MUST reject tokens from revoked or unregistered Signer_IDs.

Registrars MUST support rapid revocation and distribution of revocation state to verifiers.

Operators MUST ensure revocation information is available to verifiers in near‑real time.

## Compromise handling

In the event of TPM/HSM compromise, operators MUST support re‑enrollment and key rollover.

Registrars MUST provide mechanisms to bind new keys to existing device identities and to revoke compromised keys without disrupting unaffected devices.

Audit logs MUST record revocation and re‑enrollment events for forensic traceability.

## Location claims

Verifiers MUST NOT assert geographic residency or location from a single signed timestamp.

Proximity proofs require correlation across multiple observers and RTT measurements.

# IANA Considerations
A new PTP TLV type for the signed token.

A registry for token versions and signature algorithm identifiers.

# References
Normative: IEEE 1588 (PTP), RFC 8949 (CBOR), RFC 8446 (TLS 1.3), TPM 2.0 spec, draft‑kumarvarigonda‑ptp‑auth‑extension.

Informative: draft‑ietf‑ntp‑over‑ptp, RATS architecture (RFC 9334), COSE (RFC 8152).

--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
