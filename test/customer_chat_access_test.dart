import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/models/consultation.dart';
import 'package:nvit_app/features/consultations/screens/consultation_detail_screen.dart';
import 'package:nvit_app/features/consultations/widgets/care_chat_thread_widgets.dart';

void main() {
  testWidgets('Read-only completed chat retains history and offers follow-up', (tester) async {
    tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      consultationDetailProvider('case').overrideWith((ref) async => ConsultationBooking(id: 'case', animalType: 'Dog', status: 'COMPLETED', createdAt: DateTime(2026))),
      careChatMessagesProvider('case').overrideWith((ref) async => CareChatPage(canMessage: false, bookingStatus: 'COMPLETED', messages: [
        CareChatMessage(id: 'm', senderId: 'doctor', senderRole: 'VET', senderName: 'Veterinarian', messageType: 'TEXT', body: 'Your previous care advice', createdAt: DateTime(2026)),
      ])),
    ], child: const MaterialApp(home: ConsultationDetailScreen(id: 'case'))));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CareChatComposer), findsNothing);
    expect(find.text('Request a follow-up'), findsOneWidget);
    expect(find.text('Your previous care advice'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
