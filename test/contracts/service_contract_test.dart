/// Contract tests for every API-backed service.
///
/// These run the real service/model code against [FakeApiClient], so endpoint
/// paths, request bodies and JSON parsing are verified without a network.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/providers/address_service.dart';
import 'package:nvit_app/providers/ai_service.dart';
import 'package:nvit_app/providers/cart_service.dart';
import 'package:nvit_app/providers/catalog_service.dart';
import 'package:nvit_app/providers/consultation_service.dart';
import 'package:nvit_app/providers/content_service.dart';
import 'package:nvit_app/providers/delivery_service.dart';
import 'package:nvit_app/providers/order_service.dart';
import 'package:nvit_app/providers/pet_service.dart';
import 'package:nvit_app/providers/prescription_service.dart';
import 'package:nvit_app/providers/referral_service.dart';
import 'package:nvit_app/providers/settings_service.dart';
import 'package:nvit_app/providers/upload_service.dart';

import '../support/fake_api_client.dart';
import '../support/fixtures.dart';

void main() {
  group('CatalogService', () {
    test('fetchProducts sends filters and parses products', () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      final products = await service.fetchProducts(
        category: 'Spray',
        animalType: 'Dog',
        search: 'calm',
        sort: 'price',
      );

      expect(products, hasLength(3));
      expect(products.first.name, 'GranLiv Tonic 500ml');
      final call = api.calls.single;
      expect(call.path, '/products');
      expect(call.query?['category'], 'Spray');
      expect(call.query?['animalType'], 'Dog');
      expect(call.query?['search'], 'calm');
      expect(call.query?['sort'], 'price');
    });

    test('fetchProduct resolves by id or slug', () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      final product = await service.fetchProduct('prod-petcalm');

      expect(product.id, 'prod-petcalm');
      expect(product.price, 299);
      expect(api.calls.single.path, '/products/prod-petcalm');
    });

    test('fetchSuggestions ignores queries shorter than two characters',
        () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      expect(await service.fetchSuggestions('a'), isEmpty);
      expect(api.calls, isEmpty);

      await service.fetchSuggestions('gr');
      expect(api.calls.single.path, '/search/suggestions');
      expect(api.calls.single.query?['q'], 'gr');
    });

    test('fetchCategories parses active categories', () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      final categories = await service.fetchCategories();

      expect(categories.map((c) => c.name),
          containsAll(['Supplement & Nutrition', 'Spray', 'Deworming']));
    });

    test('fetchCombos and fetchCombo parse bundles', () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      final combos = await service.fetchCombos();
      expect(combos, hasLength(1));
      expect(combos.first.name, 'Liver + Deworming Care Combo');
      expect(combos.first.items, hasLength(2));
      expect(combos.first.savingPercent, greaterThan(0));

      final combo = await service.fetchCombo('combo-liv-deworm');
      expect(combo?.id, 'combo-liv-deworm');
      expect(api.calls.last.query?['id'], 'combo-liv-deworm');
    });

    test('fetchFacets parses counts and disease options', () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      final facets = await service.fetchFacets(animalType: 'Dog');

      expect(facets.animalTypeCounts['Dog'], 2);
      expect(facets.categoryCounts['Spray'], 1);
      expect(facets.diseaseOptions.single.slug, 'skin-and-coat');
    });

    test('fetchHealthConcerns parses the health library', () async {
      final api = FakeApiClient();
      final service = CatalogService(api);

      final concerns = await service.fetchHealthConcerns();

      expect(concerns, hasLength(2));
      expect(concerns.first.slug, 'skin-and-coat');
    });
  });

  group('CartService', () {
    test('fetchCart parses server cart lines', () async {
      final api = FakeApiClient(
        routes: {
          '/cart': [
            {
              'id': 'ci-1',
              'productId': 'prod-granliv',
              'quantity': 2,
              'product': productJson(),
            },
          ],
        },
      );
      final service = CartService(api);

      final items = await service.fetchCart();

      expect(items.single.quantity, 2);
      expect(items.single.lineTotal, 900);
    });

    test('mutations use the documented verbs and payloads', () async {
      final api = FakeApiClient();
      final service = CartService(api);

      await service.addItem(productId: 'prod-granliv', quantity: 2);
      await service.setQuantity(productId: 'prod-granliv', quantity: 3);
      await service.addCombo('combo-1');
      await service.setComboQuantity('combo-1', 0);
      await service.removeItem('ci-1');
      await service.clearCart();

      expect(api.calls[0].method, 'POST');
      expect(api.calls[0].data, {'productId': 'prod-granliv', 'quantity': 2});
      expect(api.calls[1].method, 'PUT');
      expect(api.calls[1].data['quantity'], 3);
      expect(api.calls[2].data['addCombo'], true);
      // combo quantity 0 removes instead of posting a zero quantity.
      expect(api.calls[3].method, 'DELETE');
      expect(api.calls[3].query?['comboId'], 'combo-1');
      expect(api.calls[4].query?['id'], 'ci-1');
      expect(api.calls[5].method, 'DELETE');
    });
  });

  group('OrderService', () {
    test('fetchOrders and fetchOrder parse order history', () async {
      final api = FakeApiClient();
      final service = OrderService(api);

      final orders = await service.fetchOrders();
      expect(orders.single.orderNumber, 'KKNV-1001');
      expect(orders.single.items.single.product?.id, 'prod-granliv');

      final order = await service.fetchOrder('order-1');
      expect(order.id, 'order-1');
      expect(api.calls.last.path, '/orders/order-1');
    });

    test('coupons, tracking and cashfree endpoints', () async {
      final api = FakeApiClient(
        routes: {
          'POST /coupons/validate': {
            'valid': true,
            'discountAmount': 50,
            'code': 'SAVE50',
          },
          'GET /coupons': [
            {'code': 'SAVE50', 'discount': 50, 'description': 'Flat 50 off'},
          ],
          'GET /orders/tracking': {'trackingStatus': 'Delivered'},
          'POST /payments/cashfree/create': {'paymentSessionId': 'sess-1'},
        },
      );
      final service = OrderService(api);

      final coupon = await service.validateCoupon('SAVE50', 500);
      expect(coupon['valid'], isTrue);
      expect(api.calls.last.data, {'code': 'SAVE50', 'subtotal': 500.0});

      final offers = await service.fetchPublicCoupons();
      expect(offers.single.code, 'SAVE50');

      final tracking = await service.fetchTracking('order-1');
      expect(tracking['trackingStatus'], 'Delivered');

      final cashfree = await service.createCashfreeOrder('order-1');
      expect(cashfree['paymentSessionId'], 'sess-1');
    });
  });

  group('Account & content services', () {
    test('address CRUD maps payloads', () async {
      final api = FakeApiClient(routes: {
        'POST /addresses': addressJson(id: 'addr-new'),
        'PUT /addresses': addressJson(id: 'addr-1', isDefault: false),
      });
      final service = AddressService(api);

      final addresses = await service.fetchAddresses();
      expect(addresses.single.city, 'Bhubaneswar');

      final address = addresses.single;
      final created = await service.addAddress(address);
      expect(created.id, 'addr-new');

      await service.updateAddress('addr-1', address);
      expect(api.calls.last.data['id'], 'addr-1');

      await service.deleteAddress('addr-1');
      expect(api.calls.last.query?['id'], 'addr-1');
    });

    test('pet service handles wrapped pet responses', () async {
      final api = FakeApiClient(routes: {
        'GET /pets/pet-1': {'pet': petJson()},
        'POST /pets': {'pet': petJson(id: 'pet-new', name: 'Milo')},
        'PATCH /pets/pet-1': {'pet': petJson()},
        'POST /pets/quick': petJson(id: 'pet-quick', name: 'Coco'),
      });
      final service = PetService(api);

      expect((await service.fetchPets()).single.name, 'Bruno');
      expect((await service.fetchPet('pet-1')).name, 'Bruno');
      expect((await service.createPet({'name': 'Milo'})).id, 'pet-new');
      expect((await service.quickAddPet({'name': 'Coco'})).id, 'pet-quick');
      expect((await service.updateReminders('pet-1', {'reminderEnabled': true})).name,
          'Bruno');

      await service.deletePet('pet-1');
      expect(api.calls.last.path, '/pets/pet-1');
      expect(api.calls.last.method, 'DELETE');
    });

    test('prescription, referral, delivery and settings parse', () async {
      final api = FakeApiClient();
      final prescriptions = await PrescriptionService(api).fetchPrescriptions();
      expect(prescriptions.single.isApproved, isTrue);

      final referral = await ReferralService(api).fetchSummary();
      expect(referral.referralCode, 'KKASHA200');
      expect(referral.rewardsPoints, 250);

      final delivery = await DeliveryService(api).checkPincode('751007');
      expect(delivery.serviceable, isTrue);
      expect(delivery.etaLabel, '2-3 days');

      final settings = await SettingsService(api).fetchSettings();
      expect(settings.freeDeliveryThreshold, 500);
      expect(settings.appUpdate.forceUpdateEnabled, isFalse);
    });

    test('content service parses blog, insights, shots and sections', () async {
      final api = FakeApiClient();
      final service = ContentService(api);

      final posts = await service.fetchBlogPosts();
      expect(posts.single.title, 'Pet Nutrition Basics');

      final post = await service.fetchBlogPost('pet-nutrition-basics');
      expect(post.slug, 'pet-nutrition-basics');

      expect(await service.fetchVetInsights(), isEmpty);
      // /shots is empty, so the service falls back to popular products.
      expect(await service.fetchShots(), hasLength(3));
      expect(await service.fetchHomepageSections(), isEmpty);
    });
  });

  group('Care services', () {
    test('consultations parse list and chat page contracts', () async {
      final api = FakeApiClient(routes: {
        'GET /consultations/booking-1/messages': {
          'messages': [
            {
              'id': 'msg-1',
              'senderRole': 'VET',
              'body': 'Hello, how is Bruno?',
              'createdAt': '2026-10-02T09:05:00.000Z',
            },
          ],
          'canMessage': true,
        },
      });
      final service = ConsultationService(api);

      final bookings = await service.fetchMyConsultations();
      expect(bookings.single.concern, 'Not eating since two days');

      final page = await service.fetchChatPage('booking-1');
      expect(page.canMessage, isTrue);
      expect(page.messages.single.body, 'Hello, how is Bruno?');
    });

    test('Dr Paw unwraps the vet-coach reply contract', () async {
      final api = FakeApiClient(routes: {
        'POST /pet-care/vet-coach': {
          'reply': {
            'headline': 'Offer small meals',
            'summary': 'Encourage eating with warm food.',
            'steps': ['Warm the food', 'Offer 4 small meals'],
            'caution': 'See a vet if it lasts 24h.',
            'followUpChoices': ['What about water?'],
          },
          'matchedProducts': [
            {'id': 'prod-granliv'},
          ],
        },
        'GET /alternatives/search': testProducts,
      });
      final service = AiService(api);

      final answer = await service.ask(question: 'My dog is not eating');
      expect(answer.content, contains('Offer small meals'));
      expect(answer.content, contains('Warm the food'));
      expect(answer.productIds, ['prod-granliv']);
      expect(answer.suggestedQuestions, ['What about water?']);

      final alternatives = await service.findAlternativesByText('liver tonic');
      expect(alternatives, hasLength(3));
    });

    test('upload service returns the public URL and forwards purpose',
        () async {
      final api = FakeApiClient(routes: {
        'UPLOAD /upload-image': {'url': 'https://cdn.example.com/rx.jpg'},
      });
      final service = UploadService(api);

      final url = await service.uploadImage('/tmp/rx.jpg', purpose: 'prescription');

      expect(url, 'https://cdn.example.com/rx.jpg');
      expect(api.calls.single.path, '/upload-image');
      expect(api.calls.single.data, {'purpose': 'prescription'});
      expect(api.calls.single.filePath, '/tmp/rx.jpg');
    });
  });

  group('Error mapping', () {
    test('services propagate ApiException with status codes', () async {
      final api = FakeApiClient();
      api.failOn(
        '/products',
        ApiException('Unauthorized', statusCode: 401),
      );

      expect(
        () => CatalogService(api).fetchProducts(),
        throwsA(isA<ApiException>()),
      );
    });

    test('addresses treat 401 as an empty list', () async {
      final api = FakeApiClient();
      api.failOn('/addresses', ApiException('Unauthorized', statusCode: 401));

      expect(await AddressService(api).fetchAddresses(), isEmpty);
    });
  });
}
