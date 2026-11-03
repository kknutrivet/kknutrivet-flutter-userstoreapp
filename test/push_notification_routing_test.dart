import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/notifications/push_service.dart';

void main() {
  group('PushService URL routing', () {
    test('routes care chat URL with query parameter ?chat= to consultation detail', () {
      final route = PushService.mapUrlToAppRoute(
        'https://kknutrivet.in/care-chat?chat=care_cmlk1abc',
      );
      expect(route, '/consultations/care_cmlk1abc');
    });

    test('routes care chat URL with path /care-chat/:id to consultation detail', () {
      final route = PushService.mapUrlToAppRoute(
        'https://kknutrivet.in/care-chat/care_cmlk1abc',
      );
      expect(route, '/consultations/care_cmlk1abc');
    });

    test('routes video room URL to consultation detail', () {
      final route = PushService.mapUrlToAppRoute(
        'https://kknutrivet.in/video-room/care_cmlk1abc',
      );
      expect(route, '/consultations/care_cmlk1abc');
    });

    test('routes consultations path with id to consultation detail', () {
      final route = PushService.mapUrlToAppRoute(
        'https://kknutrivet.in/consultations/care_cmlk1abc',
      );
      expect(route, '/consultations/care_cmlk1abc');
    });

    test('routes general care-chat without chat id to consultations list', () {
      final route = PushService.mapUrlToAppRoute(
        'https://kknutrivet.in/care-chat',
      );
      expect(route, '/consultations');
    });

    test('routes orders and confirmation URLs to order detail', () {
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/orders/ord_123'),
        '/order/ord_123',
      );
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/orders/ord_123/confirmation'),
        '/order/ord_123',
      );
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/orders?order_id=ord_123'),
        '/order/ord_123',
      );
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/orders'),
        '/orders',
      );
    });

    test('routes products, cart, profile, and fallbacks', () {
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/products/granboost-syrup'),
        '/product/granboost-syrup',
      );
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/cart'),
        '/cart',
      );
      expect(
        PushService.mapUrlToAppRoute('https://kknutrivet.in/profile'),
        '/profile',
      );
      expect(
        PushService.mapUrlToAppRoute(''),
        isNull,
      );
    });
  });

  group('PushService RemoteMessage data mapping', () {
    test('extracts direct bookingId from message data', () {
      final message = RemoteMessage(
        data: {'bookingId': 'care_cmlk1abc'},
      );
      expect(PushService.mapMessageToAppRoute(message), '/consultations/care_cmlk1abc');
    });

    test('extracts direct orderId from message data', () {
      final message = RemoteMessage(
        data: {'orderId': 'ord_98765'},
      );
      expect(PushService.mapMessageToAppRoute(message), '/order/ord_98765');
    });

    test('extracts direct productId from message data', () {
      final message = RemoteMessage(
        data: {'productId': 'granboost'},
      );
      expect(PushService.mapMessageToAppRoute(message), '/product/granboost');
    });

    test('falls back to notificationUrl if direct IDs are missing', () {
      final message = RemoteMessage(
        data: {'notificationUrl': 'https://kknutrivet.in/care-chat?chat=care_cmlk1abc'},
      );
      expect(PushService.mapMessageToAppRoute(message), '/consultations/care_cmlk1abc');
    });
  });
}
