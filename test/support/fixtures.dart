/// Shared, deterministic API payloads used by the automation suite.
///
/// Keeping fixtures in one place means a model change breaks exactly one
/// file, and journey/route tests can rely on consistent data.
library;

Map<String, dynamic> userJson({
  String id = 'user-1',
  String email = 'pet.parent@example.com',
  String? name = 'Asha Panda',
  String? phone = '9876543210',
  bool isAnonymous = false,
  int loyaltyPoints = 250,
}) =>
    {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': 'CUSTOMER',
      'isAnonymous': isAnonymous,
      'loyaltyPoints': loyaltyPoints,
    };

Map<String, dynamic> productJson({
  String id = 'prod-granliv',
  String name = 'GranLiv Tonic 500ml',
  String slug = 'granliv-tonic-500ml',
  double price = 450,
  double? mrp = 520,
  int stock = 25,
  String category = 'Supplement & Nutrition',
  List<String> animalTypes = const ['Dog', 'Cat'],
  List<Map<String, dynamic>> variants = const [],
  bool requiresPrescription = false,
}) =>
    {
      'id': id,
      'name': name,
      'slug': slug,
      'description':
          'A vet-recommended liver tonic that supports appetite and digestion.',
      'composition': 'Silymarin, Liv.52 extracts, B-complex',
      'price': price,
      'mrp': mrp,
      'image': null,
      'images': const <String>[],
      'category': category,
      'animalTypes': animalTypes,
      'diseases': const <String>[],
      'brand': 'KK Nutrivet',
      'size': '500 ml',
      'requiresPrescription': requiresPrescription,
      'minimumQuantity': 1,
      'stock': stock,
      'variants': variants,
      'quantityDiscounts': const <Map<String, dynamic>>[],
    };

final List<Map<String, dynamic>> testProducts = [
  productJson(),
  productJson(
    id: 'prod-petcalm',
    name: 'PetCalm Calming Spray 100ml',
    slug: 'petcalm-calming-spray-100ml',
    price: 299,
    mrp: 349,
    stock: 4,
    category: 'Spray',
  ),
  productJson(
    id: 'prod-deworm',
    name: 'DewormSure Tablet Strip',
    slug: 'dewormsure-tablet-strip',
    price: 180,
    mrp: 210,
    stock: 0,
    category: 'Deworming',
  ),
];

Map<String, dynamic> comboJson({
  String id = 'combo-liv-deworm',
  String name = 'Liver + Deworming Care Combo',
}) =>
    {
      'id': id,
      'name': name,
      'description': 'Complete liver support and deworming in one bundle.',
      'image': null,
      'originalPrice': 630,
      'comboPrice': 549,
      'isActive': true,
      'items': [
        {'id': 'ci-1', 'productId': 'prod-granliv', 'quantity': 1, 'product': testProducts[0]},
        {'id': 'ci-2', 'productId': 'prod-deworm', 'quantity': 1, 'product': testProducts[2]},
      ],
    };

Map<String, dynamic> categoryJson({
  String id = 'cat-supplement',
  String name = 'Supplement & Nutrition',
  String slug = 'supplement-nutrition',
}) =>
    {
      'id': id,
      'name': name,
      'slug': slug,
      'image': null,
      'active': true,
    };

final List<Map<String, dynamic>> testCategories = [
  categoryJson(),
  categoryJson(id: 'cat-spray', name: 'Spray', slug: 'spray'),
  categoryJson(id: 'cat-deworming', name: 'Deworming', slug: 'deworming'),
];

Map<String, dynamic> settingsJson() => {
      'freeDeliveryThreshold': 500,
      'localFreeDeliveryThreshold': 500,
      'deliveryCharge': 49,
      'courierDeliveryCharge': 49,
      'codEnabled': true,
      'onlinePaymentsEnabled': true,
      'partialCodEnabled': false,
      'codConfirmationEnabled': true,
      'prescriptionDiscountPercent': 5,
      'hiddenCategories': const <String>[],
      'appUpdate': {
        'forceUpdateEnabled': false,
        'minBuildNumber': 1,
        'minAppVersion': '1.0.0',
        'maintenanceMode': false,
      },
    };

