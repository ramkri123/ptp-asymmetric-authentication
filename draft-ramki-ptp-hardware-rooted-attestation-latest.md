%%%
title = "Hardware‑Rooted Attestation for Precision Time Protocol: Scalable Workload Identity and Phased PQC Readiness"
abbrev = "PTP-Hardware‑Rooted-Attestation"
category = "info"
docName = "draft-ramki-ptp-hardware-rooted-attestation-01"
ipr = "trust200902"
area = "Security"
workgroup = "PTP Working Group"
keyword = ["PTP", "Attestation", "Time Provenance", "PQC", "SPIFFE", "Merkle Tree", "Non-Repudiation"]

[seriesInfo]
name = "Internet-Draft"
value = "draft-ramki-ptp-hardware-rooted-attestation-01"
stream = "IETF"
status = "informational"

[[author]]
initials = "R."
surname = "Krishnan"
fullname = "Ramki Krishnan"
organization = "JPMorgan Chase"
  [author.address]
  email = "ramkri123@gmail.com"

[[author]]
initials = "M."
surname = "Richardson"
fullname = "Michael Richardson"
organization = "Sandelman Software Works Inc"
  [author.address]
  email = "mcr+IETF@sandelman.ca"

[[author]]
initials = "D."
surname = "Lopez"
fullname = "Diego R. Lopez"
organization = "Telefonica"
  [author.address]
  email = "diego.r.lopez@telefonica.com"

[[author]]
initials = "A."
surname = "Prasad"
fullname = "A Prasad"
organization = "Oracle"
  [author.address]
  email = "a.prasad@oracle.com"

[[author]]
initials = "S."
surname = "Addepalli"
fullname = "Srinivasa Addepalli"
organization = "Aryaka"
  [author.address]
  email = "srinivasa.addepalli@aryaka.com"

%%%

.# Abstract

This document defines a scalable framework for hardware‑rooted cryptographic attestation in the Precision Time Protocol (PTP). Standard PTP security mechanisms rely on symmetric keys, which suffer from identity ambiguity and source repudiation—vulnerabilities that allow any node possessing the shared secret to impersonate a Grandmaster. To resolve these issues while overcoming the silicon throughput limits of traditional TPMs and the overhead of Post-Quantum Cryptography (PQC), this draft specifies a tiered trust model. A Hardware Root (e.g., TPM) establishes a long-term PQC identity, while a workload identity management plane (e.g., SPIFFE/SPIRE) manages the frequent rotation of short-lived operational keys. These keys perform amortized signing of PTP message batches via Merkle Trees, ensuring wire-speed synchronization and irrefutable provenance for regulated environments.

{mainmatter}

# Introduction

Precise, auditable time provenance is a cornerstone for regulated environments, including financial services, distributed ledgers, and sovereign AI. However, standard PTP security (IEEE 1588-2019) faces three critical architectural challenges:

1. **The Identity and Repudiation Problem:** Current PTP security relies largely on symmetric keys (HMAC-SHA256). Because the Grandmaster (GM) and all Slaves share the same secret, any compromised node can forge time messages appearing to originate from the GM. This lack of source non-repudiation makes it impossible to irrefutably audit time provenance or defend against "insider" clock spoofing.
2. **The Throughput Gap:** Hardware Security Modules (TPMs/HSMs) are "slow-path" silicon, often incapable of performing the 128+ asymmetric signatures per second required by high-performance PTP profiles.
3. **The PQC Payload Problem:** Post-Quantum Cryptographic (PQC) signatures (e.g., ML-DSA) are significantly larger than standard PTP message MTUs, introducing fragmentation risks and unacceptable processing jitter if applied per-packet.

This draft introduces a **Transitive and Amortized Attestation** model. By anchoring an automated software control plane in hardware silicon, we resolve the identity ambiguity of symmetric keys while maintaining wire-speed performance.

# Architecture: The Tiered Trust Model

Trust is distributed across three functional layers to bridge the gap between "Slow-but-Secure" hardware and "Fast-and-Precise" network timing.

## Tier 1: Hardware Root (Immutable Identity)
The Root of Trust (RoT) is a hardware component (e.g., TPM 2.0, HPE iLO 7, or SmartNIC SRoT) containing a non-exportable Identity Key. This key MUST be asymmetric and SHOULD be PQC-compatible (e.g., ML-DSA). This establishes an irrefutable "Silicon Identity" that cannot be cloned, addressing the fundamental weakness of symmetric shared secrets.

