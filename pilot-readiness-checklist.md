# Pilot Readiness Checklist — Gambia Police Crime System

From working prototype (Laravel + Filament + Flutter, running on localhost) to officers using it in the field.

**Priority legend**
- **[BLOCKER]** — must be done before any officer touches *real* data
- **[PILOT]** — needed for a limited real-world pilot
- **[LATER]** — needed for full rollout, can wait past the pilot

---

## 1. Infrastructure & Deployment
- [ ] **[BLOCKER]** Deploy the backend to a real server (AWS, Cape Town region) instead of `localhost` / `php artisan serve`
- [ ] **[BLOCKER]** HTTPS/TLS with a real domain — the app must talk to the API over HTTPS, not cleartext HTTP
- [ ] **[BLOCKER]** Switch the database from SQLite to **MySQL** (production), with `APP_DEBUG=false` and a generated `APP_KEY`
- [ ] **[BLOCKER]** Move evidence files off local disk to **S3** (or self-hosted MinIO if in-country), private bucket, no public access
- [ ] **[PILOT]** Automated backups — daily DB snapshots + evidence file backups, and confirm you can restore
- [ ] **[PILOT]** Managed process for the app (Laravel Forge or similar) with auto-deploy from the repo
- [ ] **[PILOT]** AWS security baseline: encryption at rest on DB/storage/disk, least-privilege IAM role, locked-down security groups, MFA on the AWS account
- [ ] **[LATER]** Separate **staging** environment so you never test against production
- [ ] **[LATER]** WAF + threat detection (GuardDuty) for the security story

## 2. Security Hardening
- [ ] **[BLOCKER]** Remove `android:usesCleartextTraffic="true"` from the Android manifest and point the app's base URL at the HTTPS domain
- [ ] **[BLOCKER]** Change/remove the seeded default admin (`ADMIN-001` / `change-me-now`) — no default credentials in production
- [ ] **[BLOCKER]** Set Sanctum **token expiry** (currently tokens never expire) and add a clean re-login flow when a token expires
- [ ] **[PILOT]** App lock: PIN or biometric to open the mobile app, since it holds sensitive data and a token
- [ ] **[PILOT]** Secrets out of Git and in a secrets store / server-only `.env`
- [ ] **[PILOT]** A way to revoke a lost/stolen device's token (you already store tokens per-device — add the revoke action in the back office)
- [ ] **[LATER]** Independent security review / penetration test before wider rollout
- [ ] **[LATER]** Certificate pinning in the app for defense-in-depth

## 3. Data Protection & Legal — Gambia PDPP Act, 2025
- [ ] **[BLOCKER]** Confirm the **legal basis** for police processing and check the Act's law-enforcement provisions with a Gambian lawyer
- [ ] **[BLOCKER]** Finalize the **data-residency decision** with the police (in-country vs. foreign cloud) — this drives Section 1
- [ ] **[BLOCKER]** Retention policy + automated **purge job** for offences and (especially) evidence photos
- [ ] **[PILOT]** Record of Processing Activities — document what data you hold, why, and for how long
- [ ] **[PILOT]** Data Protection Impact Assessment (DPIA) for the pilot
- [ ] **[PILOT]** Officer guidance: photograph the vehicle/plate/offence; avoid unnecessary capture of faces and bystanders (data minimisation)
- [ ] **[PILOT]** Data-breach response procedure (the Act requires breach handling)
- [ ] **[LATER]** Register/notify the Commission if required; process for data-subject rights requests

## 4. User & Access Management
- [ ] **[BLOCKER]** A real way to **create and manage officer/supervisor accounts** in the back office (a Filament Users resource with role assignment) — right now only a seeded admin exists
- [ ] **[PILOT]** Onboarding/offboarding process (deactivate = instant loss of access, which you already support)
- [ ] **[PILOT]** Initial password distribution + forced change on first login
- [ ] **[PILOT]** A Filament screen to **view the audit log** (you record it, but there's no UI to review it yet)

## 5. Functional Gaps to Close
- [ ] **[PILOT]** Finalize the **offence-type list** with the police (real Gambian traffic offences), not the placeholder set
- [ ] **[PILOT]** "My recent records" view in the app so officers can see supervisor **confirmed/dismissed** decisions (the `pull` endpoint is ready; no UI yet)
- [ ] **[PILOT]** Edit/correct a **pending** offence on the device before it syncs
- [ ] **[PILOT]** Retry / visibility for **failed** syncs (failed items currently just sit with a red chip)
- [ ] **[PILOT]** Dismissal **reason** field on the supervisor Dismiss action (deferred earlier)
- [ ] **[LATER]** Reporting/analytics in the back office: dashboards, offence hotspots on a map, exports

## 6. Mobile App Production Readiness
- [ ] **[BLOCKER]** Build a **signed release APK** (release keystore) — not the debug build
- [ ] **[BLOCKER]** Decide **distribution**: direct APK / mobile device management (MDM). A public Play Store listing is likely not appropriate for a police app
- [ ] **[PILOT]** Proper **app icon and name** (currently the Flutter defaults)
- [ ] **[PILOT]** Add `CAMERA` permission + runtime request and test the camera on **real low-end Android phones**, not just the emulator
- [ ] **[PILOT]** Clear permission-rationale prompts for location and camera
- [ ] **[PILOT]** Test across the Android versions officers will actually carry
- [ ] **[LATER]** In-app update mechanism for pushing new versions

## 7. Reliability & Operations
- [ ] **[PILOT]** Server-side error logging/monitoring and uptime monitoring
- [ ] **[PILOT]** Crash reporting in the app
- [ ] **[PILOT]** Monitor evidence storage growth against your ~55 GB/year estimate
- [ ] **[PILOT]** A short runbook / handover notes (you're solo — write down how to deploy, restore, rotate keys)
- [ ] **[LATER]** Alerting on failures and storage thresholds

## 8. Testing & QA
- [ ] **[BLOCKER]** End-to-end test on a **physical phone** over real mobile data, including offline capture and reconnect-sync
- [ ] **[PILOT]** Automated backend tests for the critical paths (auth, sync push, image hash verify)
- [ ] **[PILOT]** User acceptance testing with a few actual officers before the pilot
- [ ] **[PILOT]** Deliberate edge-case testing: dead zone, dropped mid-upload, wrong hash, duplicate resend

## 9. Training & Rollout
- [ ] **[PILOT]** Simple one-page officer guide (capture, photo, sync)
- [ ] **[PILOT]** Supervisor training for the back office (review, confirm/dismiss, view evidence)
- [ ] **[PILOT]** Define the **pilot scope** — one unit or location (e.g. a traffic division in one area) before going wide
- [ ] **[PILOT]** Feedback channel and a support plan for the pilot period (who fixes issues, how fast)

## 10. Governance & Sign-off
- [ ] **[BLOCKER]** Formal approval from police leadership to run the pilot with real data
- [ ] **[PILOT]** Written agreement on **data ownership** (data, code, infrastructure) and responsibilities
- [ ] **[LATER]** Incident-response and escalation plan agreed with the force

---

### The short version — true blockers before any officer touches real data
Deployed HTTPS server · MySQL · private cloud storage · no default admin · token expiry · cleartext removed from the app · a way to create officer accounts · signed release APK · a legal basis + residency decision + retention/purge · real-device end-to-end test · leadership sign-off.