Map<String, dynamic> addressJson({
  String id = 'addr-1',
  bool isDefault = true,
}) =>
    {
      'id': id,
      'label': 'Home',
      'fullName': 'Asha Panda',
      'phone': '9876543210',
      'buildingNumber': 'Flat 4B',
      'fullAddress': 'Saheed Nagar, Near SBI',
      'city': 'Bhubaneswar',
      'state': 'Odisha',
      'zipCode': '751007',
      'isDefault': isDefault,
    };

final List<Map<String, dynamic>> testAddresses = [addressJson()];

Map<String, dynamic> petJson({String id = 'pet-1', String name = 'Bruno'}) => {
      'id': id,
      'name': name,
      'animalType': 'Dog',
      'breed': 'Labrador',
      'weightKg': 24.5,
      'sex': 'MALE',
      'reminderEnabled': true,
    };

final List<Map<String, dynamic>> testPets = [petJson()];

Map<String, dynamic> orderJson({
  String id = 'order-1',
  String orderNumber = 'KKNV-1001',
  String status = 'DELIVERED',
}) =>
    {
      'id': id,
      'orderNumber': orderNumber,
      'totalAmount': 499,
      'subtotal': 450,
      'deliveryCharge': 49,
      'status': status,
      'recipientName': 'Asha Panda',
      'shippingAddress': 'Flat 4B, Saheed Nagar, Bhubaneswar, Odisha 751007',
      'phone': '9876543210',
      'paymentMethod': 'COD',
      'paymentStatus': 'PENDING',
      'createdAt': '2026-10-01T10:00:00.000Z',
      'items': [
        {
          'id': 'oi-1',
          'quantity': 1,
          'price': 450,
          'product': testProducts[0],
        },
      ],
    };

Map<String, dynamic> referralJson() => {
      'referralCode': 'KKASHA200',
      'rewardsPoints': 250,
      'totalReferrals': 2,
      'totalEarned': 200,
      'referredUsers': const <Map<String, dynamic>>[],
    };

Map<String, dynamic> deliveryJson({String pincode = '751007'}) => {
      'pincode': pincode,
      'serviceable': true,
      'deliveryDays': 2,
      'deliveryDaysMax': 3,
      'cod': true,
      'prepaid': true,
      'city': 'Bhubaneswar',
      'source': 'local',
      'message': 'Delivery available',
    };

Map<String, dynamic> healthConcernJson({
  String id = 'hc-1',
  String name = 'Skin & Coat',
  String slug = 'skin-and-coat',
}) =>
    {
      'id': id,
      'name': name,
      'slug': slug,
      'description': 'Itching, hair fall, rashes and dull coat.',
      'enabled': true,
    };

final List<Map<String, dynamic>> testHealthConcerns = [
  healthConcernJson(),
  healthConcernJson(id: 'hc-2', name: 'Digestion', slug: 'digestion'),
];

Map<String, dynamic> blogPostJson({String slug = 'pet-nutrition-basics'}) => {
      'id': 'blog-1',
      'title': 'Pet Nutrition Basics',
      'slug': slug,
      'excerpt': 'What every pet parent should know about balanced meals.',
      'content': '<p>Balanced meals keep pets active and healthy.</p>',
      'coverImage': null,
      'category': 'Nutrition',
      'publishedAt': '2026-09-20T08:00:00.000Z',
      'author': {'name': 'Dr. Meera'},
    };

Map<String, dynamic> consultationJson({String id = 'booking-1'}) => {
      'id': id,
      'animalType': 'Dog',
      'status': 'WAITING_FOR_VET',
      'concern': 'Not eating since two days',
      'language': 'English',
      'createdAt': '2026-10-02T09:00:00.000Z',
    };

Map<String, dynamic> prescriptionJson({String id = 'rx-1'}) => {
      'id': id,
      'status': 'APPROVED',
      'notes': 'Continue for 7 days',
      'vetName': 'Dr. Meera',
      'createdAt': '2026-10-03T09:00:00.000Z',
    };

Map<String, dynamic> productFacetsJson() => {
      'animalTypeCounts': const {'Dog': 2, 'Cat': 1, 'Cattle': 3},
      'categoryCounts': const {'Supplement & Nutrition': 2, 'Spray': 1},
      'brandCounts': const {'KK Nutrivet': 3},
      'diseaseOptions': const [
        {'name': 'Skin & Coat', 'slug': 'skin-and-coat', 'count': 2},
      ],
    };
