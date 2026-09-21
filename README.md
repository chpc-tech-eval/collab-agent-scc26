# Human–Agent Collaboration — Discord & Telegram Operations Gateway

**Repository:** `collab-agent-scc26`  
**Recommended long name:** **Human–Agent Collaboration: Discord & Telegram Operations Gateway**  
**Duration:** 10-week core, 12 weeks with stretch/handover

## Project summary

This project studies how researchers, students and operators can collaborate with platform agents through tools they already use—Discord and Telegram—without turning a chat bot into a privileged back door.

Students build two external **liaison adapters** that translate chat interactions into authenticated, policy-bounded tasks for `agent-control-plane`. Hermes provides the conversational/runtime layer, while the control plane owns task authorisation, evidence, run history and future delegation. `quantum-platform` remains the authoritative identity/application surface.

The central engineering idea is simple:

> Chat systems are user interfaces. They are not the security boundary and they are not the system of record.

## Core question

> Can Discord and Telegram provide a useful conversational operations/research interface while preserving identity, authorisation, auditability, least privilege and reproducibility?

## Primary integrations

- `agent-control-plane` — task API, policy boundary, run/evidence history;
- Hermes — conversational/runtime adapter;
- `quantum-platform` — user identity, administrator/researcher views and account linking;
- `infra-hpc-qc-k8s` — deployment, secrets, network policy and observability;
- `quantum-workflows` — read-only workflow status and future approved submission contracts.

## Learning outcomes

Students should be able to:

- build production-style webhook/bot adapters;
- normalise different messaging APIs into a common message envelope;
- separate authentication from authorisation;
- design account-linking flows without trusting chat display names;
- persist task/run/audit history outside the chat platform;
- implement rate limiting, replay protection and idempotency;
- design safe conversational commands that map to fixed backend capabilities;
- surface progress and errors asynchronously through message threads/replies;
- compare Discord and Telegram operational ergonomics;
- document privacy and retention implications.

## Scope

### Must deliver

1. A common channel-adapter interface.
2. A Discord adapter.
3. A Telegram adapter.
4. A normalised inbound message/event schema.
5. An account-linking design that maps external channel identities to platform identities without relying on usernames alone.
6. At least four safe capabilities, all read-only in the core project. Suggested examples:
   - platform health summary;
   - Prometheus diagnostic summary;
   - Kubernetes application status;
   - recent agent task/run history;
   - selected workflow status.
7. Persistent audit/task history in `agent-control-plane`.
8. Rate limits, duplicate-event handling and basic abuse protection.
9. Structured metrics/logging for adapter health and task latency.
10. A demonstration that the same logical request works through both Discord and Telegram.

### Should deliver

- threaded/reply-aware conversations;
- per-channel formatting adapters;
- “show evidence” command that links an answer back to bounded source evidence;
- administrator visibility in `quantum-platform`;
- graceful fallback if Hermes/inference is unavailable;
- a privacy/retention matrix comparing what is stored by the platform versus the external chat provider.

### Stretch

- explicit human approval flow for one non-destructive mutation;
- workflow submission request that creates a pending task rather than directly launching compute;
- role-aware channel policies;
- handoff between small/fast and large/reasoning models through control-plane routing experiments.

## Non-goals

- storing platform truth only in Discord/Telegram history;
- granting bot tokens Kubernetes/Slurm/OpenStack administrator credentials;
- executing arbitrary shell commands from chat;
- inferring platform roles from Discord server roles or Telegram usernames without an explicit mapping policy;
- allowing a language model to bypass application authorisation.

## Architecture

```text
 Discord user                       Telegram user
      │                                  │
      ▼                                  ▼
Discord liaison                     Telegram liaison
      │                                  │
      └────────── normalized event ──────┘
                         │
                 identity link check
                         │
                         ▼
                agent-control-plane
               policy + task + audit
                         │
              ┌──────────┴──────────┐
              │                     │
        bounded diagnostics      Hermes runtime
              │                     │
              └──────── evidence ───┘
                         │
                         ▼
                 formatted response
                         │
            Discord / Telegram reply

 quantum-platform remains authoritative for platform identity and admin views.
```

