# Page UI/UX audit — 3 November 2026

## Scope and evidence

Current-source review of home/navigation, product discovery/details, cart, checkout, order details, health concerns, pet reminders, address forms, onboarding, splash and forced update. This is not a rendered-device visual sign-off. Spacing, contrast, clipping, keyboard behavior and screen-reader navigation still require device verification. No application code changed for this audit. Homepage rails and their arrangement are preserved as requested.

## Priority findings

| Priority | Page / evidence | User impact | Recommended change |
|---|---|---|---|
| P1 | Checkout — `lib/features/checkout/screens/checkout_screen.dart:346–396` | “Choose another address” opens `/addresses/new`; customers cannot follow the instruction to select an existing address through this action. Displayed blockers and resolution actions also use different precedence: the message checks address first, while the action checks stock first. | Derive the message, button label and action from one blocker state. Offer saved addresses for unserviceable delivery, with Add address as a secondary action. |
| P1 | Health concern — `lib/features/health/screens/disease_detail_screen.dart:1071–1092` | Copy promises chat with a licensed doctor, while the button says “Care team chat.” Customers cannot reliably distinguish support, booked veterinary consultation and AI. | Describe each channel accurately. Use “Care team chat” for support, “Book a vet consultation” for appointments and “Dr. Paw AI” for AI. Do not imply doctor availability through support chat without a verified service guarantee. |
| P2 | Checkout footer — `lib/features/checkout/widgets/checkout_payment_and_review.dart:1403–1440` | Every actionable blocker uses “Review and continue,” obscuring the next step. Partial-COD payment action shows the advance without the remaining balance alongside it. | Use “Choose address,” “Retry delivery check,” “Review cart,” “View prescription status” or “Choose payment method.” Show “Pay ₹X now · ₹Y on delivery” together for partial COD. |
| P2 | Cart — `lib/features/cart/screens/cart_screen.dart:191–210,400–408` | Stock warning appears after the summary and says to remove items or wait, although a quantity reduction may resolve the problem. Permanent coupon-reset instructions add clutter even when no coupon was removed. | Place a specific warning and corrective action beside each affected item. Show coupon invalidation feedback when it happens; remove the always-visible explanatory paragraph. Keep delivery and total ahead of add-ons. |
| P2 | Order details — `lib/features/orders/screens/order_detail_screen.dart:61–74`; `lib/features/orders/widgets/order_tracking_and_status.dart:879` | An unpaid order presents its delivery journey before the payment-recovery action. “Pay advance” omits the amount at the decision point. | For unpaid orders, place payment status and recovery immediately below the header. Include amount due and, for partial COD, balance due on delivery. For paid orders, retain delivery tracking as the primary content. |
| P2 | Home/navigation — `lib/features/home/widgets/home_product_rails.dart:191,211–212`; `lib/features/home/screens/main_shell.dart:273,360`; `lib/features/home/widgets/dr_paw_floating_button.dart:182` | The Shots rail arrow has a 36×36 interactive area. Navigation text is 10.5 and the AI floating label is 8; these are difficult secondary cues to read. | Keep the rails. Increase the arrow hit area to 48×48, navigation labels to approximately 12 and essential explanatory text to 12–14. Check long labels and large text before reducing type to make content fit. |
| P2 | Address and pet forms — `lib/features/addresses/screens/address_form_screen.dart:547`; `lib/features/pets/screens/pet_form_screen.dart:356`; `lib/features/pets/screens/pet_detail_screen.dart:539` | Raw exception strings appear in transient toasts. These can expose technical wording and disappear before the user understands how to recover. | Map known failures to plain-language messages. Keep submission failures beside the form action, preserve entered values and offer retry. Reserve toasts for brief confirmations. |
| P2 | Pet reminders — `lib/features/pets/screens/pet_detail_screen.dart:238–243` | “Reminders enabled” reflects the pet preference alone. It does not establish that this device can receive notifications. | Distinguish the saved reminder preference from device notification permission. Offer notification settings when blocked; only show schedule/delivery confirmation when backed by actual data. Verify whether reminders also use other channels before choosing final wording. |
| P2 | Tutorial — `lib/features/onboarding/screens/onboarding_screen.dart:227` | A fixed 65% progress bar in the prescription illustration resembles a real processing state. | Replace it with a clearly illustrative document or static Photo → Review → Products steps. Keep the illustration separate from real upload or review status. |
| P2 | Splash/shared scene — `lib/core/widgets/mascot_world_scene.dart:49–59` | Floating animation repeats without checking the system reduced-motion preference. | Respect `MediaQuery.disableAnimations` and stop ambient motion when requested. Preserve the single logo, nearby tagline and bottom loader. |
| P2 | Health product terminology — `lib/features/health/screens/disease_detail_screen.dart:106,278,547,627` | Filters and results call commercial products “remedies,” potentially implying suitability for the concern before the user checks the product details. | Use “Products,” “Search products” and “Products for this concern.” Keep suitability, prescription requirements and access to qualified care clear. |
| P3 | Forced update — `lib/features/system/screens/force_update_screen.dart:142–171` | Installed/minimum versions and build numbers receive a dedicated information card during a blocked task. | Lead with why an update is needed and a clear Update app action. Move technical build information into secondary support details; retain a useful action if opening the store fails. |

