# Page UX fixes — implementation and verification

Implemented:
1. Checkout recovery opens and scrolls to saved-address selection. Message/action precedence is aligned; recovery labels identify the next step.
2. Health guidance separates care-team support, booked consultations and Dr. Paw AI, with an explicit booking action.
3. Pending-payment recovery appears immediately after the order header, with the amount payable and partial-COD delivery balance when available. Missing advance amounts are not invented. Checkout also shows the delivery balance beside its advance action.
4. Stock issues appear beside the affected item or bundle. Individual items offer reduction to available stock where the minimum quantity permits, or removal. Bundles offer whole-bundle removal to preserve their composition. Variant zero stock no longer falls back to parent stock. Corrections disable while saving and retain an actionable error on failure.
5. Navigation labels and the AI badge are larger; the Shots arrow has a 48px target. Navigation height responds to text scaling.
6. Reminder preference and device notification permission are separate. Permission is refreshed on app resume, with a settings action when blocked and an honest unavailable state on lookup failure. No notification-delivery guarantee is shown.
7. Address/pet errors use customer-safe messages. Save errors persist beside the form action and preserve entered values.
8. Tutorial prescription illustration no longer displays simulated processing progress.

Added regression coverage for customer-safe errors, zero variant stock and checkout recovery at 320px/200% text with a labeled-target accessibility assertion. Updated the existing checkout recovery-label expectation.

Verification updated after device testing:
- Full Flutter suite: 243 tests passed. After the final checkout wrapping change, all 5 targeted checkout tests passed again.
- Flutter analyzer: final analysis reports no issues.
- Physical A015 / Android 16: inspected homepage at default and 200% system font size, plus populated cart and checkout at 200%. Fixed the observed location-row, animal-label, category-grid and checkout-address-action overflows, then inspected the updated screens.
- Automated accessibility: labeled targets and Android touch-target guideline passed for navigation at 320px/200%; checkout recovery passed its large-text/label test.
- Restored the device font scale to its original 1.0. No order was submitted and no cart items were changed.
- This is not an exhaustive accessibility certification: TalkBack spoken output, iOS VoiceOver, contrast measurements across all images, and every order/payment/reminder state still require dedicated verification.

Additional homepage fixes: smaller badge density in video cards, larger secondary text, adaptive rail/card heights, shorter search prompt, 48px cart/action targets, Care tab naming, and reserved cart space to separate it from the AI button. Rails and their order were preserved by this pass.

User-requested adjustment: restored the original floating View cart overlay by removing the reserved bottom strip. Removed the COD availability claim from the checkout delivery summary; payment availability remains controlled by checkout/admin settings.
