class VetSlot {
  VetSlot({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.vet,
  });

  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final VetSummary vet;

  factory VetSlot.fromJson(Map<String, dynamic> json) => VetSlot(
    id: json['id'].toString(),
    startAt: DateTime.tryParse(json['startAt']?.toString() ?? '') ?? DateTime.now(),
    endAt: DateTime.tryParse(json['endAt']?.toString() ?? '') ?? DateTime.now(),
    vet: json['vet'] is Map<String, dynamic>
        ? VetSummary.fromJson(json['vet'] as Map<String, dynamic>)
        : VetSummary(id: '', name: 'Vet'),
  );
}

class VetSummary {
  VetSummary({
    required this.id,
    required this.name,
    this.qualifications,
    this.languages = const [],
    this.fee,
    this.ratingAverage,
    this.ratingCount,
  });

  final String id;
  final String name;
  final String? qualifications;
  final List<String> languages;
  final double? fee;
  final double? ratingAverage;
  final int? ratingCount;

  factory VetSummary.fromJson(Map<String, dynamic> json) => VetSummary(
    id: json['id']?.toString() ?? '',
    name:
        json['name']?.toString() ??
        (json['user'] is Map ? json['user']['name']?.toString() : null) ??
        'Vet',
    qualifications: json['qualifications']?.toString(),
    languages:
        (json['languages'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    fee: (json['fee'] as num?)?.toDouble(),
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble(),
    ratingCount: (json['ratingCount'] as num?)?.toInt(),
  );
}

class CareChatPage {
  const CareChatPage({
    required this.messages,
    this.canMessage = false,
    this.hasMore = false,
    this.followUpRequested = false,
    this.videoAvailable = false,
    this.videoEligible = false,
    this.bookingStatus,
    this.videoAmount,
    this.careChatAssignedAt,
  });
  final List<CareChatMessage> messages;
  final bool canMessage, hasMore, followUpRequested, videoAvailable, videoEligible;
  final String? bookingStatus;
  final double? videoAmount;
  final DateTime? careChatAssignedAt;

  factory CareChatPage.fromJson(Map<String, dynamic> json) => CareChatPage(
    messages: (json['messages'] as List? ?? [])
        .whereType<Map>()
        .map((m) => CareChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
    canMessage: json['canMessage'] == true,
    hasMore: json['hasMore'] == true,
    followUpRequested: json['followUpRequested'] == true,
    videoAvailable: json['videoCallAvailable'] == true,
    videoEligible: json['videoCallEligible'] == true,
    bookingStatus: json['bookingStatus']?.toString(),
    videoAmount: (json['videoAmount'] as num?)?.toDouble(),
    careChatAssignedAt: json['careChatAssignedAt'] != null
        ? DateTime.tryParse(json['careChatAssignedAt'].toString())
        : null,
  );
}

class ChatReaction {
  const ChatReaction({
    required this.emoji,
    required this.count,
    required this.mine,
  });

  final String emoji;
  final int count;
  final bool mine;

  factory ChatReaction.fromJson(Map<String, dynamic> json) => ChatReaction(
        emoji: json['emoji']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        mine: json['mine'] == true,
      );

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'count': count,
        'mine': mine,
      };
}

class CareChatMessage {
  CareChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.messageType,
    required this.body,
    this.mediaUrl,
    this.prescriptionUnlocked,
    this.unlockAmount,
    this.reactions = const [],
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  /// One of: `TEXT`, `IMAGE`, `VIDEO`, `PRESCRIPTION`, `CALL_REQUEST`
  final String messageType;
  final String body;
  final String? mediaUrl;
  final bool? prescriptionUnlocked;
  final double? unlockAmount;
  final List<ChatReaction> reactions;
  final DateTime createdAt;

  CareChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderRole,
    String? senderName,
    String? messageType,
    String? body,
    String? mediaUrl,
    bool? prescriptionUnlocked,
    double? unlockAmount,
    List<ChatReaction>? reactions,
    DateTime? createdAt,
  }) {
    return CareChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      messageType: messageType ?? this.messageType,
      body: body ?? this.body,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      prescriptionUnlocked: prescriptionUnlocked ?? this.prescriptionUnlocked,
      unlockAmount: unlockAmount ?? this.unlockAmount,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isSystem {
    final role = senderRole.toUpperCase();
    if (role == 'SYSTEM') return true;
    final type = messageType.toUpperCase();
    if (type == 'CALL_REQUEST' || type == 'VIDEO_REQUEST') return true;
    final text = body.trim();
    if (text.isEmpty) return false;
    return text.contains('has been assigned to your care chat') ||
        text.contains('recommends a video consultation') ||
        text.contains('Video call requested') ||
        text.contains('Payment successful! Your video consultation is now unlocked') ||
        text.contains('looking for a doctor') ||
        text.contains('awaiting care-team review') ||
        text.contains('awaiting admin review');
  }

  bool get isCustomer => !isSystem && senderRole.toUpperCase() == 'CUSTOMER';

  factory CareChatMessage.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['senderRole'] ?? '').toString().toUpperCase();
    final rawType = (json['messageType'] ?? json['type'] ?? 'TEXT').toString().toUpperCase();
    final rawBody = (json['body'] ?? json['text'] ?? '').toString();

