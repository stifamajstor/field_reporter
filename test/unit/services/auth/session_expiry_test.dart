import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:field_reporter/features/auth/services/session_expiry_service.dart';

@GenerateMocks([FlutterSecureStorage])
import 'session_expiry_test.mocks.dart';

void main() {
  group('SessionExpiryService - Expired session redirects to login', () {
    late MockFlutterSecureStorage mockStorage;
    late SessionExpiryService sessionExpiryService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      sessionExpiryService = SessionExpiryService(storage: mockStorage);
    });

    group('Session expiration detection', () {
      test('detects when session is expired', () async {
        // Simulate expired token (past expiration time)
        final expiredTimestamp = DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => expiredTimestamp);
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null); // No refresh token available

        final isExpired = await sessionExpiryService.isSessionExpired();

        expect(isExpired, isTrue);
      });

      test('session is valid when token not expired', () async {
        final validTimestamp = DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => validTimestamp);

        final isExpired = await sessionExpiryService.isSessionExpired();

        expect(isExpired, isFalse);
      });
    });

    group('API action with expired session', () {
      test(
          'attempting API action with expired session returns SessionExpired state',
          () async {
        // Setup: Token is expired and refresh fails
        final expiredTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => expiredTimestamp);
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null); // No refresh token

        // Attempt an API action
        final result = await sessionExpiryService.performApiAction(
          () async => 'api_result',
          currentPath: '/dashboard',
        );

        expect(result.isSessionExpired, isTrue);
        expect(result.message, contains('session'));
      });

      test('session expired result includes return URL for post-login redirect',
          () async {
        final expiredTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => expiredTimestamp);
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        final result = await sessionExpiryService.performApiAction(
          () async => 'api_result',
          currentPath: '/projects/123/edit',
        );

        expect(result.isSessionExpired, isTrue);
        expect(result.returnUrl, equals('/projects/123/edit'));
      });

      test('successful API action when session is valid', () async {
        final validTimestamp = DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => validTimestamp);

        final result = await sessionExpiryService.performApiAction(
          () async => 'api_result',
          currentPath: '/dashboard',
        );

        expect(result.isSessionExpired, isFalse);
        expect(result.data, equals('api_result'));
      });
    });

    group('Session expired message', () {
      test('session expired message is displayed correctly', () async {
        final expiredTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => expiredTimestamp);
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        final result = await sessionExpiryService.performApiAction(
          () async => 'api_result',
          currentPath: '/dashboard',
        );

        expect(result.message,
            equals('Your session has expired. Please log in again.'));
      });
    });

    group('Clearing session on expiry', () {
      test('clears stored tokens when session expires', () async {
        final expiredTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => expiredTimestamp);
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);
        when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

        await sessionExpiryService.performApiAction(
          () async => 'api_result',
          currentPath: '/dashboard',
        );

        verify(mockStorage.delete(key: 'auth_token')).called(1);
        verify(mockStorage.delete(key: 'user_id')).called(1);
        verify(mockStorage.delete(key: 'user_email')).called(1);
      });
    });

    group('Return URL preservation', () {
      test('stores return URL for post-login redirect', () async {
        final expiredTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch
            .toString();

        when(mockStorage.read(key: 'token_expiration'))
            .thenAnswer((_) async => expiredTimestamp);
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);
        when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        await sessionExpiryService.performApiAction(
          () async => 'api_result',
          currentPath: '/reports/456',
        );

        verify(mockStorage.write(key: 'return_url', value: '/reports/456'))
            .called(1);
      });

      test('retrieves stored return URL after login', () async {
        when(mockStorage.read(key: 'return_url'))
            .thenAnswer((_) async => '/projects/123');
        when(mockStorage.delete(key: 'return_url')).thenAnswer((_) async {});

        final returnUrl = await sessionExpiryService.getAndClearReturnUrl();

        expect(returnUrl, equals('/projects/123'));
        verify(mockStorage.delete(key: 'return_url')).called(1);
      });

      test('returns null if no return URL stored', () async {
        when(mockStorage.read(key: 'return_url')).thenAnswer((_) async => null);

        final returnUrl = await sessionExpiryService.getAndClearReturnUrl();

        expect(returnUrl, isNull);
      });
    });
  });
}
