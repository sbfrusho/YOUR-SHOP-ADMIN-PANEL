# Your Shop Admin

Admin panel for the **Your Shop** store (Bangladesh, BDT). Flutter, GetX
(MVVM), Firebase. Runs on Android, iOS and the web; tablets and browsers
get a side rail, phones get a bottom bar.

It shares the Firebase project `nabilrayhanshopping` with the customer app
(`UTM_clothing_app`), which owns `firestore.rules`, `storage.rules` and the
Cloud Functions. Only accounts with `users/{uid}.isAdmin == true` can sign in.

![Dashboard on tablet / web](tool/screenshots/23_dashboard_wide.png)

| Sign in | Dashboard (phone) | Settings |
|---|---|---|
| ![](tool/screenshots/01_login.png) | ![](tool/screenshots/22_dashboard.png) | ![](tool/screenshots/05_settings.png) |

| Orders | Order detail |
|---|---|
| ![](tool/screenshots/08_orders.png) | ![](tool/screenshots/10_order_detail.png) |

![Orders on tablet / web](tool/screenshots/09_orders_wide.png)
![Order detail on tablet / web](tool/screenshots/11_order_detail_wide.png)

| Products | Product form |
|---|---|
| ![](tool/screenshots/13_products.png) | ![](tool/screenshots/15_product_form.png) |

![Products on tablet / web](tool/screenshots/14_products_wide.png)
![Product form on tablet / web](tool/screenshots/16_product_form_wide.png)

| Categories | Banners | Category form |
|---|---|---|
| ![](tool/screenshots/17_catalogue.png) | ![](tool/screenshots/19_banners.png) | ![](tool/screenshots/21_category_form.png) |

![Categories on tablet / web](tool/screenshots/18_catalogue_wide.png)
![Banners on tablet / web, dark](tool/screenshots/20_banners_wide_dark.png)

## Run

```sh
cp env/example.json env/dev.json   # git-ignored; fill in values
flutter run --dart-define-from-file=env/dev.json
flutter run -d chrome --dart-define-from-file=env/dev.json
```

## Check

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter test tool/screenshots_test.dart --update-goldens   # golden PNGs
```

## Layout

```
lib/app/      app, routes, bindings, middlewares (AdminMiddleware)
lib/core/     config, constants, errors, services, theme, utils, widgets, i18n
lib/data/     models, repositories (Firestore only, injectable fakes)
lib/modules/  <feature>/view_models, views, bindings
```

Plan and progress: [docs/ROADMAP.md](docs/ROADMAP.md).
