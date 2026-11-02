import '../core/network/api_client.dart';
import '../models/consultation.dart';

class ConsultationService {
  ConsultationService(this._client);
  final ApiClient _client;

  dynamic _payload(dynamic response) {
    if (response is Map && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  Future<Map<String, dynamic>> fetchSlots({
    String date = 'today',
    String? language,
  }) async {
    final response = await _client.get(
      '/consultations/slots',
      query: {'date': date, 'language': ?language},
    );
    final data = _payload(response);
    return Map<String, dynamic>.from(data);
  }

  Future<ConsultationBooking> holdSlot({
    required String slotId,
    String? petProfileId,
    required String animalType,
    required String language,
    String? notes,
    String? followUpOfId,
  }) async {
    final response = await _client.post(
      '/consultations/hold',
      data: {
        'slotId': slotId,
        'petProfileId': ?petProfileId,
        'animalType': animalType,
        'language': language,
        'notes': ?notes,
        'followUpOfId': ?followUpOfId,
      },
    );
    final data = _payload(response);
    return ConsultationBooking.fromJson(data['booking']);
  }

  Future<ConsultationBooking> startCareChat({
    required String name,
    required String phone,
    required String animalType,
    String? otherAnimalName,
    required String concern,
    required String language,
    String? mediaUrl,
    String? mediaType,
    required String requestId,
    String? petProfileId,
  }) async {
    final resolvedAnimal =
        (animalType.toLowerCase() == 'other' &&
            otherAnimalName != null &&
            otherAnimalName.trim().isNotEmpty)
        ? otherAnimalName.trim()
        : animalType;
    final cleanPhone = phone.trim();
    final intakeMap = <String, dynamic>{
      'name': name.trim(),
      if (cleanPhone.isNotEmpty) 'phone': cleanPhone,
      'animalType': resolvedAnimal,
      'concern': concern.trim(),
      'language': language,
    };
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (cleanPhone.isNotEmpty) 'phone': cleanPhone,
      'animalType': resolvedAnimal,
      if (otherAnimalName != null && otherAnimalName.trim().isNotEmpty)
        'otherAnimalName': otherAnimalName.trim(),
      'concern': concern.trim(),
      'message': concern.trim(),
      'language': language,
      if (mediaUrl != null && mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
      if (mediaType != null && mediaType.isNotEmpty) 'mediaType': mediaType,
      'requestId': requestId,
      if (petProfileId != null && petProfileId.isNotEmpty)
        'petProfileId': petProfileId,
      'newThread': true,
      'intake': intakeMap,
    };
    dynamic response;
    try {
      response = await _client.post('/consultations/chat', data: payload);
    } on ApiException catch (e) {
      // If the backend requires OTP verification for an unverified phone number (HTTP 403),
      // retry without the unverified phone so the customer's consultation request goes through.
      if (e.statusCode == 403 && intakeMap.containsKey('phone')) {
        final fallbackPayload = Map<String, dynamic>.from(payload);
        final fallbackIntake = Map<String, dynamic>.from(intakeMap)..remove('phone');
        fallbackPayload.remove('phone');
        fallbackPayload['intake'] = fallbackIntake;
        response = await _client.post('/consultations/chat', data: fallbackPayload);
      } else {
        rethrow;
      }
    }
    final data = _payload(response);
    if (data is Map && data['booking'] is Map) {
      return ConsultationBooking.fromJson(
        Map<String, dynamic>.from(data['booking'] as Map),
      );
    }
    if (data is Map) {
      return ConsultationBooking.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not start Care Chat.');
  }

  Future<CareChatPage> fetchChatPage(String bookingId, {String? before}) async {
    final data = _payload(await _client.get('/consultations/${Uri.encodeComponent(bookingId)}/messages',
      query: {'before': before ?? DateTime.now().toUtc().toIso8601String()}));
    if (data is! Map || data['messages'] is! List) throw ApiException('Could not load this conversation. Please retry.');
    return CareChatPage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<CareChatMessage>> fetchChatMessages(String bookingId) async => (await fetchChatPage(bookingId)).messages;

  Future<void> requestFollowUp(String bookingId, String reason) async {
    await _client.post('/consultations/${Uri.encodeComponent(bookingId)}/follow-up', data: {'action': 'request', 'reason': reason});
  }

  Future<CareChatMessage> sendChatMessage(
    String bookingId, {
    required String body,
    String messageType = 'TEXT',
    String? mediaUrl,
  }) async {
    final response = await _client.post(
      '/consultations/$bookingId/messages',
      data: {
        'body': body,
        'text': body,
        'messageType': messageType,
        'type': messageType,
        'mediaUrl': ?mediaUrl,
      },
    );
    final data = _payload(response);
    if (data is Map && data['message'] is Map) {
      return CareChatMessage.fromJson(
        Map<String, dynamic>.from(data['message'] as Map),
      );
    }
    if (data is Map) {
      return CareChatMessage.fromJson(Map<String, dynamic>.from(data));
    }
    return CareChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderRole: 'CUSTOMER',
      senderName: 'You',
      messageType: messageType,
      body: body,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> createPayment(String bookingId, {String? prescriptionMessageId, bool video = false}) async {
    final response = await _client.post(
      '/consultations/payment',
      data: {'bookingId': bookingId, 'prescriptionMessageId': ?prescriptionMessageId, if (video) 'purpose': 'VIDEO'},
    );
    final data = _payload(response);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> activateFreeFollowUp(String bookingId) async {
    final response = await _client.post(
      '/consultations/$bookingId/activate-free',
    );
    final data = _payload(response);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> verifyBooking(String bookingId, {String? orderId, String? prescriptionMessageId, bool video = false}) async {
    final response = await _client.get(
      '/consultations/verify',
      query: {'booking_id': bookingId, 'order_id': ?orderId, 'prescription_message_id': ?prescriptionMessageId, if (video) 'video': '1'},
    );
    final data = _payload(response);
    return Map<String, dynamic>.from(data);
  }

  Future<List<ConsultationBooking>> fetchMyConsultations() async {
    final response = await _client.get('/consultations');
    final data = _payload(response);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ConsultationBooking.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> joinCall(String bookingId) async {
    final data = await _client.post('/consultations/$bookingId/join');
    return Map<String, dynamic>.from(_payload(data) as Map);
  }

  Future<void> submitReview(
    String bookingId, {
    required int rating,
    String? comment,
    String? feedback,
  }) {
    final resolvedComment = (comment ?? feedback ?? '').trim();
    return _client.post(
      '/consultations/$bookingId/review',
      data: {
        'rating': rating,
        'comment': resolvedComment,
        'feedback': resolvedComment,
      },
    );
  }
}
