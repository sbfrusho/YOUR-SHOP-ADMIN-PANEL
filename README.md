# Your Shop Admin

Admin panel for the **Your Shop** store (Bangladesh, BDT). Flutter, GetX
(MVVM), Firebase. Runs on the web, Android and iOS: tablets and browsers get
a side rail and tables, phones get a bottom bar and cards.

It shares the Firebase project `nabilrayhanshopping` with the customer app
(`UTM_clothing_app`), which owns `firestore.rules`, `storage.rules` and the
Cloud Functions. Only accounts with `users/{uid}.isAdmin == true` can sign in.

![Dashboard on tablet / web](tool/screenshots/23_dashboard_wide.png)

## What it does

| Area | |
|---|---|
| **Dashboard** | Revenue and orders today, orders to confirm and ship, 14-day revenue chart, best sellers (30 days), low stock |
| **Orders** | Live list with filters and search; detail with items, customer, payment, timeline; status changes; cancel with restock and refund |
| **Products** | Search and stock/category filters; create and edit with photos, sizes, stock and sale percentage; archive |
| **Catalogue** | Categories with images (rename updates products, in-use ones can't be deleted); home banners with drag-to-reorder |
| **Customers** | Search; detail with contacts, addresses, order history and totals; disable or re-enable an account |

Light and dark themes, offline banner, 48 dp tap targets and WCAG AA text
contrast (checked by tests).

| Sign in | Dashboard | Orders | Order detail |
|---|---|---|---|
| ![](tool/screenshots/01_login.png) | ![](tool/screenshots/22_dashboard.png) | ![](tool/screenshots/08_orders.png) | ![](tool/screenshots/10_order_detail.png) |

| Products | Product form | Categories | Banners |
|---|---|---|---|
| ![](tool/screenshots/13_products.png) | ![](tool/screenshots/15_product_form.png) | ![](tool/screenshots/17_catalogue.png) | ![](tool/screenshots/19_banners.png) |

| Customers | Customer | Category form | Settings |
|---|---|---|---|
| ![](tool/screenshots/24_customers.png) | ![](tool/screenshots/27_customer_detail.png) | ![](tool/screenshots/21_category_form.png) | ![](tool/screenshots/05_settings.png) |

![Orders on tablet / web](tool/screenshots/09_orders_wide.png)
![Product form on tablet / web](tool/screenshots/16_product_form_wide.png)
![Customer on tablet / web](tool/screenshots/26_customer_detail_wide.png)
![Dark mode](tool/screenshots/06_shell_wide_dark.png)

## Run

```sh
cp env/example.json env/dev.json   # git-ignored; set FUNCTIONS_BASE_URL
flutter run --dart-define-from-file=env/dev.json
flutter run -d chrome --dart-define-from-file=env/dev.json
```

Without `FUNCTIONS_BASE_URL`, everything works except cancelling orders and
disabling accounts (the buttons explain why).

## Check

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test                                              # incl. accessibility and flows
flutter test tool/screenshots_test.dart --update-goldens  # golden PNGs, look at them
```

CI (`.github/workflows/ci.yml`) runs format, analyze and tests and builds the
web app and the Android bundle on every push and pull request.

## Release

Web on Firebase Hosting (`firebase deploy --only hosting:admin`) and a signed
Android bundle: see [docs/RELEASE.md](docs/RELEASE.md). Changes:
[docs/RELEASE_NOTES.md](docs/RELEASE_NOTES.md).

## Layout

```
lib/app/      app, routes, bindings, middlewares (AdminMiddleware)
lib/core/     config, constants, errors, services, theme, utils, widgets, i18n
lib/data/     models, repositories (Firestore only, injectable fakes)
lib/modules/  <feature>/view_models, views
```

Plan and progress: [docs/ROADMAP.md](docs/ROADMAP.md).
