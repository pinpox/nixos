---
name: nats
description: Read and publish clan events on the NATS bus with the `nats` CLI
---

You can read from and publish to the clan's NATS message bus with the `nats`
CLI (already on your PATH). `NATS_URL` and `NATS_NKEY` are preset in your
environment, so commands need no connection flags.

## What you're allowed to touch

The broker enforces a per-persona ACL: subscribing or publishing to any subject
outside your grant is rejected. Your allowed subjects are in your environment:

```bash
echo "read:  $NATS_READ_SUBJECTS"
echo "write: $NATS_WRITE_SUBJECTS"
```

Subjects may contain wildcards (`*` matches one token, `>` matches the rest).

## Reading events

Core NATS keeps no history — you only receive messages published *after* you
subscribe, so always bound the read with `--count` and/or `--wait`:

```bash
# the next single message on one of your readable subjects
nats sub --count 1 "<subject>"

# up to 5 messages, or give up after 30s of silence
nats sub --count 5 --wait 30s "<subject>"
```

## Publishing events

```bash
nats pub "<subject>" '{"example":"compact single-line JSON"}'
```

Use compact single-line JSON payloads.

## Request / reply

```bash
nats request "<subject>" '{"q":"..."}' --timeout=5s
```
