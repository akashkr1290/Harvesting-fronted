# HarvestFlow — Flutter Frontend

Flutter implementation of the Harvesting Planning, Purchase, Sales & Logistics
Workflow System — all 11 workflow stages, Admin, and Reports, fully wired to
the Spring Boot backend (`harvestflow-backend`).

## What's built

**Core workflow (all 11 stages, matching the state machine both apps share):**

1. **Plot Selection** — full form with mandatory/numeric validation,
   harvesting-date-after-visit-date check, duplicate prevention, priority tag,
   search/filter list, timeline view. Also doubles as the **edit** form
   (`existingCase:` param) — editable only while the backend still considers
   the case `SUBMITTED_FOR_PLANNING`; the edit button only shows client-side
   when that's true, but the backend independently re-checks this on save
   (a stale client can't bypass it).
2. **Planning** — schedule, team assignment (supervisor, pickup person,
   vehicle), notes for Godown/Supervisor.
3. **Purchase Rate Update** — Purchase Account Team sets the rate before
   Godown issues material (per SOW section 4, Step 4).
4. **Packing Material Issue** — multi-line item entry against the Packing
   Items master list, receiver, remarks.
5. **Harvest Completion** — actuals, quality/wastage notes, weight slip
   upload (via `image_picker`; the file itself isn't yet persisted to the
   backend — see "Not yet built").
6. **Pickup Entry** — driver name, amount, advance payment.
7. **Transport Entry** — same shape as Pickup, shared screen
   (`LogisticsEntryScreen`, parameterized by kind).
8–9. **Labor + Local Labor** — entered together in one screen since one
   role owns both and local labor is optional ("if any").
10. **Packing Material Return** — reconciliation against issued quantities,
    for inventory control.
11. **Purchase Invoice** — auto-pulls farmer/weight data, configurable
    cost-calculation engine (toggle commission/packing/transport on or off),
    live net-payable calculation.
12. **Sales Invoice** — buyer, rate, tax, total. Flagged in-app as scope
    still being confirmed with the client (see Working Approach doc).

**Eicher Truck Driver** — since the SOW describes this role as confirming
loading/transit/delivery milestones but doesn't give it a dedicated status
in the workflow table, it's built as an informational milestone log
(`EicherTripScreen`) that doesn't gate the pipeline.

**Documents** — every case's Browse Cases entry shows download/share
buttons for whichever PDFs actually exist for it (selection report always;
issue slip, purchase invoice, sales invoice once each stage happens).
Tapping one fetches the PDF from the backend and hands it to the device's
native share sheet — pick WhatsApp, email, or anything else installed.
This is deliberately not a WhatsApp/email API integration on either side;
see the backend README for why.

**Admin module:**
- User management — create with auto-generated username/temp password
  (shown once in a dialog, never re-displayed), activate/deactivate, reset
  password.
- Master data — tabbed CRUD for all 9 categories (locations, villages,
  agents, farmers, companies, crop types, vehicle types, packing items, UOM),
  with active/inactive toggling.
- Overview — stage-wise counts, location filter, export stub.

**Reports & Dashboards** — daily snapshot, stage-wise pending report,
purchase summary by farmer, sales summary by company, recovery/pulp
analytics — pulled from the backend's `GET /api/reports/summary`, computed
server-side over every case rather than just this device's local cache.

**Auth** — real JWT login against the backend; the shared `ApiClient`
instance carries the token to every other service automatically once set.

## Architecture notes

- **One state machine, one dashboard.** `DashboardScreen` shows each role's
  pending queue via `CaseStatus.nextActorRole`, and routes a tap to the
  correct stage screen — including disambiguating the two roles (Purchase
  Account, Godown) that own two different stages, by checking `case.status`.
- **All screens talk to services, never to raw HTTP** — `CaseService`,
  `UserService`, `MasterDataService`, `ReportsService`, `AuthService` are
  the only places that know about `ApiClient`; screens call service
  methods and never touch `http` directly.
- **Every stage screen goes through `SubmitStateMixin`** (`widgets/form_helpers.dart`)
  for its submit button — loading state, and consistent surfacing of the
  backend's actual 403 (wrong role for this action) / 409 (case moved to a
  different stage) messages rather than a generic failure or, worse,
  silently doing nothing.
- **Shared widgets** (`SectionHeader`, `DateField`, `LabeledValue`,
  validators, `SubmitStateMixin`) live in `widgets/form_helpers.dart`.

## Not yet built

- Actually uploading the weight slip / plot photo file to the backend —
  `image_picker` captures it locally, but nothing sends the bytes anywhere
  yet (the backend has plain string fields for these, not a real upload
  endpoint — see the backend README).
- Automatic email/WhatsApp sending — see "Documents" above; this is a
  deliberate scope decision, not a gap, unless automatic server-sent email
  is wanted later.
- Excel export (button wired, shows a placeholder message).
- Session timeout enforcement, forgot-password flow, login history view.

## Configuring the backend URL

`lib/services/api_config.dart` defaults to `http://localhost:4000` (or
`http://10.0.2.2:4000` automatically when running on an Android emulator,
since `localhost` there refers to the emulator itself, not the host
machine). Override at run time if the backend lives elsewhere:

```bash
flutter run --dart-define=API_BASE_URL=http://your-host:4000
```

## Running it

```bash
flutter pub get
flutter run
```

Requires the backend running (see `harvestflow-backend/README.md` — the
same seeded users/master data/sample cases exist on both sides so the two
apps demo consistently against each other). Log in as different roles to
walk a case through the whole pipeline end to end — the backend README has
the full seeded login table (e.g. `priya.sharma` / `plot123` for Plot
Selection, `admin.user` / `admin123` for Admin).

## Project structure

```
lib/
  main.dart                     # Provider setup — one shared ApiClient injected into every service
  models/                       # One model per stage's data shape, each with toJson/fromApi
  services/
    api_client.dart             # Shared HTTP layer — JWT header, JSON + binary (PDF) responses, ApiException mapping
    api_config.dart             # Backend base URL (with the Android-emulator localhost fix)
    auth_service.dart           # Real JWT login/logout
    case_service.dart           # All 11 stage transitions — the one file that knows every /api/cases/* endpoint
    user_service.dart           # Admin user management
    master_data_service.dart    # Admin master data
    reports_service.dart        # GET /api/reports/summary
  screens/
    login_screen.dart
    dashboard_screen.dart       # Routes pending cases to the right stage screen; pull-to-refresh
    plot_selection_form_screen.dart  # Create AND edit (existingCase: param)
    plot_selection_list_screen.dart  # "Browse Cases" — search/filter, timeline, edit, document downloads
    planning_form_screen.dart
    purchase_rate_screen.dart
    godown_issue_screen.dart / godown_return_screen.dart
    supervisor_completion_screen.dart
    logistics_entry_screen.dart  # Pickup + Transport (shared)
    labor_entry_screen.dart      # Labor + Local Labor (combined)
    purchase_invoice_screen.dart
    sales_invoice_screen.dart
    eicher_trip_screen.dart
    reports_screen.dart
    admin/
      admin_overview_screen.dart
      user_management_screen.dart
      master_data_screen.dart
  widgets/
    case_card.dart               # Shared case summary card, with an optional trailingAction slot
    document_actions.dart        # DocumentDownloadButton — fetch PDF bytes, hand off to native share sheet
    form_helpers.dart             # SectionHeader, DateField, LabeledValue, validators, SubmitStateMixin
  theme/                        # AppTheme
```
