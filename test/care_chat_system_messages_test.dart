import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/consultations/widgets/care_chat_thread_widgets.dart';
import 'package:nvit_app/models/consultation.dart';

void main() {
  final testBooking = ConsultationBooking(
    id: 'booking_123',
    animalType: 'Dog',
    status: 'IN_PROGRESS',
    isCareChat: true,
    vet: VetSummary(id: 'vet_1', name: 'Dr. Sumitra Panigrahi'),
    careChatAssignedAt: DateTime.now(),
    createdAt: DateTime(2026),
  );

  group('CareChat System Messages Recognition and Rendering', () {
    test('CareChatMessage correctly detects system message patterns', () {
      final doctorAssignedMsg = CareChatMessage.fromJson({
        'id': 'msg_1',
        'senderId': 'system',
        'senderRole': 'SYSTEM',
        'type': 'TEXT',
        'text': 'Dr. Sumitra Panigrahi has been assigned to your care chat.',
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(doctorAssignedMsg.isSystem, isTrue);
      expect(doctorAssignedMsg.isCustomer, isFalse);

      final videoRequestMsg = CareChatMessage.fromJson({
        'id': 'msg_2',
        'senderId': 'doctor_1',
        'senderRole': 'VET',
        'type': 'VIDEO_REQUEST',
        'text':
            'Your doctor recommends a video consultation. Review the video fee and pay to continue. The prescription is included with paid video.',
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(videoRequestMsg.isSystem, isTrue);
      expect(videoRequestMsg.isCustomer, isFalse);

      final lookingForDocMsg = CareChatMessage.fromJson({
        'id': 'msg_3',
        'senderId': 'system',
        'type': 'TEXT',
        'text':
            'Your message is awaiting care-team review. We will assign a doctor if a consultation is needed.',
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(lookingForDocMsg.isSystem, isTrue);
      expect(lookingForDocMsg.isCustomer, isFalse);
    });

    testWidgets('CareChatBubble renders system messages centered with pill styling', (tester) async {
      final systemMessage1 = CareChatMessage(
        id: 'sys_1',
        senderId: 'system',
        senderRole: 'SYSTEM',
        senderName: 'System',
        messageType: 'TEXT',
        body: 'Dr. Sumitra Panigrahi has been assigned to your care chat.',
        createdAt: DateTime.now(),
      );

      final systemMessage2 = CareChatMessage(
        id: 'sys_2',
        senderId: 'system',
        senderRole: 'SYSTEM',
        senderName: 'System',
        messageType: 'VIDEO_REQUEST',
        body:
            'Your doctor recommends a video consultation. Review the video fee and pay to continue. The prescription is included with paid video.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareChatMessagesSection(
                isLoading: false,
                messages: [systemMessage1, systemMessage2],
                booking: testBooking,
                onUnlockPrescription: (_) {},
                onOpenMedia: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Dr. Sumitra Panigrahi has been assigned to your care chat.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your doctor recommends a video consultation. Review the video fee and pay to continue. The prescription is included with paid video.',
        ),
        findsOneWidget,
      );

      // Verify that neither is rendered as a customer bubble (which has sender name or green bg)
      expect(find.text('Veterinarian'), findsNothing);
      expect(find.text('You'), findsNothing);
    });

    testWidgets('CareChatBubble renders reaction pills and opens reaction bottom sheet', (tester) async {
      final normalMessage = CareChatMessage(
        id: 'user_msg_1',
        senderId: 'vet_1',
        senderRole: 'VET',
        senderName: 'Dr. Sumitra',
        messageType: 'TEXT',
        body: 'Hello! How is your dog feeling today?',
        reactions: const [
          ChatReaction(emoji: '👍', count: 2, mine: true),
          ChatReaction(emoji: '❤️', count: 1, mine: false),
        ],
        createdAt: DateTime.now(),
      );

      CareChatMessage? reactedMessage;
      String? reactedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareChatMessagesSection(
                isLoading: false,
                messages: [normalMessage],
                booking: testBooking,
                canReact: true,
                onReact: (msg, emoji) {
                  reactedMessage = msg;
                  reactedEmoji = emoji;
                },
                onUnlockPrescription: (_) {},
                onOpenMedia: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify message text and reactions exist
      expect(find.text('Hello! How is your dog feeling today?'), findsOneWidget);
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap existing reaction '👍'
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();

      expect(reactedMessage?.id, equals('user_msg_1'));
      expect(reactedEmoji, equals('👍'));

      // Tap the add reaction button
      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      await tester.pumpAndSettle();

      // Verify emoji options sheet is shown
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('😊'), findsOneWidget);
      expect(find.text('🙏'), findsOneWidget);

      // Select '🎉'
      await tester.tap(find.text('🎉'));
      await tester.pumpAndSettle();

      expect(reactedEmoji, equals('🎉'));
    });

    testWidgets('InlinePrescriptionBubble renders progress spinner and disables button when busyAction is true', (tester) async {
      final prescriptionMsg = CareChatMessage(
        id: 'rx_msg_1',
        senderId: 'vet_1',
        senderRole: 'VET',
        senderName: 'Dr. Sumitra',
        messageType: 'PRESCRIPTION',
        body: 'Digital prescription ready',
        prescriptionUnlocked: false,
        unlockAmount: 69.0,
        createdAt: DateTime.now(),
      );

      final lockedBooking = ConsultationBooking(
        id: 'booking_123',
        animalType: 'Dog',
        status: 'IN_PROGRESS',
        isCareChat: true,
        prescriptionLocked: true,
        vet: VetSummary(id: 'vet_1', name: 'Dr. Sumitra Panigrahi'),
        careChatAssignedAt: DateTime.now(),
        createdAt: DateTime(2026),
      );

      // 1. Idle state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareChatMessagesSection(
                isLoading: false,
                messages: [prescriptionMsg],
                booking: lockedBooking,
                busyAction: false,
                onUnlockPrescription: (_) {},
                onOpenMedia: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Unlock Prescription (₹69)'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 2. Busy / Opening payment gateway state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareChatMessagesSection(
                isLoading: false,
                messages: [prescriptionMsg],
                booking: lockedBooking,
                busyAction: true,
                busyMessageId: 'rx_msg_1',
                onUnlockPrescription: (_) {},
                onOpenMedia: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Opening payment gateway…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
