# Handoff: Your Shop admin panel

You are continuing work for **Sakib Bin Faruque Rusho**. Over Sprints 1 to 10, the customer app **Your Shop** (`~/Desktop/UTM_clothing_app`) was rebuilt into a production-grade Flutter app for Google Play. The next job is the **admin panel** in `~/Desktop/YOUR-SHOP-ADMIN-PANEL`. It is an older university project (`admin_panel`, GetX, package `com.example.admin_panel`). Bring it up to the same standard, with the same look and the same working style.

The customer app is the reference implementation. When in doubt, open the matching file there and follow it.

---

## 1. Working agreement (follow exactly)

- **Never run `git commit` or `git push`.** The owner commits. At the end of every sprint, give a ready-to-paste commit message in conventional-commit style (`feat(sprint-N): ...`). In my project you must not mention clauded did this/ or co authored by claude or ay ai model
- **Work in sprints.** First read the code and write a sprint plan in `docs/ROADMAP.md` (about 6 to 8 sprints). Then do one sprint per "next" from the owner. After each sprint, summarise what changed, what wasn't done and why, and what the owner must do themselves (console steps, keys, deploys).
- **Finish every sprint with zero errors.** `flutter analyze` reports *No issues found*, `dart format` changes nothing, and all tests pass. Report real results. If something wasn't run (for example, not tried on a device), say so.
- **Never store credentials.** If the owner shares passwords or keys, use them only in that moment. Never write them to files, memory, docs or commit messages. Secret keys live only in Cloud Functions secrets.
- **Ask only when blocked.** Pick sensible defaults, state them, and move on.
- **Show, don't claim.** UI work is checked with golden screenshots (see section 6) that you actually look at.

## 2. Architecture (required: MVVM with GetX)

Use the same layout as the customer app:

```
lib/
  app/        app.dart, routes/ (AppRoutes constants + AppPages), bindings/, middlewares/
  core/       config/ (AppConfig from --dart-define-from-file=env/*.json), constants/
              (FirestorePaths), errors/ (AppException with user-safe messages),
              services/ (GetxService), theme/, utils/, widgets/ (shared UI), i18n/
  data/       models/ (fromMap/toMap, tolerant parsing via json_parsing.dart),
              repositories/ (Firestore access only; injectable FirebaseFirestore)
  modules/<feature>/  view_models/ (XxxViewModel extends GetxController),
                      views/ (XxxView extends GetView<XxxViewModel>), bindings/
```

- View models hold the state as `Rx` values. Views contain no Firebase calls and no business logic.
- Repositories take optional `FirebaseFirestore`, `FirebaseAuth` and `FirebaseStorage` arguments so tests can use fakes.
- User-facing errors go through `AppException.from(e)` and `AppSnackbar`.
- Config comes from `env/example.json` (committed). `env/dev.json` and `env/prod.json` are git-ignored.
- Wrap UI strings in `.tr`. Keys are the English text, as in the customer app's `lib/core/i18n/`.

## 3. Design system (copy it, don't reinvent it)

Copy these files from the customer app as they are: `lib/core/theme/` (`app_colors.dart`, `app_palette.dart`, `app_theme.dart`, `app_typography.dart`), the shared widgets in `lib/core/widgets/` (`AppTopBar`, `AppIconButton`, `LoadingButton`, `state_views.dart`, `skeleton.dart`, `app_network_image.dart`, `section_header.dart`, `brand/`), `lib/core/utils/app_snackbar.dart`, and `assets/fonts/`.

**Look:** calm, premium and neutral. Warm greys and creams, no bright brand colours, a charcoal primary, cream surfaces, and muted status colours. Material 3 in light and dark.

