import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/cart_item.dart';
import '../../../models/prescription.dart';
import '../screens/prescriptions_screen.dart' show prescriptionsProvider;
import '../widgets/rx_upload_sheet.dart' show showRxUploadSheet;

/// Whether any line item in [items] requires a veterinary prescription.
bool cartNeedsPrescription(List<CartItem> items) =>
    items.any((item) => item.product?.requiresPrescription == true);

/// A prescription that has been uploaded (pending or approved) can be
/// attached to an order. Review happens after submission.
bool prescriptionReadyForCheckout(Prescription prescription) {
  final status = prescription.status.toUpperCase();
  return status == 'APPROVED' || status == 'PENDING';
}

/// Cart-level Rx state shown by the cart banner and per-item pills,
/// mirroring the website's `effectiveRxStatus`.
enum CartRxStatus { none, pending, approved }

/// Latest attached state across the customer's prescriptions: an approved
/// one wins; otherwise any pending upload counts as attached.
CartRxStatus cartRxStatus(List<Prescription> prescriptions) {
  if (prescriptions.any((p) => p.isApproved)) return CartRxStatus.approved;
  if (prescriptions.any(prescriptionReadyForCheckout)) {
    return CartRxStatus.pending;
  }
  return CartRxStatus.none;
}

/// The most recent prescription usable for checkout (approved preferred,
/// then pending) — attached to the order at placement.
Prescription? attachedPrescription(List<Prescription> prescriptions) {
  return prescriptions.where(prescriptionReadyForCheckout).firstOrNull;
}

/// Gate before checkout: any uploaded prescription (pending review or
/// approved) lets checkout proceed — verification completes post-order,
/// exactly like the website. Only carts with no upload at all are sent
/// to the inline upload sheet.
///
/// Returns `true` only when checkout may proceed.
Future<bool> ensurePrescriptionForCheckout(
  BuildContext context,
  WidgetRef ref, {
  required List<CartItem> items,
}) async {
  if (!cartNeedsPrescription(items)) return true;

  final prescriptions = await _loadPrescriptions(ref);
  if (prescriptions.any(prescriptionReadyForCheckout)) return true;
  if (!context.mounted) return false;

  final uploaded = await showRxUploadSheet(
    context,
    ref,
    onUploaded: () => ref.invalidate(prescriptionsProvider),
  );
  if (!uploaded || !context.mounted) return false;
  ref.invalidate(prescriptionsProvider);
  return true;
}

Future<List<Prescription>> _loadPrescriptions(WidgetRef ref) async {
  try {
    return await ref.read(prescriptionsProvider.future);
  } catch (_) {
    return const [];
  }
}
