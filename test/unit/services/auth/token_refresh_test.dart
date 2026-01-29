import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:field_reporter/features/auth/services/token_refresh_service.dart';

@GenerateMocks([FlutterSecureStorage, TokenRefreshService])
import 'token_refresh_test.mocks.dart';

void main() {
  group('TokenRefreshService', () {
    late MockFlutterSecureStorage mockStorage;
    late TokenRefreshService tokenRefreshService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      tokenRefreshService = TokenRefreshService(storage: mockStorage);
    });

    test('token is valid when expiration is far in the future', () async {
      final futureExpiration = DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch
          .toString();

      when(mockStorage.read(key: 'token_expiration'))
          .thenAnswer((_) async => futureExpiration);

      final needsRefresh = await tokenRefreshService.needsRefresh();

      expect(needsRefresh, isFalse);
    });

    test('token needs refresh when near expiration (within 5 minutes)',
        () async {
      final nearExpiration = DateTime.now()
          .add(const Duration(minutes: 3))
          .millisecondsSinceEpoch
          .toString();

      when(mockStorage.read(key: 'token_expiration'))
          .thenAnswer((_) async => nearExpiration);

      final needsRefresh = await tokenRefreshService.needsRefresh();

      expect(needsRefresh, isTrue);
    });

    test('token needs refresh when expired', () async {
      final pastExpiration = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch
          .toString();

      when(mockStorage.read(key: 'token_expiration'))
          .thenAnswer((_) async => pastExpiration);

      final needsRefresh = await tokenRefreshService.needsRefresh();

      expect(needsRefresh, isTrue);
    });

    test('refreshToken calls API and stores new token', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'old_refresh_token');
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final result = await tokenRefreshService.refreshToken();

      expect(result, isNotNull);
      expect(result!.accessToken, isNotEmpty);
      expect(result.refreshToken, isNotEmpty);

      // Verify new tokens were stored
      verify(mockStorage.write(key: 'auth_token', value: anyNamed('value')))
          .called(1);
      verify(mockStorage.write(key: 'refresh_token', value: anyNamed('value')))
          .called(1);
      verify(mockStorage.write(
              key: 'token_expiration', value: anyNamed('value')))
          .called(1);
    });

    test('refreshToken returns null when no refresh token exists', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => null);

      final result = await tokenRefreshService.refreshToken();

      expect(result, isNull);
    });

    test('refreshToken returns null on API error', () async {
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'invalid_refresh_token');

      final service = TokenRefreshService(
        storage: mockStorage,
        simulateError: true,
      );

      final result = await service.refreshToken();

      expect(result, isNull);
    });
  });

  group('Token refresh integration', () {
    late MockFlutterSecureStorage mockStorage;
    late TokenRefreshService tokenRefreshService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      tokenRefreshService = TokenRefreshService(storage: mockStorage);
    });

    test(
        'performApiActionWithRefresh refreshes token transparently before action',
        () async {
      // Setup: Token near expiration
      final nearExpiration = DateTime.now()
          .add(const Duration(minutes: 2))
          .millisecondsSinceEpoch
          .toString();

      when(mockStorage.read(key: 'token_expiration'))
          .thenAnswer((_) async => nearExpiration);
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'valid_refresh_token');
      when(mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'new_access_token');
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      // Track if API action was called
      var apiActionCalled = false;
      Future<String> apiAction() async {
        apiActionCalled = true;
        return 'api_result';
      }

      // Perform action with automatic refresh
      final result = await tokenRefreshService.performWithRefresh(apiAction);

      // Verify token was refreshed
      verify(mockStorage.write(key: 'auth_token', value: anyNamed('value')))
          .called(1);

      // Verify API action completed successfully
      expect(apiActionCalled, isTrue);
      expect(result, equals('api_result'));
    });

    test('performApiActionWithRefresh skips refresh when token is valid',
        () async {
      // Setup: Token valid (far from expiration)
      final futureExpiration = DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch
          .toString();

      when(mockStorage.read(key: 'token_expiration'))
          .thenAnswer((_) async => futureExpiration);
      when(mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'current_token');

      var apiActionCalled = false;
      Future<String> apiAction() async {
        apiActionCalled = true;
        return 'api_result';
      }

      final result = await tokenRefreshService.performWithRefresh(apiAction);

      // Verify refresh was NOT called
      verifyNever(
          mockStorage.write(key: 'auth_token', value: anyNamed('value')));

      // Verify API action still completed
      expect(apiActionCalled, isTrue);
      expect(result, equals('api_result'));
    });

    test('new token is stored after refresh', () async {
      final nearExpiration = DateTime.now()
          .add(const Duration(minutes: 2))
          .millisecondsSinceEpoch
          .toString();

      when(mockStorage.read(key: 'token_expiration'))
          .thenAnswer((_) async => nearExpiration);
      when(mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'valid_refresh_token');
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      await tokenRefreshService.performWithRefresh(() async => 'done');

      // Verify all token-related values were stored
      verify(mockStorage.write(key: 'auth_token', value: anyNamed('value')))
          .called(1);
      verify(mockStorage.write(key: 'refresh_token', value: anyNamed('value')))
          .called(1);
      verify(mockStorage.write(
              key: 'token_expiration', value: anyNamed('value')))
          .called(1);
    });
  });
}
