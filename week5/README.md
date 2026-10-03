# Week 5 — Discord → ACP Persistent Collaboration MVP

This week makes Discord a **user interface into the same authorised Agent Control Plane**, not a second security boundary or a remote shell.

## Core path

```text
Discord event
   ↓
liaison adapter
   ↓ normalize + deduplicate
platform identity/account-link check
   ↓
authorised ACP task
   ↓
persistent task/run/evidence
   ↓
Hermes explanation
   ↓
Discord reply containing safe result/reference
```

## Implementation order

```text
1. Create Discord application/bot and store token privately
2. Define transport-neutral event schema
3. Implement fixture-driven parser tests (no Discord needed in CI)
4. Implement account-link mapping; never trust display names
5. Add idempotency key from provider/message identifiers
6. Call one fixed read-only ACP capability
7. Persist ACP task/run reference before replying
8. Format success/failure response
9. Add rate-limit/retry/duplicate handling
10. Restart the liaison and Hermes; prove result/history survive
11. Test unlinked/unauthorised user denial
12. Capture latency/error telemetry
```

## Secrets

Discord bot tokens are secrets. Use a SealedSecret for the deployed liaison; never commit `.env` or bot tokens.

## CI contract

Use recorded/synthetic fixtures so GitHub Actions can test:

- valid message envelope;
- malformed payload;
- duplicate event;
- unlinked identity;
- authorised command mapping;
- ACP unavailable response mapping.

CI must not need a live Discord token.

## Identity rule

An external provider ID is an input to account linking, not proof of platform authority. Do not infer platform roles from Discord display names/server roles unless the explicit project policy says so.

## Persistence/restart test

1. Submit an authorised request from Discord.
2. Record external message ID + ACP task ID.
3. Delete/restart the liaison pod.
4. Delete/restart the Hermes worker pod.
5. Query the previous task from Student Project Platform/ACP history.
6. Send another Discord request and prove normal recovery.

## Metrics

Record:

```text
end-to-end response latency
ACP queue/run latency
model latency separately
adapter errors/retries
duplicate suppression count
unauthorised request count
```

## Exit gate

The same logical request is auditable end-to-end, duplicate events do not create duplicate tasks, an unauthorised/unlinked account is denied, and restarting chat/agent pods does not erase canonical ACP history.
