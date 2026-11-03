# Purchase journey audit — 3 November 2026

Scope: current Flutter source from Home and health concerns through catalogue, product detail, cart, checkout, payment, and order details. Existing suite: 222 tests passed. This is a source/flow review, not a live payment transaction, backend validation review, or rendered-device usability study. Homepage rails are retained as requested. No application code was changed.

## Prioritized findings

### P1 — Partial-COD orders have no payment recovery action
`lib/features/orders/screens/order_detail_screen.dart:70` renders OrderPaymentRetryBanner only for CASHFREE. Checkout accepts PARTIAL_COD and routes cancelled/failed advance payments to this same order screen. A customer who cancels the advance payment therefore reaches an order with no in-app completion action. Include unpaid partial-COD orders, exclude already ADVANCE_PAID/PAID orders, and display the advance amount rather than implying full payment. Test cancellation and gateway-session failure for both payment modes.

### P1 — Redeemed coins can exceed the new cart limit
`lib/features/cart/widgets/cart_coupons_and_coins.dart:1022` clamps the displayed currentPoints to the new maximum but does not update the shared draft. Cart and checkout totals subtract raw draft.pointsToRedeem; submission sends the same raw amount. Example: redeem 300 coins on a ₹1,000 cart, then reduce the subtotal to ₹200. The editor may show the new 60-coin cap while the total subtracts 300. Normalize shared redemption whenever subtotal/balance changes, and use that one value in editor, summary, and request. Server rejection or actual over-redemption depends on backend rules, which were not audited.

### P2 — Applied coupon amount becomes stale after cart edits
Coupon validation runs when the user applies a code, while CheckoutDraft retains its discount across item/quantity changes. Summaries use the stored amount. A percentage discount or minimum-spend coupon can remain displayed after the qualifying cart changes. Revalidate against a cart revision, ignore stale validation responses, and show an explicit removed/updated-discount message before payment. Test reducing quantity below the threshold and changing a percentage-discount subtotal.

### P2 — Stock readiness checks ignore the selected pack
Cart's out-of-stock checks use product.inStock and skip combo entries; they do not compare item quantity with the selected variant's stock. Checkout's _canPlace also has no stock check. A selected pack can become unavailable while the overall product is still in stock, allowing users to reach payment confirmation before the server rejects it. Derive readiness from variant/quantity and bundle members, refresh before final submission, and place the corrective action beside the item. The backend remains authoritative for inventory.

### P2 — Product-detail pincode checks can display stale results
`_PincodeCheckState._check` in `lib/features/products/screens/product_detail_screen.dart` does not associate a result with the current input. Keyboard submission can invoke checks while another is running; editing the field also leaves the old result visible. An older response can update both the displayed result and saved global pincode. Use request identity and input matching, invalidate results on edit, and validate six numeric digits rather than length alone. Checkout already has request tracking; extend the same behavior to discovery checks.

### P2 — Payment-page failures lack an explicit recovery state
`lib/features/checkout/screens/cashfree_checkout_screen.dart` handles page start/finish and redirects, but has no web-resource error state. Failed main-page loads can leave a blank gateway. Unsupported external payment schemes are prevented without feedback when launch fails. Show an inline load error and Retry/Return to order; explain when a selected UPI app cannot open. Keep verification server-based and always preserve the existing order ID.

### P2 — Purchase analytics are recorded before payment
`lib/features/checkout/screens/checkout_screen.dart` calls logPurchase immediately after order creation, before gateway launch, without paymentMethod. The analytics service defaults to prepaid and emits purchase_completed, including for COD orders. This makes abandoned payments look like completed prepaid purchases. Separate order-created, COD-order-placed, advance-paid, and full-payment-confirmed events; deduplicate by order/payment identity. Validate checkout and order-detail retry paths together.

### P2 — Health concern recovery action can fail on direct entry
In `lib/features/health/screens/disease_detail_screen.dart`, the missing-concern state labels its action “Browse Health Concerns” but calls context.pop(). A direct link with no back stack cannot reliably open the library. Navigate explicitly to /diseases. Test invalid/removed concern deep links as well as normal in-app entry.

## Screen-by-screen UX assessment

| Stage | What works | Recommended refinement |
|---|---|---|
| Home | Animal/category entry points, search, cart access, separate care entry | Preserve rails. Keep animal, pack and cart context consistent when moving between rails and catalogue. Verify floating cart and care button clearance at small sizes. |
| Product list | Filter updates respond to route changes; result controls and variant selection exist | Keep selected filters/count and Clear all discoverable when scrolling. Verify return from detail retains scroll position and filters. Stock labels must describe the selected pack. |
| Product details | Suitability/description now precede bundles; sticky purchase bar and Rx/delivery information | Resolve stale pincode state. Put pack/strength and minimum quantity beside the purchase action. Keep warnings visible before related products. |
| Cart | Delivery and total precede add-on rails | Resolve coin/coupon drift and variant stock. Show blocking stock/Rx messages next to affected items, group optional savings controls, and provide Undo for removal. |
| Checkout | Delivery verification gates payment; blocking reasons and saved-order recovery exist | Share one verified quote and readiness decision across display/submission. Replace generic “Review and continue” with specific actions. An unavailable address should offer saved alternatives, not only new-address creation. |
| Order details | Tracking, bill, support and online payment retry are present | Add partial-COD recovery. Clearly separate order created, advance paid, full payment paid and fulfilment status. Prioritize the next required action above tracking. |
| Health concern list/detail | Concern discovery, species filters and shared product cards | Use “Products for this concern” instead of “remedies”; retain educational and urgent-care guidance before product promotion. Preserve selected species into product discovery. Fix missing-concern navigation. This is an interface review, not clinical advice validation. |

## Acceptance journeys

1. Home → animal/category → select a pack → add → cart → address → each payment mode → correct order status.
2. Health concern → species filter → Rx product → approval pending/approved → checkout; invalid concern deep link → library.
3. Apply coupon and maximum coins → change/remove items → all displayed and submitted totals agree.
4. Change pack stock/quantity or bundle availability → actionable item error before payment.
5. Submit pincode A then B; complete requests in reverse order → only B persists.
6. Create order → session creation fails, gateway fails, UPI app unavailable, payment cancelled, verification delayed → recover the same order without duplicate creation.
7. Partial COD paid advance → order shows remaining delivery balance and does not ask for another advance.
8. 320–412dp screens, 2× text, keyboard open, TalkBack/VoiceOver, slow/offline network.

The passing suite is a regression baseline; it does not prove the above failure paths are covered. Prioritize partial-COD recovery and consistent discount state, then stock readiness, delivery/gateway recovery, and analytics accuracy before further cosmetic work.
