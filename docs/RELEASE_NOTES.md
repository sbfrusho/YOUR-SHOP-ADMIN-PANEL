# Release notes

## 1.0.0 (first release)

The admin panel is rebuilt from scratch to the same standard as the shop app:
MVVM with GetX, the shared calm grey-and-cream design, light and dark themes,
and layouts for phones, tablets and the web.

**Sign-in**
- Email sign-in for admin accounts only (`isAdmin`); customers are refused,
  and an admin who loses access is signed out at once. Forgot password.

**Dashboard**
- Revenue and orders today (compared with yesterday), orders to confirm and
  to ship, a 14-day revenue chart, best sellers of the last 30 days and low
  stock. Every tile opens the matching filtered list.

**Orders**
- Live list with status, payment and date filters and search by name,
  phone, email or order number. Detail with items, customer, payment and a
  status timeline. Move orders along Pending → Confirmed → Shipped →
  Delivered; the customer is emailed and notified automatically. Cancel
  with restock and refund (through the server).

**Products**
- Live list with search, stock and category filters. Create and edit with
  several photos, sizes, stock, delivery time and a sale percentage with the
  sale price worked out. Archive instead of delete, so past orders keep
  their products.

**Catalogue**
- Categories with images: renaming updates their products; a category in
  use can't be deleted. Home banners: add several at once, drag to reorder,
  delete.

**Customers**
- Searchable list and a detail page with contact details, saved addresses,
  order history and totals. Disable or re-enable an account (signs the
  customer out everywhere; orders are kept).

**Quality**
- Tap targets of at least 48 dp, labelled controls and WCAG AA text
  contrast, checked by tests on every main screen in both themes.
- Unit, widget and end-to-end flow tests; CI checks format, analysis and
  tests and builds the web app and the Android bundle.

**Needs the backend** (customer repo, `firebase deploy`): cancelling orders,
disabling accounts and uploading images.
