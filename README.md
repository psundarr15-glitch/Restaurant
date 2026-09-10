# Jeevi Foodie — Restaurant App (Flutter)

Flutter client for restaurant managers — accept/reject incoming orders,
manage the menu, and edit the restaurant's profile. Built the same way
as the customer app: no local Flutter install needed to get an APK,
GitHub Actions builds it for you.

## ⚠️ Backend requires a new patch first

Unlike the customer/delivery-partner apps, **restaurant managers
previously had no REST API at all** — only the session-based Admin web
panel. This app talks to a brand-new `manager/*` API added specifically
for it (`Api\ManagerAuthApiController`, `Api\ManagerApiController`,
routes added to `Config/Routes.php`).

**Before this app can log in, deploy the backend patch** (in the
`restaurant_manager_backend_patch/` folder alongside this app, or ask
for it again if you don't have it):
1. Copy its files over your backend's `app/` folder
2. Run the two new migrations (`php spark migrate`) — they add an
   `api_token` column to `admins` and a new `admin_device_tokens` table
3. Restaurant manager accounts are created the same way as before
   (Admin panel → Managers, or `Admin\ManagerController`) — they just
   also now work for logging into this app with the same email/password

See that patch's own README for the full list of new endpoints.

## 1. Backend URL

Already set in `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'https://food.tvkomalur.xyz/api';
```

## 2. Push this project to GitHub

```bash
git init
git add .
git commit -m "Restaurant app"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

## 3. Get the APK

Pushing to `main` automatically triggers **Build APK**
(`.github/workflows/build-apk.yml`):

1. Repo → **Actions** tab → latest **Build APK** run (~4-6 min)
2. **Artifacts** → download `restaurant-app-release-apk`
3. Unzip → `app-release.apk` → install on an Android phone

Push notifications (new-order alerts) need their own Firebase Android
app registration — see the comments in `build-apk.yml`'s "Set up
Firebase" step for the one-time setup (**register a separate Android
app in Firebase with package name `com.foodexpress.restaurant_app`** —
don't reuse the customer app's `google-services.json`, the package
names differ). Without that secret configured, the app still builds
and works fine — it just won't receive push notifications, and the
manager will need to check the Orders tab (or dashboard, which polls
every 20s) manually.

## What's wired up

- Manager login (email + password — see `Api\ManagerAuthApiController`)
- Dashboard: total orders, menu item count, revenue, incoming orders
  needing a decision, recent order history
- Orders: Incoming tab (accept/reject) + full history tab, order detail
  with items/bill/customer call button
- Push notification the moment a new order is placed (tap → straight to
  that order); dashboard also polls every 20s as a fallback
- Menu management: add/edit/delete items, one-tap availability toggle,
  photo upload, create new menu sections (sub-categories) inline
- Restaurant profile: name, description, cuisine, hours, prep time,
  contact info, address, FSSAI/GST numbers, bank details, photo

## Scope trimmed vs. the customer app (by design, to keep this focused)

- **No Tamil localization** — the customer-facing app needs it far more
  than an internal staff tool; happy to add `l10n.yaml` + arb files the
  same way if you want it later.
- **No dark-mode toggle screen** — `theme.dart` already supports light
  and dark (copied from the customer app), and `ThemeMode.system`
  follows the phone's setting automatically; there's just no in-app
  switch to override it.
- **A manager can only Accept or Reject a newly-placed order** — once
  confirmed, order status moves forward via the delivery partner app
  (pickup → out for delivery → delivered), matching how the backend's
  `OrderModel::$STATUS_FLOW` already works. If you also want managers
  to force-cancel an order *after* confirming (e.g. kitchen ran out of
  an item mid-prep), that's a small addition to `ManagerApiController`
  — say the word.

## Project structure

Same layout as the customer app:

```
lib/
  config/api_config.dart      – backend base URL + endpoint paths
  models/                     – Manager, Restaurant, Category/SubCategory, MenuItem, Order
  services/                   – one file per backend API controller
  state/app_state.dart        – login state + pending-order badge count
  theme.dart                  – same Jeevi Foodie brand colors as the customer app
  screens/                    – auth, dashboard, orders, menu, profile
  widgets/root_shell.dart     – bottom nav (Dashboard / Orders / Menu / Profile)
```