| Token | Hex | Used for |
|---|---|---|
| cream50 | `#FFFCF7` | cards, input fill (light) |
| cream100 | `#F7F2EA` | page background (light) |
| cream200 | `#EFE8DD` | high containers, primary in dark |
| cream300 | `#E5DCCE` | borders, highest containers |
| sand / sandDeep | `#CDBBA0` / `#A8916F` | accent, badges, tertiary |
| grey900 / grey800 | `#22201E` / `#2E2C29` | text, **primary** (light) |
| grey600 / grey500 / grey400 / grey300 | `#56524C` / `#7A746C` / `#A39C92` / `#C9C2B8` | secondary and muted text, outlines |
| night900 to night500 | `#161513` `#1E1C1A` `#282623` `#34312D` `#45413C` | dark surfaces |
| sage / sageLight | `#5F7F5B` / `#9DBA97` | success, *Delivered*, in stock |
| ochre / ochreLight | `#B3803A` / `#D9AE6F` | warning, *Pending*, low stock |
| terracotta / terracottaLight | `#A6473A` / `#E29A8D` | error, *Cancelled*, destructive |
| slate / slateLight | `#4E6A80` / `#9DB6C9` | info, *Shipped* |

- **Fonts:** Manrope for UI text and **Playfair Display** (bold serif) for headlines and the brand. Both are SIL OFL and bundled.
- **Radius:** sm 10, md 14 (buttons and inputs), lg 20 (cards), xl 28 (sheets).
- **Rules:**
  - Widgets read `Theme.of(context).colorScheme` or `context.palette`, never `AppColors` directly.
  - Status chips use the muted status colours. The same chip widget is in `lib/modules/orders/views/order_status_chip.dart`.
  - Large page titles use `AppTopBar.large` with the serif headline.
  - Destructive actions use the error colour and a confirm dialog.
- The logo is drawn in code (`brand_mark_painter.dart`). Reuse it, for example with an "Admin" label next to it.
- **Admin-specific:** the panel will mostly run on tablets and the web. Make layouts responsive: at 900px and wider, use a `NavigationRail` or side menu and data tables. On phones, use the bottom navigation and list layout.

## 4. Shared backend contract (must not break the customer app)

Both apps use the same Firebase project, **`nabilrayhanshopping`**. Field names are shared, so **renaming any field is a data migration, not a refactor.**

**Admins:** `users/{uid}.isAdmin == true`. `firestore.rules` (in the customer repo) grants admins full read and write, and customers can't set `isAdmin`. The customer app refuses to sign in admin accounts, and the admin panel must refuse non-admins in the same way. Add an auth middleware that checks `isAdmin`.

**Collections** (string types are legacy; the admin panel originally wrote numbers as strings):
- `products/{id}` has these fields:
  - `productId`, `productName`, `categoryId`, `productDescription`.
  - `fullPrice` and `salePrice` (strings, in Taka), `isSale`, `quantity` (stock, a **string**).
  - `productSizes` (a list of strings), `productImages` (a list of URLs).
  - `email` (the seller), `deliveryTime`, `createdAt`, `updatedAt`.
  - Sizes share one stock counter.
- `categories/{id}`: `categoryId`, `categoryName`, `categoryImg`.
- `banners/{id}`: `imageUrl`.
- `users/{uid}` has these fields:
  - `uId`, `email`, `name`, `phone`, `isAdmin`, `photoUrl`.
  - `deviceToken` (the latest device) and `fcmTokens` (a list covering all devices).
  - Legacy address fields, including the misspelled `adress`.
  - Subcollections: `cart`, `wishlist` and `addresses`.
- `orders/{id}` has these fields:
  - `customerId`, `uniqueId` (the customer's email), `customerName`, `customerPhone`, `customerAddress`, `customerDeviceToken`.
  - `paymentMethod` (`Card` or `Cash on Delivery`).
  - `paymentStatus`: `unpaid` (COD), `awaiting_payment`, `paid`, `refunded` or `void`.
  - `paymentGateway`: `cod`, `demo` or `stripe`.
  - `paymentReference`, `deliveryTime`, `deliveryType`, `totalPrice` (a number).
  - `status`: `Pending`, `Confirmed`, `Shipped`, `Delivered` or `Cancelled`.
  - `statusHistory` (a map of status to timestamp), `sellerId`, `sellerIds`, `createdAt`, `cancelledBy`.
  - `customerDeleted`: when a customer deletes their account, their orders stay but their personal details are removed. The admin panel must handle these orders.
  - Subcollection `orders/{id}/items`: `product_id`, `product_name`, `price`, `quantity`, `size`, `product_image`.
  - add field for on sale how many % in sale, calculate the sale price 

**The admin panel changes order status by updating `status` only.** The `onOrderWritten` Cloud Function then:
- records `statusHistory.<Status>`,
- emails the customer (through the `mail` collection and the Trigger Email extension),
- sends a push notification to every device in the customer's `fcmTokens`.

Don't send notifications from the admin app. Valid flow: Pending → Confirmed → Shipped → Delivered, or Cancelled. Cancelling must **restock** the items, and a Stripe-paid order needs a refund. Prefer adding an admin Cloud Function (for example `adminCancelOrder`, in the customer repo's `functions/`) over doing stock maths in the client.