## Page-by-page direction

- **Homepage:** retain rails and merchandising order. Standardize readable captions, enlarge small controls and verify floating cart/AI controls do not compete or cover rail content on small screens.
- **Product list/cards:** retain the larger product name, price and purchase targets already implemented. Validate two-line names, long pack labels, unavailable variants and prescription badges at large text sizes. Avoid restoring stacked promotional badges.
- **Product details:** suitability and description already precede bundles. Preserve that sequence. Keep pack selection, price, availability and prescription requirements close to the purchase action; secondary content can stay expandable.
- **Cart:** delivery and total already precede add-ons. Prioritize item-level corrections, then simplify optional coupon/coin content. Label unknown delivery charges as estimates until verified.
- **Checkout:** repair blocker/action consistency first. Keep the final amount and payment consequences together. Validate transitions when changing address, prescription status or payment method.
- **Order details:** make the primary action depend on order state: complete payment for unpaid orders, track delivery for paid orders, explain the next step for cancelled orders.
- **Health concerns:** use neutral product terminology and unambiguous care-channel labels. Make guidance discoverable before customers interpret the product list as a diagnosis or treatment plan.
- **Pets and addresses:** use persistent, actionable errors and accurate reminder status. Confirm forms remain usable with the keyboard open and large text enabled.
- **Tutorial:** keep short copy and fixed navigation. Remove simulated processing. Consider one progress treatment instead of both “Step X of 4” and dots; this is a visual simplification recommendation, not a functional defect.
- **Splash:** the duplicate heading is already removed. Preserve the requested logo/tagline/loader hierarchy; verify real-device composition rather than redesigning again from source alone.
- **Maintenance/forced update:** use concise state-specific messages, one primary recovery action and secondary support information. Do not invent a restoration time or imply a refresh succeeded without a real response.

## Device verification before visual sign-off

1. Review a small phone and a typical large phone at default and 200% text scale. Check bottom navigation, sticky purchase/payment controls, dialogs and keyboard-open forms.
2. Check TalkBack/VoiceOver names, focus order, selected tabs, quantity controls and announcement of errors and totals.
3. Exercise no-network, retry, empty results, slow delivery checks, unserviceable addresses, rejected/pending prescriptions, unavailable quantities and interrupted payments.
4. Check partial-COD amount consistency across checkout, confirmation, gateway return and order details.
5. Verify notification-denied and reduced-motion states.

## Implementation order

First fix checkout blocker consistency and care-channel promises. Next improve payment recovery prominence, cart corrections, reminder status and form errors. Then standardize small typography and touch areas, followed by tutorial/update-screen polish and device accessibility verification.
