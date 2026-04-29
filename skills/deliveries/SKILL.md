---
name: Delivery Tracking
description: Track packages and deliveries. Use when the user asks about shipments, parcels, or tracking numbers.
---

Track pending deliveries using the `delivery-cli` command. State is stored automatically.

## Commands

### Add a package

```bash
delivery-cli add --carrier dhl --description "USB-C cables" 00340434540333441700
```

Always ask the user which carrier a package is from.

### Check for updates

```bash
delivery-cli check
```

Queries 17track for all tracked packages and reports any status changes.

### Show all tracked packages

```bash
delivery-cli status
```

### Remove a delivered/cancelled package

```bash
delivery-cli remove 00340434540333441700
```

## Supported carriers

`dhl`, `dhl-express`, `dhl-parcel`, `deutsche-post`, `dpd`, `hermes`, `gls`, `ups`, `fedex`, `amazon`

If the user says "DHL", use `dhl` (domestic German parcels). Use `dhl-express` for international express shipments.

## Periodic checks

When there are pending deliveries, ensure your HEARTBEAT.md contains a task like:

```
- [ ] Every 6h — Run `delivery-cli check` and notify the user of any status changes.
```

When all deliveries are delivered or removed, remove the heartbeat task.

## Tips

- The user may give you a tracking number directly, or paste a shipping confirmation email. Extract the tracking number from it.
- Always ask for the carrier if the user doesn't mention it.
- When listing deliveries, use `delivery-cli status`.
- After a package is delivered, ask if the user wants to remove it from tracking.