## Common message envelope

Students should define and version a transport-neutral envelope such as:

```json
{
  "provider": "discord|telegram",
  "external_user_id": "opaque-provider-id",
  "external_conversation_id": "opaque-provider-id",
  "external_message_id": "opaque-provider-id",
  "received_at": "RFC3339 timestamp",
  "text": "request text",
  "reply_to": "optional external message id"
}
```

The envelope should not pretend that an external user ID is itself sufficient authorisation. It is an input to a platform-controlled identity mapping.

## Repository layout

```text
collab-agent-scc26/
├── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── IDENTITY-LINKING.md
│   ├── PRIVACY-RETENTION.md
│   └── OPERATIONS.md
├── src/
│   ├── common/
│   ├── discord/
│   └── telegram/
├── fixtures/
├── deploy/
├── tests/
└── .github/workflows/
```

## Ten-week roadmap

### Week 1 — Threat model and channel abstraction

- compare Discord and Telegram API/event models;
- define common envelope and adapter interface;
- document trust boundaries and secrets handling;
- build local fake-event fixtures.

### Week 2 — One-channel vertical slice

Implement one provider end to end:

```text
message -> adapter -> fixed diagnostic -> response
```

Use a local/mock control-plane endpoint if required.

### Week 3 — `agent-control-plane` integration

- authenticated service-to-service call;
- persistent task/run record;
- idempotency key based on provider/message identifiers;
- clear error states.

### Week 4 — Second provider

Implement the same contract for the second channel. Avoid copy/paste provider-specific business logic.

### Week 5 — Identity linking

- design account-link flow through `quantum-platform` or a project fixture;
- test revoked/unlinked identities;
- test duplicate names and changed display names;
- document administrator recovery.

### Week 6 — Hermes conversational layer

Hermes receives only the authorised task/evidence context required for the response. Add explanation, conversational continuity and safe formatting.

### Week 7 — Cross-project integration

Consume one real platform diagnostic and one real workflow/task status. Freeze adapter/control-plane interface.

### Week 8 — Reliability and abuse handling

- duplicate webhooks;
- retries/timeouts;
- inference unavailable;
- provider unavailable;
- rate limiting;
- malformed content;
- observability dashboards.

### Week 9 — Staging release

Deploy from `stag`, perform an end-to-end test matrix across both providers and verify audit history.

### Week 10 — Final demo

Demonstrate identical logical requests from Discord and Telegram, show account linkage and authorisation, display task/evidence history, deliberately trigger a denial/failure, and explain where every trust decision occurs.

### Weeks 11–12 — Stretch

Human approval for one bounded mutation, richer workflow integration and upstream PR refinement.

## Test matrix

At minimum test:

- linked user / permitted command;
- unlinked user;
- linked user / forbidden capability;
- duplicated provider event;
- delayed retry;
- malformed payload;
- Hermes unavailable;
- control-plane unavailable;
- evidence source unavailable;
- request that exceeds rate limit.

## Metrics

- end-to-end response latency;
- control-plane queue/run latency;
- adapter error rate;
- duplicate suppression count;
- unauthorised request count;
- model/inference latency separately from transport latency;
- percentage of responses with traceable task/evidence IDs.

## Acceptance criteria

A student must be able to send the same authorised diagnostic request through both Discord and Telegram, receive equivalent evidence-grounded answers, locate the corresponding task/run in the control-plane history, and demonstrate that an unlinked or unauthorised user cannot obtain the protected result.

## Upstream contribution targets

- `agent-control-plane`: stable channel-adapter/task contracts and audit improvements;
- `quantum-platform`: account-linking/admin views;
- `infra-hpc-qc-k8s`: GitOps deployment, secrets and network policies;
- `quantum-workflows`: read-only workflow status contract.
