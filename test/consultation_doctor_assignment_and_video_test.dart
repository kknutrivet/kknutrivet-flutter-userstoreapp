import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/consultations/widgets/consultation_prescription_and_review.dart';
import 'package:nvit_app/models/consultation.dart';

void main() {
  final placeholderVet = VetSummary(id: 'vet-1', name: 'Sumitra Panigrahi');
  final assignedVet = VetSummary(id: 'vet-2', name: 'Alok Mishra');

  testWidgets(
    'ConsultationDetailAppBar shows KK Nutrivet Care Team when doctor is not assigned yet',
    (tester) async {
      final unassignedBooking = ConsultationBooking(
        id: 'care_123',
        animalType: 'Dog',
        status: 'WAITING_FOR_VET',
        isCareChat: true,
        vet: placeholderVet, // DB placeholder
        careChatAssignedAt: null,
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConsultationDetailAppBar(
              booking: unassignedBooking,
              busyAction: false,
              videoAvailable: false,
              onJoinVideoCall: (_) {},
            ),
          ),
        ),
      );

      // Should display "KK Nutrivet Care Team", NOT "Dr. Sumitra Panigrahi"
      expect(find.text('KK Nutrivet Care Team'), findsOneWidget);
      expect(find.textContaining('Sumitra'), findsNothing);
      expect(find.textContaining('Dog · #'), findsOneWidget);
    },
  );

  testWidgets(
    'ConsultationDetailAppBar shows Dr. <Name> once careChatAssignedAt is set',
    (tester) async {
      final assignedBooking = ConsultationBooking(
        id: 'care_123',
        animalType: 'Dog',
        status: 'CONFIRMED',
        isCareChat: true,
        vet: assignedVet,
        careChatAssignedAt: DateTime.now(),
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConsultationDetailAppBar(
              booking: assignedBooking,
              busyAction: false,
              videoAvailable: false,
              onJoinVideoCall: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Dr. Alok Mishra'), findsOneWidget);
      expect(find.text('KK Nutrivet Care Team'), findsNothing);
    },
  );

  testWidgets(
    'Tapping video call icon when video is available calls onJoinVideoCall',
    (tester) async {
      bool joined = false;
      final booking = ConsultationBooking(
        id: 'care_123',
        animalType: 'Dog',
        status: 'IN_PROGRESS',
        isCareChat: true,
        vet: assignedVet,
        careChatAssignedAt: DateTime.now(),
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConsultationDetailAppBar(
              booking: booking,
              busyAction: false,
              videoAvailable: true,
              onJoinVideoCall: (_) => joined = true,
            ),
          ),
        ),
      );

      final videoButton = find.byIcon(Icons.videocam_rounded);
      expect(videoButton, findsOneWidget);
      await tester.tap(videoButton);
      await tester.pump();

      expect(joined, isTrue);
    },
  );

  testWidgets(
    'Tapping video call icon when videoEligible calls onPayVideoCall',
    (tester) async {
      bool payCalled = false;
      final booking = ConsultationBooking(
        id: 'care_123',
        animalType: 'Dog',
        status: 'IN_PROGRESS',
        isCareChat: true,
        vet: assignedVet,
        careChatAssignedAt: DateTime.now(),
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConsultationDetailAppBar(
              booking: booking,
              busyAction: false,
              videoAvailable: false,
              videoEligible: true,
              onPayVideoCall: () => payCalled = true,
              onJoinVideoCall: (_) {},
            ),
          ),
        ),
      );

      final videoButton = find.byIcon(Icons.videocam_outlined);
      expect(videoButton, findsOneWidget);
      await tester.tap(videoButton);
      await tester.pump();

      expect(payCalled, isTrue);
    },
  );

  testWidgets(
    'Tapping video call icon when unassigned does not crash and provides tap feedback',
    (tester) async {
      final unassignedBooking = ConsultationBooking(
        id: 'care_123',
        animalType: 'Dog',
        status: 'WAITING_FOR_VET',
        isCareChat: true,
        vet: placeholderVet,
        careChatAssignedAt: null,
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConsultationDetailAppBar(
              booking: unassignedBooking,
              busyAction: false,
              videoAvailable: false,
              onJoinVideoCall: (_) {},
            ),
          ),
        ),
      );

      final videoButton = find.byIcon(Icons.videocam_outlined);
      expect(videoButton, findsOneWidget);

      // Verify the button is interactive (not null onPressed)
      final iconButton = tester.widget<IconButton>(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Video consultation status',
      ));
      expect(iconButton.onPressed, isNotNull);

      await tester.tap(videoButton);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
