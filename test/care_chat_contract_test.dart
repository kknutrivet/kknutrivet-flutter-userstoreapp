import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/providers/consultation_service.dart';

class ContractApi implements ApiClient {
  dynamic response;
  String? path;
  dynamic payload;
  Map<String, dynamic>? query;
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async { this.path = path; this.query = query; return response; }
  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? query}) async { this.path = path; payload = data; return response; }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  test('Chat response preserves access, follow-up, paging and video state', () async {
    final api = ContractApi()..response = {'messages': [], 'canMessage': false, 'hasMore': true,
      'followUpRequested': true, 'bookingStatus': 'COMPLETED', 'videoCallEligible': true, 'videoCallAvailable': false, 'videoAmount': 299};
    final page = await ConsultationService(api).fetchChatPage('case', before: '2026-01-01T00:00:00Z');
    expect(page.canMessage, false); expect(page.followUpRequested, true); expect(page.hasMore, true);
    expect(page.videoEligible, true); expect(page.videoAvailable, false); expect(page.videoAmount, 299);
    expect(api.query!['before'], '2026-01-01T00:00:00Z');
  });
  test('Malformed conversation fails instead of displaying an empty chat', () async {
    final api = ContractApi()..response = {'unexpected': true};
    await expectLater(ConsultationService(api).fetchChatPage('case'), throwsA(isA<ApiException>()));
  });
  test('Prescription and video payments target distinct server contracts', () async {
    final api = ContractApi()..response = <String, dynamic>{}; final service = ConsultationService(api);
    await service.createPayment('case', prescriptionMessageId: 'rx-message');
    expect(api.payload, {'bookingId': 'case', 'prescriptionMessageId': 'rx-message'});
    await service.createPayment('case', video: true);
    expect(api.payload, {'bookingId': 'case', 'purpose': 'VIDEO'});
    await service.verifyBooking('case', orderId: 'CARE-RX-order', prescriptionMessageId: 'rx-message');
    expect(api.query, {'booking_id': 'case', 'order_id': 'CARE-RX-order', 'prescription_message_id': 'rx-message'});
  });
  test('Follow-up request targets the completed case with the question', () async {
    final api = ContractApi()..response = <String, dynamic>{};
    await ConsultationService(api).requestFollowUp('case', 'Can I continue the same medicine?');
    expect(api.path, '/consultations/case/follow-up');
    expect(api.payload, {'action': 'request', 'reason': 'Can I continue the same medicine?'});
  });
  test('startCareChat targets /consultations/chat endpoint directly', () async {
    final api = ContractApi()
      ..response = {
        'booking': {
          'id': 'booking-123',
          'status': 'WAITING_FOR_VET',
          'animalType': 'Dog',
        },
      };
    final booking = await ConsultationService(api).startCareChat(
      name: 'John Doe',
      phone: '9876543210',
      animalType: 'Dog',
      concern: 'My dog has a cough',
      language: 'English',
      requestId: 'test-req-id',
    );
    expect(api.path, '/consultations/chat');
    expect(booking.id, 'booking-123');
    expect((api.payload as Map)['requestId'], 'test-req-id');
    expect((api.payload as Map)['intake']['language'], 'English');
  });
}
