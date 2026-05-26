# Email Tiers

NetLocal uses a tiered email model. Set `EMAIL_TIER` in `.env` to choose how much of the mail stack you need. Higher tiers include everything from the tiers below them.

---

## Tier reference

| Tier | Services added | Use case |
|---|---|---|
| `1` | Mailpit | Development: capture all outbound mail without delivering it |
| `2` | Stalwart, SnappyMail | Full self-hosted mail with SMTP, webmail |
| `3` | + Dovecot | Add standard IMAP access for mail clients (Thunderbird, Apple Mail, etc.) |
| `4` | + Postfix relay | Enable real outbound delivery to external addresses |

---

## Tier 1 — Mailpit (dev trap)

The simplest setup. Mailpit intercepts all outbound SMTP and presents a web UI showing every captured message. Nothing is actually delivered.

- **Services:** `mailpit`
- **Web UI:** `http://mail.localnet`
- **SMTP port:** 1025 (inside the network)
- **Use when:** You're developing locally and want to inspect outbound email without a real mail server.

---

## Tier 2 — Stalwart + SnappyMail

A complete, production-capable mail server with a modern webmail interface.

- **Services:** `stalwart` (SMTP + IMAP + JMAP), `snappymail` (webmail)
- **Stalwart admin:** `https://mail.localnet/admin`
- **Webmail:** `https://mail.localnet`
- **Ports:** 25 (SMTP), 465 (SMTPS), 143 (IMAP), 993 (IMAPS), 4190 (ManageSieve)
- **Use when:** You want a full local mail server with webmail, but don't need to receive IMAP from external mail clients.

---

## Tier 3 — + Dovecot IMAP

Adds Dovecot as a dedicated IMAP server alongside Stalwart, for mail clients that need standard IMAP.

- **Services:** tier 2 + `dovecot`
- **Additional ports:** 143 (IMAP), 993 (IMAPS)
- **Use when:** You use a desktop mail client (Thunderbird, Apple Mail, Outlook) and need to connect via IMAP.

---

## Tier 4 — + Postfix relay

Adds Postfix as an outbound mail relay for real delivery to external email addresses.

- **Services:** tier 3 + `postfix-relay`
- **Relay port:** 587 (submission)
- **Use when:** You need the stack to send real email outbound (alerts, notifications, user signups).
- **Note:** Requires a valid sending domain, proper SPF/DKIM/DMARC records, and a clean IP. Consider using an SMTP relay service (Mailgun, SES, SendGrid) instead of direct delivery.

---

## Changing tiers

Edit `EMAIL_TIER` in `.env` and restart:

```bash
# Edit .env: EMAIL_TIER=2
make restart
```

> Switching tiers does not migrate mail data. If you have mail stored in Stalwart/Dovecot volumes and switch to a lower tier, that data remains in the volume but the services are stopped.