    final isSystemMessage = rawRole == 'SYSTEM' ||
        rawType == 'CALL_REQUEST' ||
        rawType == 'VIDEO_REQUEST' ||
        rawBody.contains('has been assigned to your care chat') ||
        rawBody.contains('recommends a video consultation') ||
        rawBody.contains('Video call requested') ||
        rawBody.contains('Payment successful! Your video consultation is now unlocked') ||
        rawBody.contains('looking for a doctor') ||
        rawBody.contains('awaiting care-team review') ||
        rawBody.contains('awaiting admin review');

    final effectiveRole = isSystemMessage
        ? 'SYSTEM'
        : (rawRole.isEmpty ? 'CUSTOMER' : rawRole);

    final defaultName = switch (effectiveRole) {
      'VET' => 'Veterinarian',
      'ADMIN' => 'KK Nutrivet Care Team',
      'AI' || 'AI_SUMMARY' => 'Dr. Paw AI Intake',
      'SYSTEM' => 'System',
      _ => 'You',
    };
    return CareChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: effectiveRole,
      senderName:
          json['senderName']?.toString() ??
          (json['sender'] is Map ? json['sender']['name']?.toString() : null) ??
          defaultName,
      messageType: rawType,
      body: rawBody,
      prescriptionUnlocked: json['prescriptionUnlocked'] as bool?,
      unlockAmount: (json['unlockAmount'] as num?)?.toDouble(),
      mediaUrl:
          (json['mediaUrl'] ?? json['prescriptionUrl'])?.toString(),
      reactions: (json['reactions'] as List? ?? [])
          .whereType<Map>()
          .map((r) => ChatReaction.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ConsultationPrescriptionItem {
  ConsultationPrescriptionItem({
    required this.id,
    required this.medicineName,
    required this.dosage,
    this.frequency = '',
    this.duration = '',
    this.instructions,
    this.productId,
    this.productSlug,
  });

  final String id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final String? productId;
  final String? productSlug;

  factory ConsultationPrescriptionItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : null;
    return ConsultationPrescriptionItem(
      id: json['id']?.toString() ?? '',
      medicineName:
          (json['medicineName'] ?? json['name'] ?? product?['name'] ?? 'Medicine')
              .toString(),
      dosage: (json['dosage'] ?? '').toString(),
      frequency: (json['frequency'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      instructions: json['instructions']?.toString(),
      productId: (json['productId'] ?? product?['id'])?.toString(),
      productSlug: (json['productSlug'] ?? product?['slug'])?.toString(),
    );
  }
}

class ConsultationPrescription {
  ConsultationPrescription({
    required this.id,
    this.diagnosis,
    this.instructions,
    this.followUpAt,
    this.pdfUrl,
    this.items = const [],
  });

  final String id;
  final String? diagnosis;
  final String? instructions;
  final DateTime? followUpAt;
  final String? pdfUrl;
  final List<ConsultationPrescriptionItem> items;

  factory ConsultationPrescription.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['medicines'];
    final parsedItems = <ConsultationPrescriptionItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(ConsultationPrescriptionItem.fromJson(item));
        } else if (item is Map) {
          parsedItems.add(
            ConsultationPrescriptionItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }
    return ConsultationPrescription(
      id: json['id']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString(),
      instructions: (json['instructions'] ?? json['notes'])?.toString(),
      followUpAt: json['followUpAt'] != null
          ? DateTime.tryParse(json['followUpAt'].toString())
          : null,
      pdfUrl: (json['pdfUrl'] ?? json['prescriptionUrl'] ?? json['url'])
          ?.toString(),
      items: parsedItems,
    );
  }
}

class ConsultationBooking {
  ConsultationBooking({
    required this.id,
    String? bookingRef,
    this.petProfileId,
    this.petName,
    required this.animalType,
    this.language,
    this.concern,
    this.notes,
    required this.status,
    this.holdExpiresAt,
    this.amount,
    this.paymentStatus,
    this.isFreeFollowUp = false,
    this.freeFollowUpOfId,
    this.freeFollowUpUntil,
    this.hmsRoomId,
    this.meetingUrl,
    this.slot,
    this.vet,
    this.prescription,
    this.prescriptionLocked = false,
    this.unlockAmount,
    this.reviewRating,
    this.reviewComment,
    this.isCareChat = false,
    this.careChatAssignedAt,
    required this.createdAt,
  }) : bookingRef =
           bookingRef ??
           (id.length > 6
               ? id.substring(id.length - 6).toUpperCase()
               : id.toUpperCase());

  final String id;
  final String bookingRef;
  final String? petProfileId;
  final String? petName;
  final String animalType;
  final String? language;
  final String? concern;
  final String? notes;
  final String status;
  final DateTime? holdExpiresAt;
  final double? amount;
  final String? paymentStatus;
  final bool isFreeFollowUp;
  final String? freeFollowUpOfId;
  final DateTime? freeFollowUpUntil;
  final String? hmsRoomId;
  final String? meetingUrl;
  final VetSlot? slot;
  final VetSummary? vet;
  final ConsultationPrescription? prescription;
  final bool prescriptionLocked;
  final double? unlockAmount;
  final int? reviewRating;
  final String? reviewComment;
  final bool isCareChat;
  final DateTime? careChatAssignedAt;
  final DateTime createdAt;

  bool get isDoctorAssigned {
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'WAITING_FOR_VET' ||
        upperStatus == 'HOLD' ||
        upperStatus == 'PAYMENT_PENDING') {
      return false;
    }
    if (careChatAssignedAt != null) {
      return true;
    }
    if (isCareChat) {
      return false;
    }
    return slot != null && vet != null;
  }

  String get doctorDisplayName {
    if (isDoctorAssigned && vet != null && vet!.name.trim().isNotEmpty) {
      final raw = vet!.name.trim();
      return raw.toLowerCase().startsWith('dr') ? raw : 'Dr. $raw';
    }
    return 'KK Nutrivet Care Team';
  }

  factory ConsultationBooking.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final petProfile = json['petProfile'] is Map
        ? Map<String, dynamic>.from(json['petProfile'] as Map)
        : null;
    final rawPrescription = json['prescription'];
    final reviewMap = json['review'] is Map
        ? Map<String, dynamic>.from(json['review'] as Map)
        : null;

    final rawAnimal =
        json['animalType']?.toString() ??
        petProfile?['animalType']?.toString() ??
        '';

    return ConsultationBooking(
      id: id,
      bookingRef:
          json['bookingRef']?.toString() ??
          (id.length > 6
              ? id.substring(id.length - 6).toUpperCase()
              : id.toUpperCase()),
      petProfileId:
          json['petProfileId']?.toString() ?? petProfile?['id']?.toString(),
      petName: petProfile?['name']?.toString(),
      animalType: rawAnimal,
      language: json['language']?.toString(),
      concern: json['concern']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'HOLD',
      holdExpiresAt: json['holdExpiresAt'] != null
          ? DateTime.tryParse(json['holdExpiresAt'].toString())
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      paymentStatus: json['paymentStatus']?.toString(),
      isFreeFollowUp: json['isFreeFollowUp'] == true,
      freeFollowUpOfId: json['freeFollowUpOfId']?.toString(),
      freeFollowUpUntil: json['freeFollowUpUntil'] != null
          ? DateTime.tryParse(json['freeFollowUpUntil'].toString())
          : null,
      hmsRoomId: json['hmsRoomId']?.toString(),
      meetingUrl:
          (json['meetingUrl'] ?? json['roomUrl'] ?? json['joinUrl'])?.toString(),
      slot: json['slot'] is Map
          ? VetSlot.fromJson(Map<String, dynamic>.from(json['slot'] as Map))
          : null,
      vet: json['vet'] is Map
          ? VetSummary.fromJson(Map<String, dynamic>.from(json['vet'] as Map))
          : null,
      prescription: rawPrescription is Map
          ? ConsultationPrescription.fromJson(
              Map<String, dynamic>.from(rawPrescription),
            )
          : null,
      prescriptionLocked:
          json['prescriptionLocked'] == true ||
          json['prescriptionUnlocked'] == false,
      unlockAmount: (json['unlockAmount'] as num?)?.toDouble(),
      reviewRating: (reviewMap?['rating'] as num?)?.toInt(),
      reviewComment:
          (reviewMap?['comment'] ?? reviewMap?['feedback'])?.toString(),
      isCareChat: json['isCareChat'] == true ||
          json['isCareTeamChat'] == true ||
          (json['slot'] == null &&
              (json['paymentStatus'] == 'CHAT_OPEN' || id.startsWith('care_'))),
      careChatAssignedAt: json['careChatAssignedAt'] != null
          ? DateTime.tryParse(json['careChatAssignedAt'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isUpcoming =>
      status == 'CONFIRMED' ||
      status == 'WAITING_FOR_VET' ||
      status == 'IN_PROGRESS';
}
