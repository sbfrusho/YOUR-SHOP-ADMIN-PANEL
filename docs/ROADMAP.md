# Your Shop Admin: roadmap

The admin panel is being rebuilt to the same standard as the customer app
(`~/Desktop/UTM_clothing_app`): MVVM with GetX, the shared design system,
tests, golden screenshots and CI. One sprint per "next" from the owner.

Every sprint ends with `flutter analyze` clean, `dart format` unchanged and all
tests passing.

## Defaults chosen (change any of them by saying so)

- **Package:** Dart package `your_shop_admin`, Android/iOS ID
  `com.sbfrusho.yourshopadmin`. Platforms: Android, iOS and **web**.
  Desktop folders (macOS, Windows, Linux) are dropped.
- **Legacy code:** the old `lib/` (screens, controllers, seller flow) is
  replaced, not migrated. The separate **seller** role and its screens are
  dropped. Every admin sees every product and order (as `firestore.rules`
  already allows). `email` on a product is still written, as the admin's email.
- **Sign-up is removed.** Admins are created by setting `isAdmin: true` on an
  existing `users/{uid}` in the console. The panel refuses non-admins.
- **Language:** English with `.tr` keys, ready for Bangla. No second
  language ships until the owner decides.
- **Sale percentage:** products gain a new numeric `salePercent` field
  (0 to 90). The form computes `salePrice = fullPrice × (1 − percent/100)`,
  rounded to whole Taka, and still writes `salePrice` as a string so the
  customer app keeps working unchanged.

## Sprints

### Sprint 1: Foundation and sign-in
- New pubspec (current Firebase and GetX, same versions as the customer app),
  lints, fonts, design system and shared widgets copied from the customer app.
- MVVM folder layout, `AppConfig`, `FirestorePaths`, `AppException`,
  `AppSnackbar`, formatters, tolerant JSON parsing.
- Email sign-in with an `isAdmin` check, `AdminMiddleware` session guard,
  forgot password and sign-out. Splash routing.
- Responsive shell: `NavigationRail` at 900px and wider, bottom navigation on
  phones. Placeholder pages for Dashboard, Orders, Products, Catalogue
  (categories and banners) and Customers.
- Light, dark and system themes. Offline banner.
- Regenerated platform folders with the new package ID and web support.
- Tests (repositories, view models, middleware, widget), the golden
  screenshot harness and CI (format, analyze, test, app bundle, web).

### Sprint 2: Orders
- Live order list with filters (status, payment status, date range) and
  search (name, phone, email, order ID). Data table on wide screens.
- Order detail: items, customer and address, payment, status timeline.
  Handles `customerDeleted` orders.
- Status changes (update `status` only) with confirmation. Only valid next
  steps are offered.
- **Customer repo:** `adminCancelOrder` Cloud Function (restock, Stripe
  refund, `cancelledBy: 'admin'`) and its tests.

### Sprint 3: Products
- Product list (table or list) with search, category filter, stock filter.
- Create and edit: images to Firebase Storage, sizes, full price, sale
  percentage with computed sale price, stock, delivery time, category.
  Writes legacy string formats.
- Archive instead of delete (`isArchived`; customer app hides archived
  products, which needs a small change and rule test in the customer repo).

### Sprint 4: Categories and banners
- CRUD with image upload. Prevent deleting a category that still has
  products. Banner ordering.

### Sprint 5: Dashboard
- Today's orders and revenue, pending orders, low stock, best sellers (last
  30 days), a simple revenue chart.

### Sprint 6: Customers
- Read-only customer list with search, detail with order history.
- Account disable through an admin Cloud Function (customer repo), if wanted.

### Sprint 7: Polish and release
- Accessibility pass, empty and error states, flow test end to end.
- README with screenshots, launcher icon and splash for "Your Shop Admin".
- Release signing, web build for Firebase Hosting, release notes.

## Owner to-dos (not done by me)

- Register `com.sbfrusho.yourshopadmin` (Android, and web app) in Firebase
  with SHA-1 and replace `android/app/google-services.json` and
  `lib/firebase_options.dart` (`flutterfire configure`). Until then CI patches
  the file, and the web build uses the old web config.
- Make sure real admin accounts have `isAdmin: true` before the rules deploy.
- Blaze plan, Storage enabled, then `firebase deploy --only
  functions,firestore,storage` from the customer repo after Sprint 2 and 3.
- Payments: Stripe doesn't onboard Bangladeshi merchants; bKash or
  SSLCommerz needs merchant credentials.
