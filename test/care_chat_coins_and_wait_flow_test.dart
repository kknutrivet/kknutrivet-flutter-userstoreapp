import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/features/consultations/screens/book_consultation_screen.dart';
import 'package:nvit_app/features/consultations/screens/consultation_detail_screen.dart';
import 'package:nvit_app/features/consultations/widgets/care_chat_thread_widgets.dart';
import 'package:nvit_app/features/health/screens/disease_detail_screen.dart';
import 'package:nvit_app/models/consultation.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/consultation_service.dart';

import 'support/app_harness.dart';
import 'support/fake_api_client.dart';
import 'support/fixtures.dart';

Map<String, dynamic> _coinStatusJson({
  bool enabled = true,
  bool exempt = false,
  String? exemptReason,
  bool intakeFree = false,
  bool waitingForDoctor = false,
  bool waitingLockActive = false,
  int waitingMessagesLimit = 3,
  int waitingMessagesUsed = 0,
  int waitingMessagesRemaining = 3,
  bool isFollowUp = false,
  String phase = 'POST_ACCEPT_FREE',
  int freeMessagesTotal = 3,
  int freeMessagesUsed = 0,
  int freeMessagesRemaining = 3,
  int coinsPerMessage = 5,
  int userCoinsBalance = 20,
  bool requiresCoinsNow = false,
  bool canAffordNextMessage = true,
}) => {
  'enabled': enabled,
  'exempt': exempt,
  'exemptReason': exemptReason,
  'intakeFree': intakeFree,
  'waitingForDoctor': waitingForDoctor,
  'waitingLockActive': waitingLockActive,
  'waitingMessagesLimit': waitingMessagesLimit,
  'waitingMessagesUsed': waitingMessagesUsed,
  'waitingMessagesRemaining': waitingMessagesRemaining,
  'isFollowUp': isFollowUp,
  'phase': phase,
  'freeMessagesTotal': freeMessagesTotal,
  'freeMessagesUsed': freeMessagesUsed,
  'freeMessagesRemaining': freeMessagesRemaining,
  'coinsPerMessage': coinsPerMessage,
  'userCoinsBalance': userCoinsBalance,
  'requiresCoinsNow': requiresCoinsNow,
  'canAffordNextMessage': canAffordNextMessage,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(loadAppFonts);

  group('Care Chat Coins, Waiting Lock & No-Vet Delay Models/Contracts', () {
    test('CareChatPage.fromJson parses coinStatus, followUpUntil and flags', () {
      final page = CareChatPage.fromJson({
        'messages': const [],
        'canMessage': true,
        'hasMore': false,
        'careChatCoinsEnabled': true,
        'prescriptionUnlocked': true,
        'intakeState': 'AWAITING_DOCTOR',
        'hasAppointment': false,
        'doctorName': 'Dr. Priya Nair',
        'followUpUntil': '2026-11-18T12:00:00.000Z',
        'coinStatus': _coinStatusJson(
          waitingForDoctor: true,
          waitingLockActive: true,
          waitingMessagesUsed: 3,
          waitingMessagesRemaining: 0,
          phase: 'WAITING_LOCKED',
          userCoinsBalance: 15,
        ),
      });

      expect(page.careChatCoinsEnabled, isTrue);
      expect(page.prescriptionUnlocked, isTrue);
      expect(page.intakeState, 'AWAITING_DOCTOR');
      expect(page.hasAppointment, isFalse);
      expect(page.doctorName, 'Dr. Priya Nair');
      expect(page.followUpUntil?.toUtc().year, 2026);
      expect(page.coinStatus, isNotNull);
      expect(page.coinStatus!.waitingLockActive, isTrue);
      expect(page.coinStatus!.waitingMessagesUsed, 3);
      expect(page.coinStatus!.userCoinsBalance, 15);
      expect(page.coinStatus!.effectivePacks, hasLength(3));
    });

    test('CareChatMessage normalizes legacy connecting wait reassurance text', () {
      final legacy = CareChatMessage.fromJson({
        'id': 'm-wait',
        'senderRole': 'SYSTEM',
        'body': kCareChatDoctorConnectingReassuranceText,
        'createdAt': '2026-11-16T00:00:00.000Z',
      });

      expect(legacy.isSystem, isTrue);
      expect(legacy.isNoVetWaitNotice, isTrue);
      expect(legacy.body, kCareChatNoVetAvailableText);
    });

    test('ConsultationService forwards COIN_RECHARGE createPayment & verifyBooking contracts', () async {
      final api = FakeApiClient(
        routes: {
          'POST /consultations/payment': {
            'orderId': 'CARE-COIN-123',
            'paymentSessionId': 'sess_123',
            'mode': 'sandbox',
          },
          'GET /consultations/verify': {
            'paid': true,
            'purpose': 'COIN_RECHARGE',
            'coinsCredited': 110,
            'newBalance': 115,
          },
          'POST /consultations/b1/messages': {
            'message': {
              'id': 'm-1',
              'senderRole': 'CUSTOMER',
              'body': 'Hi doctor',
              'createdAt': '2026-11-16T00:00:00.000Z',
            },
            'coinStatus': _coinStatusJson(
              phase: 'POST_ACCEPT_PAID',
              freeMessagesRemaining: 0,
              requiresCoinsNow: true,
              userCoinsBalance: 95,
            ),
          },
        },
      );
      final service = ConsultationService(api);

      final sendResult = await service.sendChatMessageResult(
        'b1',
        body: 'Hi doctor',
      );
      expect(sendResult.message.id, 'm-1');
      expect(sendResult.coinStatus?.userCoinsBalance, 95);

      await service.createPayment('b1', coinPackAmount: 99);
      final paymentCall = api.callsTo('/consultations/payment').single;
      expect(paymentCall.data, {
        'bookingId': 'b1',
        'purpose': 'COIN_RECHARGE',
        'coinPackAmount': 99,
      });

      await service.verifyBooking(
        'b1',
        orderId: 'CARE-COIN-123',
        coinRecharge: true,
      );
      final verifyCall = api.callsTo('/consultations/verify').single;
      expect(verifyCall.query, {
        'booking_id': 'b1',
        'order_id': 'CARE-COIN-123',
        'coin_recharge': '1',
      });
    });
  });

  group('Care Chat Coins, Free Rx, Follow-up & Parked Slot UI', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      FakeApiClient api, {
      String bookingId = 'booking-1',
    }) async {
      tester.view.physicalSize = const Size(430 * 3, 932 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(home: ConsultationDetailScreen(id: bookingId)),
        ),
      );
      await settle(tester, frames: 8);
    }

    Future<void> disposeTree(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('waitingLockActive shows emerald pause card, locks composer, and toggles recharge packs', (tester) async {
      final api = FakeApiClient(
        routes: {
          'GET /consultations': [consultationJson(id: 'booking-1')],
          'GET /consultations/booking-1/messages': {
            'canMessage': true,
            'careChatCoinsEnabled': true,
            'messages': [
              {
                'id': 'm-wait',
                'senderRole': 'SYSTEM',
                'body': kCareChatDoctorConnectingReassuranceText,
                'createdAt': '2026-11-16T00:00:00.000Z',
              },
            ],
            'coinStatus': _coinStatusJson(
              waitingForDoctor: true,
              waitingLockActive: true,
              waitingMessagesLimit: 3,
              waitingMessagesUsed: 3,
              waitingMessagesRemaining: 0,
              phase: 'WAITING_LOCKED',
              coinsPerMessage: 5,
              userCoinsBalance: 10,
            ),
          },
        },
      );

      await pumpDetail(tester, api);

      expect(find.text(kCareChatNoVetAvailableText), findsOneWidget);
      expect(
        find.text('Waiting for a doctor to accept your consultation'),
        findsOneWidget,
      );
      expect(find.textContaining('3/3 initial messages'), findsOneWidget);
      expect(find.text('Balance: 10'), findsOneWidget);
      expect(
        find.textContaining('up to 5 text messages'),
        findsNothing,
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);

      await tester.tap(find.text('+ Recharge'));
      await settle(tester, frames: 4);
      expect(find.text('₹49'), findsOneWidget);
      expect(find.text('₹99'), findsOneWidget);
      expect(find.text('₹199'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('402 INSUFFICIENT_KK_COINS preserves draft and reveals recharge packs', (tester) async {
      final booking = consultationJson(id: 'booking-1');
      booking['careChatDoctorName'] = 'Dr. Anand';
      final api = FakeApiClient(
        routes: {
          'GET /consultations': [booking],
          'GET /consultations/booking-1/messages': {
            'canMessage': true,
            'careChatCoinsEnabled': true,
            'messages': [
              {
                'id': 'm-vet',
                'senderRole': 'VET',
                'senderName': 'Dr. Anand',
                'body': 'Please share an update.',
                'createdAt': '2026-11-16T00:01:00.000Z',
              },
            ],
            'coinStatus': _coinStatusJson(
              phase: 'POST_ACCEPT_FREE',
              freeMessagesRemaining: 1,
              coinsPerMessage: 5,
              userCoinsBalance: 2,
            ),
          },
        },
      );
      api.failOn(
        'POST /consultations/booking-1/messages',
        ApiException(
          'You are out of KK Coins. Please recharge to continue.',
          statusCode: 402,
          code: 'INSUFFICIENT_KK_COINS',
          meta: {
            'coinStatus': _coinStatusJson(
              phase: 'POST_ACCEPT_PAID',
              freeMessagesRemaining: 0,
              coinsPerMessage: 5,
              userCoinsBalance: 2,
              requiresCoinsNow: true,
              canAffordNextMessage: false,
            ),
          },
        ),
      );

      await pumpDetail(tester, api);

      await tester.enterText(find.byType(TextField), 'Still scratching ears');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await settle(tester, frames: 6);

      expect(
        find.text('Out of KK Coins · Need 5 coins (Balance: 2)'),
        findsOneWidget,
      );
      expect(find.text('₹99'), findsOneWidget);
      expect(find.text('110 Coins'), findsOneWidget);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'Still scratching ears');

      await disposeTree(tester);
    });

    testWidgets('409 WAITING_FOR_DOCTOR locks composer immediately and preserves draft', (tester) async {
      final api = FakeApiClient(
        routes: {
          'GET /consultations': [consultationJson(id: 'booking-wait-409')],
          'GET /consultations/booking-wait-409/messages': {
            'canMessage': true,
            'careChatCoinsEnabled': true,
            'messages': const [],
            'coinStatus': _coinStatusJson(
              waitingForDoctor: true,
              waitingLockActive: false,
              waitingMessagesLimit: 3,
              waitingMessagesUsed: 2,
              waitingMessagesRemaining: 1,
              phase: 'PRE_ACCEPT_FREE',
              coinsPerMessage: 5,
              userCoinsBalance: 10,
            ),
          },
        },
      );
      api.failOn(
        'POST /consultations/booking-wait-409/messages',
        ApiException(
          'Waiting for a doctor to accept your consultation.',
          statusCode: 409,
          code: 'WAITING_FOR_DOCTOR',
          meta: {
            'coinStatus': _coinStatusJson(
              waitingForDoctor: true,
              waitingLockActive: true,
              waitingMessagesLimit: 3,
              waitingMessagesUsed: 3,
              waitingMessagesRemaining: 0,
              phase: 'WAITING_LOCKED',
              coinsPerMessage: 5,
              userCoinsBalance: 10,
            ),
          },
        ),
      );

      await pumpDetail(tester, api, bookingId: 'booking-wait-409');

      await tester.enterText(find.byType(TextField), 'One last photo detail');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await settle(tester, frames: 6);

      expect(
        find.text('Waiting for a doctor to accept your consultation'),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      expect(field.controller?.text, 'One last photo detail');

      await disposeTree(tester);
    });

    testWidgets('Model A unlocks prescriptions free, shows video-only copy, and renders completed 48h follow-up composer', (tester) async {
      final booking = consultationJson(id: 'booking-completed');
      booking['status'] = 'COMPLETED';
      booking['careChatDoctorName'] = 'Dr. Meera';
      booking['prescriptionLocked'] = true;
      booking['unlockAmount'] = 149;

      final api = FakeApiClient(
        routes: {
          'GET /consultations': [booking],
          'GET /consultations/booking-completed/messages': {
            'canMessage': true,
            'bookingStatus': 'COMPLETED',
            'careChatCoinsEnabled': true,
            'prescriptionUnlocked': true,
            'videoCallEligible': true,
            'videoCallAvailable': false,
            'videoAmount': 299,
            'followUpUntil': '2026-11-18T12:00:00.000Z',
            'messages': [
              {
                'id': 'm-rx',
                'senderRole': 'VET',
                'senderName': 'Dr. Meera',
                'messageType': 'PRESCRIPTION',
                'body': 'Administer twice daily.',
                'mediaUrl': 'https://test.kknutrivet.in/rx/1.pdf',
                'prescriptionUnlocked': false,
                'unlockAmount': 149,
                'createdAt': '2026-11-16T00:05:00.000Z',
              },
            ],
            'coinStatus': _coinStatusJson(
              isFollowUp: true,
              phase: 'FOLLOW_UP_FREE',
              freeMessagesTotal: 2,
              freeMessagesUsed: 0,
              freeMessagesRemaining: 2,
              userCoinsBalance: 25,
            ),
          },
        },
      );

      await pumpDetail(tester, api, bookingId: 'booking-completed');

      expect(find.text('View / Download Prescription'), findsOneWidget);
      expect(find.textContaining('Unlock Prescription'), findsNothing);
      expect(find.text('Pay ₹299 to unlock 1-on-1 video call'), findsOneWidget);
      expect(find.textContaining('First 2 follow-up messages free'), findsOneWidget);
      expect(
        find.text('Follow-up · 2 free msgs left (then 5 coins/msg)'),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byType(CareChatComposer),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration?.hintText, 'Ask a follow-up about this concern');

      await disposeTree(tester);
    });

    testWidgets('Scheduled booking route parks general booking into Care Chat CTA', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BookConsultationScreen()),
        ),
      );
      await tester.pump();
      expect(
        find.text('All consultations start on Care Chat'),
        findsOneWidget,
      );
      expect(find.text('Start Vet Care Chat'), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('DiseaseDetailScreen points to Care Chat instead of legacy slot booking', (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            concernByNameProvider('tick-flea-infestations').overrideWith(
              (ref) => Future.value(
                HealthConcern(
                  id: 'hc-1',
                  name: 'Ticks & Fleas',
                  slug: 'tick-flea-infestations',
                  description: 'Tick care.',
                ),
              ),
            ),
            diseaseProductsProvider('Ticks & Fleas').overrideWith(
              (ref) => Future.value(const <Product>[]),
            ),
          ],
          child: const MaterialApp(
            home: DiseaseDetailScreen(slug: 'tick-flea-infestations'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Chat with a veterinarian'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Chat with a veterinarian'), findsOneWidget);
      expect(find.text('Book a vet consultation'), findsNothing);
      await disposeTree(tester);
    });
  });
}
