---
title: Hardware‑Rooted Attestation for Precision Time Protocol: Verifiable Residency and Proximity proofs
abbrev: PTP-Hardware‑Rooted-Attestation
category: info

docname: draft-ramki-ptp-hardware-rooted-attestation
submissiontype: IETF  
number:
date:
consensus: true
v: 3
area: AREA
workgroup: WG Working Group
keyword:
 - next generation
 - unicorn
 - sparkling distributed ledger
venue:
  group: WG
  type: Working Group
  mail: WG@example.com
  arch: https://example.com/WG
  github: USER/REPO
  latest: https://example.com/LATEST

author:
 -
    fullname: Your Name Here
    organization: Vishanti Systems, Inc.
    email: ramkri123@gmail.com

normative:

informative:

...

--- abstract

This document defines an extension to Precision Time Protocol (PTP) that provides per‑event cryptographic attestation using non‑exportable asymmetric keys resident in TPMs or HSMs, and an optional PTP‑in‑HTTPS/MTLS encapsulation mode. When combined with freshness and multi‑observer correlation, this provides defensible proof of proximity for timing events. PTP‑in‑HTTPS/MTLS adds end‑to‑end confidentiality for timing payloads across untrusted fabrics.


--- middle

# Introduction

Precise, auditable time provenance is increasingly required by regulated systems, distributed ledgers, event forensics, and safety‑critical infrastructures. Existing symmetric PTP authentication primitives provide integrity but limited non‑repudiation and fragile key distribution (e.g., https://www.ietf.org/id/draft-kumarvarigonda-ptp-auth-extension-00.html).

This draft specifies an asymmetric, TPM/HSM‑backed attestation extension for PTP events plus an optional PTP‑in‑HTTPS/MTLS encapsulation mode. Goals are per‑event provenance, replay resistance, staged deployability in heterogeneous environments, and practical offload to SmartNICs or HSMs to meet performance needs. The optional HTTPS/MTLS encapsulation adds end‑to‑end confidentiality to the integrity and provenance provided by signing.


# Conventions and Definitions

PHC: Packet Hardware Clock exposed by NIC or SmartNIC.

TPM: Trusted Platform Module supporting non‑exportable keys and Quote operations.

HSM: Hardware Security Module on SmartNIC or separate appliance.

Verifier: Service that validates signed attestation tokens and records audit evidence.

Registrar: PKI/registry service binding signer_id to device identity, PCR profile, and revocation state.

Monotonic Counter: Non‑decreasing hardware or TPM counter used to prevent replay.

HTTPS/MTLS: HTTP over TLS 1.3 with mutual TLS (client certificates) for endpoint authentication.

SmartNIC: Programmable NIC with PHC, crypto acceleration, and optionally on‑card HSM.


# Security Considerations

TODO Security


# IANA Considerations

This document has no IANA actions.


--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
