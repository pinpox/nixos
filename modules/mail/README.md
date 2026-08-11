# Mail (Stalwart) — user FAQ

## What is declarative and what is not

Declarative, in `modules/mail/default.nix` via `stalwart-reconcile` unit:

- Pocket ID as the authentication directory
- Domains, with their catch-all addresses and alias domains
- Cross-domain send-as aliases for people (`pinpox.services.mail.accounts`)
- The mail-port TLS certificate and the HTTP settings

Not declarative:

- Accounts, both for people and for applications
- All credentials: passwords, app passwords, API keys

Service accounts are made with the `stalwart-app-account` helper on the mail host
(below); people's accounts appear on first OIDC login. Secrets are never in the
store.

The reconciler only patches the keys present in its plan, so anything you set by hand
survives future deploys.

## How do I get into the admin UI?

Admin UI at: https://mail.pinpox.com

- user: `admin`
- password: `clan vars get clementine stalwart-admin/password`

## Adding users

### For people:

Nothing to do, the account is provisioned on first OIDC login through Pocket ID
as `<preferred_username>@pinpox.com`.

### For Applications

On the mail host, as root:

```bash
stalwart-app-account uptime-kuma --ip 10.42.0.7  # Creates or updates uptime-kuma@pinpox.com
stalwart-app-account uptime-kuma --list          # id, created, allowed IPs
stalwart-app-account uptime-kuma --revoke b      # id from --list, to disable without reissuing
```

Connection parameters

- host: `mail.pinpox.com`
- submission (send): port `465`, **implicit TLS** — pick "SSL/TLS", not STARTTLS
- IMAP (receive): port `993`, implicit TLS
- auth: `AUTH PLAIN` (submission also offers `LOGIN`; both also do `XOAUTH2`/`OAUTHBEARER`)
- username: the full address, e.g. `uptime-kuma@pinpox.com`
- password: the `app_…` secret
- max message size: 100 MiB

Ports `587` and `143` (STARTTLS) are deliberately closed, so a client that defaults to
them will fail; `25` is inbound MX only and takes no submissions. Mail clients pointed
at a bare address find all of this by themselves via `autoconfig.<domain>`.

## How do I add an app password for myself (phone, mail client)?

Self-service: log in as yourself → Account ▸ Credentials ▸ App Passwords ▸ *Create App
password*. This page can only ever act on the account you are logged in as.

## Gotchas

- Secrets never read back — the UI shows `****`. Lost a service account's password ⇒
  just re-run `stalwart-app-account <name>`; for your own, delete it and mint a new one.
- Max 5 app passwords and 5 API keys per account. `stalwart-app-account` cannot hit
  that: it clears the account's old passwords on every run.
- Service accounts are managed by `stalwart-app-account`, not the UI: the UI's App
  Passwords page can only ever act on the account you are logged in as.