Other Cloud Functions, in region `asia-southeast1`, in the customer repo: `createPaymentIntent`, `stripeWebhook`, `expireUnpaidOrders`, `placeOrder`, `cancelOrder`, `deleteAccount`, `onOrderWritten`. Their docs are in `docs/BACKEND.md` there. **Rules and functions live in the customer repo.** If the admin panel needs a rule or function change, make it there, add its tests (`test/firestore_rules`, `functions/test`), and tell the owner both must be deployed together.

**Locale:** the shop serves **Bangladesh**. Currency is BDT, shown as `Tk 1,290` (copy `Formatters.price`). Phone numbers look like `01712-345678`, and addresses default to Bangladesh. The customer app's second language is currently Bahasa Melayu; Bangla is being considered.

## 5. What the admin panel should end up doing (proposed scope)

Confirm this with the owner in the sprint plan:
- Sign-in with an `isAdmin` check, a session guard and sign-out.
- **Dashboard:** today's orders and revenue, pending orders, low stock, best sellers.
- **Orders:**
  - Live list with filters (status, payment status, date) and search.
  - Detail view with items, customer and address, and the status timeline.
  - Status changes with confirmation, cancel with restock.
- **Products:** list, create, edit and archive, with image upload to Firebase Storage, sizes, sale price and stock. Write the same field formats as the legacy data.
- **Categories and banners:** CRUD with images.
- **Customers:** read-only list and order history, and account disable if needed.
- Light and dark themes, responsive layout, offline banner, tests and CI (same as the customer app's `.github/workflows/ci.yml`).
- Release: a new package ID (for example `com.sbfrusho.yourshopadmin`) and its own Firebase app registration.

## 6. Quality bar and tools used so far

- **Tests:**
  - `fake_cloud_firestore`, `firebase_auth_mocks` and `mocktail` for repositories and view models.
  - Widget tests for key screens.
  - One flow test (real view models on fakes).
  - See `test/` in the customer repo.
- **Screenshot harness:** `tool/screenshots_test.dart` in the customer repo renders the real views with fake data at 1080×2340 into golden PNGs, using the real fonts. Copy that approach. After UI changes, regenerate with `--update-goldens` and **look at the images** before calling the work done.
- **CI:** GitHub Actions runs format, analyze, tests and an app bundle build (plus web for the admin panel).
- **Docs:** keep `README.md` (with screenshots), `docs/ROADMAP.md` and any backend notes current.
- **Lint clean:** `flutter_lints`, sorted imports, no deprecated APIs. If a deprecated call is unavoidable, add an `ignore` comment that explains why.

## 7. Known owner to-dos (remind them; don't do them yourself)

- Register `com.sbfrusho.yourshop` (and later the admin package) in Firebase with SHA-1, and replace `google-services.json`. The customer app's current file contains a stop-gap copy of the old client.
- Upgrade to the Blaze plan, enable Storage, then run `firebase deploy --only functions,firestore,storage` from the customer repo, with `FUNCTIONS_BASE_URL` set in the app.
- Check that real admin accounts have `isAdmin: true` before the rules are deployed.
- Payments: Stripe doesn't sign up Bangladeshi merchants, so bKash or SSLCommerz is the likely gateway and needs merchant credentials.