## Tier 2: Control Plane (Workload Orchestration)
To manage the lifecycle of cryptographic material without manual intervention, the PTP daemon is treated as a managed workload under workload identity management frameworks such as **SPIFFE/SPIRE**. 
* **Attestation:** Host identity management plane (HPE Oneview, Keylime verifier/registrar) verifies the RoT's identity and platform state (PCRs). The interaction between host identity management plane and workload identity management plane to attest the workload identity management agent (e.g. spire agent) is described in https://github.com/ramkri123/ietf-tpm-geofencing/blob/master/draft-lkspa-wimse-verifiable-geo-fence.md.
* **Delegation:** Upon successful attestation, Workolad identity management plane (e.g. SPFFE/SPIRE) issues short-lived SVIDs and ephemeral **Operational Keys** which use standard non-PQC cryptography. This "Transitive Attestation" binds the high-speed software/NIC key to the immutable hardware identity.

## Tier 3: Data Plane (Amortized Execution)
High-frequency signing is offloaded to the Data Plane using the **Operational Keys** in software or a hardware offload such as SmartNIC. 
* **Merkle Batching:** Messages are hashed into a Merkle Tree. A single signature on the Merkle Root provides cryptographic integrity and non-repudiable proof for the entire batch of PTP events. This amortization makes large PQC signatures feasible within the PTP ecosystem. A batch message is sent from source to destination on batch or timer expiry.

# Scalable Attestation Mechanism

## Solving Source Repudiation
By utilizing asymmetric operational keys certified by the Hardware Root, a Verifier can irrefutably prove that a batch of PTP messages originated from a specific physical device. In this model, a compromised Slave has no access to the private key required to forge a Grandmaster's signature, fixing the identity ambiguity inherent in current symmetric PTP profiles.

## Amortized PQC Readiness
PQC adoption is phased to ensure that data-plane performance is never compromised:
1. **Identity Layer:** RECOMMENDED to use PQC-capable hardware roots (Identity Key) today to secure the long-term device identity.
2. **Control Layer:** RECOMMENDED to use PQC-signed workload identities (e.g. SPIFFE/SPIRE SVIDs) to protect the distribution and rotation of keys.
3. **Data Layer:** MAY use classical asymmetric algorithms (e.g., Ed25519) for the Merkle Root today, transitioning to PQC as specialized hardware acceleration becomes pervasive.

# Signed Token Structure (CBOR)

The amortized token provides the "Batch Proof" for $N$ sequence IDs.

```text
; Amortized Signed Token (CBOR map)
{
  1 : uint,         ; version (e.g., 2)
  2 : uint,         ; batch_size
  3 : bstr,         ; Merkle Root Hash
  4 : uint,         ; First SequenceID in batch
  5 : bstr,         ; SVID / Operational Cert Reference
  6 : bstr,         ; nonce (verifier-issued)
  7 : bstr          ; signature (PQC recommended)
}
```

# Security Considerations

## Integrity vs. Network Jitter

PQC signatures are computationally heavy. Performing these on every packet would introduce variable jitter into the PTP timing loop. The amortized Merkle approach ensures that the timing-sensitive hardware timestamping remains asynchronous from the heavy cryptographic signing process.

## Symmetric Key Obsolescence

Symmetric-key PTP security is insufficient for regulated time provenance due to the lack of source non-repudiation. This draft provides the blueprint for transitioning to asymmetric hardware-rooted keys as the only viable path to meaningful identity in multi-tenant or untrusted fabrics.

## Network Path Asymmetry

Attestation provides proof of Identity, Integrity, and Residency. It does not protect against physical network delay or path asymmetry. This mechanism MUST be used in conjunction with PTP's native delay measurement mechanisms.

# IANA Considerations
Registry for PTP_AMORTIZED_ATTESTATION_TLV.

# References
Normative: IEEE 1588-2019, RFC 8949 (CBOR), FIPS 204 (ML-DSA), SPIFFE Specification.

Informative: RFC 9334 (RATS Architecture), HPE iLO 7 Security Whitepaper.

{backmatter}
