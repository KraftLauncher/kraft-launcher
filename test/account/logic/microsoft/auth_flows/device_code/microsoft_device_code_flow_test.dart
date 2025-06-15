import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/auth_flows/microsoft_device_code_flow_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/async_timer.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../../common/helpers/mocks.dart';

void main() {
  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late MicrosoftDeviceCodeFlow flow;

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    flow = MicrosoftDeviceCodeFlow(microsoftAuthApi: mockMicrosoftAuthApi);
  });

  group('pollingTimer', () {
    test('is initially null before timer is started', () {
      expect(flow.pollingTimer, null);
    });

    test('the timer works correctly', () {
      fakeAsync((async) {
        bool callbackCalled = false;
        int timerCallbackInvocationCount = 0;

        const duration = Duration(seconds: 5);
        flow.pollingTimer = AsyncTimer.periodic(const Duration(seconds: 5), () {
          callbackCalled = true;
          timerCallbackInvocationCount++;
        });

        expect(callbackCalled, false);
        expect(timerCallbackInvocationCount, 0);

        async.elapse(duration);

        expect(callbackCalled, true);
        expect(timerCallbackInvocationCount, 1);

        const additionalTicks = 500;
        for (int i = 0; i < additionalTicks; i++) {
          async.elapse(duration);
        }

        expect(timerCallbackInvocationCount, additionalTicks + 1);
      });
    });
  });

  group('isPollingTimerActive', () {
    test('returns false when timer is not active', () {
      expect(flow.isPollingTimerActive, false);
    });

    AsyncTimer<MicrosoftDeviceCodeApproved?>
    dummyTimer() => AsyncTimer.periodic(
      // Dummy duration, this callback will not get invoked unless we call async.elapse().
      const Duration(seconds: 5),
      () => fail('Timer callback should not be called'),
    );

    test('returns true when timer is active', () {
      fakeAsync((async) {
        flow.pollingTimer = dummyTimer();

        expect(flow.isPollingTimerActive, true);
        flow.cancelPollingTimer();

        // Ensure cancellation
        expect(flow.isPollingTimerActive, false);
        expect(flow.pollingTimer, null);
      });
    });
  });

  test('requestCancelPollingTimer defaults to false', () {
    expect(flow.requestCancelPollingTimer, false);
  });

  test('cancelPollingTimer cancels the timer correctly', () {
    fakeAsync((async) {
      // Assuming false to confirm the timer sets it to true.
      flow.requestCancelPollingTimer = false;

      int timerCallbackInvocationCount = 0;
      const duration = Duration(seconds: 5);
      flow.pollingTimer = AsyncTimer.periodic(
        duration,
        () => timerCallbackInvocationCount++,
      );

      // Ensure the timer is currently active
      expect(flow.isPollingTimerActive, true);
      expect(flow.pollingTimer, isNotNull);

      async.elapse(duration);
      expect(
        timerCallbackInvocationCount,
        1,
        reason: 'The timer is likely not working properly',
      );

      flow.cancelPollingTimer();

      async.elapse(duration);
      expect(
        timerCallbackInvocationCount,
        1,
        reason:
            'The timer has been cancelled but the callback is still invoking, likely a bug.',
      );

      expect(
        flow.requestCancelPollingTimer,
        true,
        reason:
            'Calling cancelPollingTimer should set requestCancelPollingTimer to false',
      );
      expect(flow.pollingTimer, isNull);
    });
  });

  Future<DeviceCodeLoginResult> run({
    DeviceCodeProgressCallback? onProgress,
    UserDeviceCodeAvailableCallback? onUserDeviceCodeAvailable,
  }) => flow.run(
    onUserDeviceCodeAvailable: onUserDeviceCodeAvailable ?? (_) {},
    onProgress: onProgress ?? (_) {},
  );

  group('run', () {
    const int expiresInSeconds = 15 * 60; // 15 minutes
    const int interval = 5; // 5 seconds

    MicrosoftRequestDeviceCodeResponse requestCodeResponse({
      String userCode = '',
      int expiresIn = expiresInSeconds,
      int interval = interval,
    }) => MicrosoftRequestDeviceCodeResponse(
      userCode: userCode,
      deviceCode: '',
      expiresIn: expiresIn,
      interval: interval,
    );

    setUp(() {
      when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
        (_) async => requestCodeResponse(expiresIn: -1, interval: -1),
      );
      when(() => mockMicrosoftAuthApi.checkDeviceCodeStatus(any())).thenAnswer(
        (_) async =>
            MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
      );
    });

    setUpAll(() {
      registerFallbackValue(
        const MicrosoftRequestDeviceCodeResponse(
          deviceCode: '',
          expiresIn: -1,
          interval: -1,
          userCode: '',
        ),
      );
    });
    test('sets requestCancelPollingTimer to false', () {
      flow.requestCancelPollingTimer = true;
      run();
      expect(flow.requestCancelPollingTimer, false);
    });

    Future<DeviceCodeLoginResult> simulateExpiration({
      DeviceCodeProgressCallback? onProgress,
      UserDeviceCodeAvailableCallback? onUserDeviceCodeAvailable,
    }) {
      final completer = Completer<DeviceCodeLoginResult>();
      fakeAsync((async) {
        final future = run(
          onUserDeviceCodeAvailable: onUserDeviceCodeAvailable,
          onProgress: onProgress,
        );

        verify(() => mockMicrosoftAuthApi.requestDeviceCode()).called(1);

        // This will cause the timer to be cancelled the next time it triggers
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async => MicrosoftCheckDeviceCodeStatusResult.expired(),
        );

        future
            .then((result) {
              completer.complete(result);
            })
            .onError((e, stacktrace) {
              completer.completeError(e!, stacktrace);
            });

        // Trigger the timer callback
        async.elapse(const Duration(seconds: interval + 1));

        async.flushMicrotasks();
      });

      return completer.future.timeout(const Duration(seconds: 1));
    }

    Future<DeviceCodeLoginResult> simulateSuccess({
      DeviceCodeProgressCallback? onProgress,
      UserDeviceCodeAvailableCallback? onUserDeviceCodeAvailable,
      MicrosoftOAuthTokenResponse? mockTokenResponse,
      bool shouldMockCheckCodeResponse = true,
      MicrosoftRequestDeviceCodeResponse? mockRequestCodeResponse,
    }) {
      when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
        (_) async =>
            mockRequestCodeResponse ??
            const MicrosoftRequestDeviceCodeResponse(
              deviceCode: '',
              userCode: '',
              interval: interval,
              expiresIn: 5000,
            ),
      );

      final completer = Completer<DeviceCodeLoginResult>();
      fakeAsync((async) {
        final future = run(
          onUserDeviceCodeAvailable: onUserDeviceCodeAvailable,
          onProgress: onProgress,
        );

        if (shouldMockCheckCodeResponse) {
          // This will cause the timer to be cancelled the next time it triggers
          when(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
          ).thenAnswer(
            (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(
              mockTokenResponse ??
                  const MicrosoftOAuthTokenResponse(
                    accessToken: '',
                    refreshToken: '',
                    expiresIn: -1,
                  ),
            ),
          );
        }

        future
            .then((result) {
              completer.complete(result);
            })
            .onError((e, stacktrace) {
              completer.completeError(e!, stacktrace);
            });

        // Trigger the timer callback
        async.elapse(const Duration(seconds: interval + 1));

        async.flushMicrotasks();
      });

      return completer.future.timeout(const Duration(seconds: 1));
    }

    test('requests device code and provides the user code', () async {
      const userDeviceCode = 'EXAMPLE-USER-CODE';
      final requestDeviceCodeResponse = requestCodeResponse(
        userCode: userDeviceCode,
        expiresIn: expiresInSeconds,
        interval: interval,
      );

      when(
        () => mockMicrosoftAuthApi.requestDeviceCode(),
      ).thenAnswer((_) async => requestDeviceCodeResponse);

      String? capturedUserDeviceCode;
      final progressEvents = <MicrosoftDeviceCodeProgress>[];
      await simulateExpiration(
        onUserDeviceCodeAvailable:
            (deviceCode) => capturedUserDeviceCode = deviceCode,
        onProgress: (progress) => progressEvents.add(progress),
      );

      verify(
        () => mockMicrosoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse,
        ),
      ).called(1);

      verifyNoMoreInteractions(mockMicrosoftAuthApi);

      expect(capturedUserDeviceCode, userDeviceCode);
      expect(
        progressEvents.first,
        MicrosoftDeviceCodeProgress.waitingForUserLogin,
        reason:
            'onProgressUpdate should be called with ${MicrosoftDeviceCodeProgress.waitingForUserLogin.name} first. Progress list: $progressEvents',
      );
    });

    test('uses correct interval duration and advances timer accordingly', () {
      const fakeInterval = 50;
      when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
        (_) async => requestCodeResponse(
          interval: fakeInterval,
          // Set a high expiration (in seconds) to simulate long-lived polling without triggering expiration.
          expiresIn: 5000000,
        ),
      );
      when(() => mockMicrosoftAuthApi.checkDeviceCodeStatus(any())).thenAnswer(
        (_) async =>
            MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
      );

      fakeAsync((async) {
        run();

        async.flushMicrotasks();

        expect(flow.pollingTimer?.timer.tick, 0);

        const duration = Duration(seconds: fakeInterval);

        async.elapse(duration);

        expect(flow.pollingTimer?.timer.tick, 1);

        async.elapse(duration);

        expect(flow.pollingTimer?.timer.tick, 2);

        final currentTicks = flow.pollingTimer!.timer.tick;

        const additionalTicks = 500;
        for (int i = 0; i < additionalTicks; i++) {
          async.elapse(duration);
        }

        expect(flow.pollingTimer!.timer.tick, currentTicks + additionalTicks);

        flow.cancelPollingTimer();
      });
    });

    test(
      'cancels timer on next run if cancellation was requested before timer initialization',
      () {
        // The timer can only be cancelled once it has been initialized. Before initialization,
        // the device code is requested, which is an asynchronous call. During this time,
        // users can cancel the operation, and the timer is null at this point.
        // The requestCancelPollingTimer flag is used to cancel the timer
        // the next time it is invoked, and it should be checked on each run.

        // Example duration
        const requestDeviceCodeDuration = Duration(seconds: interval * 2);

        fakeAsync((async) {
          when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer((
            _,
          ) async {
            await Future<void>.delayed(requestDeviceCodeDuration);
            return requestCodeResponse();
          });

          // Login with device code was requested.
          final future = run();

          // The requestDeviceCode call is still not finished yet after this call.
          async.elapse(requestDeviceCodeDuration - const Duration(seconds: 2));

          verify(() => mockMicrosoftAuthApi.requestDeviceCode()).called(1);

          // Users might want to login with auth code instead before requestDeviceCode finishes,
          // cancelling the device code polling.
          flow.cancelPollingTimer();

          expect(
            flow.requestCancelPollingTimer,
            true,
            reason:
                'The requestCancelPollingTimer flag should be true when cancelPollingTimer is called',
          );

          async.elapse(requestDeviceCodeDuration);

          expect(
            flow.pollingTimer,
            null,
            reason:
                'The timer should be cancelled and null when it was requested to be cancelled before it got initialized',
          );

          // Ensure the code execution stops (i.e., `return` is used) after the timer is closed.
          try {
            verifyNever(
              () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
            );
          } on TestFailure catch (e) {
            fail(
              'Expected no call to checkDeviceCodeStatus after the timer was canceled.\n'
              'This likely means execution continued past the cancel call — is `return;` used after cancelPollingTimer when requestCancelPollingTimer is true?\n'
              'Details: $e',
            );
          }

          bool callbackCompleted = false;
          future.then((result) {
            expect(result.$1, null);
            expect(
              result.$2,
              DeviceCodeTimerCloseReason.cancelledByUser,
              reason:
                  'The close reason should be ${DeviceCodeTimerCloseReason.cancelledByUser.name} because it was cancelled due to user request.',
            );
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      },
    );

    test(
      'cancels the timer and stops execution when the device code is expired while polling',
      () {
        const expiresIn = 5400;
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async =>
              requestCodeResponse(expiresIn: expiresIn, interval: interval),
        );

        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async =>
              MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
        );

        fakeAsync((async) {
          final future = run();

          async.flushMicrotasks();
          expect(
            flow.pollingTimer,
            isNotNull,
            reason: 'The timer should not be null when it started',
          );

          const intervalDuration = Duration(seconds: interval);
          async.elapse(intervalDuration);

          expect(
            flow.pollingTimer,
            isNotNull,
            reason:
                'The code is still not expired after first timer invocation',
          );

          // Number of check attempts in timer before it gets expired.
          // The check has run only once at this point.
          const totalCheckUntilExpired = expiresIn / interval;
          const checksUntilExpired = totalCheckUntilExpired - 1;

          const checksBeforeExpiration = checksUntilExpired - 1;
          for (int i = 0; i < checksBeforeExpiration; i++) {
            async.elapse(intervalDuration);
          }

          expect(
            flow.pollingTimer,
            isNotNull,
            reason:
                'The code is still not expired before the last timer invocation',
          );

          async.elapse(intervalDuration);

          expect(
            flow.pollingTimer,
            isNull,
            reason:
                'The timer should be cancelled after $totalCheckUntilExpired invocations where each invocation runs every ${intervalDuration.inSeconds}s since code expires in ${expiresIn}s',
          );

          bool callbackCompleted = false;
          future.then((result) {
            expect(result.$1, null);
            expect(
              result.$2,
              DeviceCodeTimerCloseReason.codeExpired,
              reason:
                  'The close reason should be ${DeviceCodeTimerCloseReason.codeExpired.name} as it was cancelled due to expiration',
            );
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      },
    );

    // It might be confusing, but currently both this test and
    // the one above it are testing the same thing in slightly different ways.
    // This test verifies whether the timer callback checks if the code is expired.
    // The test above this verifies whether the "Future.then" callback was used
    // to cancel the timer on expiration, which is outside of the timer callback.
    // Since the "Future.then" callback is always called in both cases, this test
    // will not fail if the callback doesn't check whether the code is expired.
    // Fixing this would require changes to production code, but it's not an issue.
    test(
      'cancels the timer and stops execution when the device code is expired after awaiting for expiresIn',
      () {
        const expiresIn = 9200;
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async =>
              requestCodeResponse(expiresIn: expiresIn, interval: interval),
        );
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async =>
              MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
        );

        fakeAsync((async) {
          final future = run();

          async.flushMicrotasks();
          expect(flow.pollingTimer, isNotNull);
          async.elapse(const Duration(seconds: expiresIn));
          async.elapse(const Duration(seconds: interval));
          expect(flow.pollingTimer, null);

          bool callbackCompleted = false;
          future.then((result) {
            expect(result.$1, null);
            expect(
              result.$2,
              DeviceCodeTimerCloseReason.codeExpired,
              reason:
                  'The close reason should be ${DeviceCodeTimerCloseReason.codeExpired.name} as it was cancelled due to expiration',
            );
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      },
    );

    test('cancels timer as expired when API responds with expired', () async {
      when(
        () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
      ).thenAnswer((_) async => MicrosoftCheckDeviceCodeStatusResult.expired());

      fakeAsync((async) {
        final future = run();

        async.flushMicrotasks();

        async.elapse(const Duration(seconds: interval));

        expect(flow.pollingTimer, null);

        bool callbackCompleted = false;
        future.then((result) {
          expect(result.$1, null);
          expect(result.$2, DeviceCodeTimerCloseReason.codeExpired);
          callbackCompleted = true;
        });

        async.flushMicrotasks();
        expect(
          callbackCompleted,
          true,
          reason: 'The then callback was not completed',
        );
      });
    });

    test('continues polling when API responds with pending', () {
      final requestDeviceCodeResponse = requestCodeResponse(
        expiresIn: 9000,
        interval: interval,
      );
      when(
        () => mockMicrosoftAuthApi.requestDeviceCode(),
      ).thenAnswer((_) async => requestDeviceCodeResponse);
      when(() => mockMicrosoftAuthApi.checkDeviceCodeStatus(any())).thenAnswer(
        (_) async =>
            MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
      );

      fakeAsync((async) {
        run();

        async.flushMicrotasks();

        verify(() => mockMicrosoftAuthApi.requestDeviceCode()).called(1);

        expect(flow.pollingTimer?.timer.tick, 0);

        const duration = Duration(seconds: interval);

        for (int i = 1; i <= 50; i++) {
          async.elapse(duration);
          expect(flow.pollingTimer?.timer.tick, i);
          verify(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(
              requestDeviceCodeResponse,
            ),
          ).called(1);
        }

        flow.cancelPollingTimer();

        async.elapse(duration);
        expect(flow.pollingTimer?.timer.tick, null);
        verifyNoMoreInteractions(mockMicrosoftAuthApi);
      });
    });

    test(
      'cancels the timer as ${DeviceCodeTimerCloseReason.approved} when API responds with success',
      () {
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async => requestCodeResponse(expiresIn: 9000, interval: interval),
        );
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(
            const MicrosoftOAuthTokenResponse(
              accessToken: '',
              refreshToken: '',
              expiresIn: -1,
            ),
          ),
        );

        fakeAsync((async) {
          final future = run();

          async.flushMicrotasks();
          async.elapse(const Duration(seconds: interval));

          bool callbackCompleted = false;
          future.then((result) {
            expect(result.$1, isNotNull);
            expect(
              result.$2,
              DeviceCodeTimerCloseReason.approved,
              reason:
                  'The close reason should be ${DeviceCodeTimerCloseReason.approved.name} because it was cancelled due to a successful login.',
            );
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      },
    );

    test(
      'returns close reason ${DeviceCodeTimerCloseReason.cancelledByUser} when user cancels the operation',
      () async {
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async => requestCodeResponse(
            expiresIn: expiresInSeconds,
            interval: interval,
          ),
        );

        fakeAsync((async) {
          final future = run();

          async.flushMicrotasks();

          async.elapse(const Duration(seconds: interval));

          flow.cancelPollingTimer();

          bool callbackCompleted = true;
          future.then((result) {
            expect(result.$1, null);
            expect(
              result.$2,
              DeviceCodeTimerCloseReason.cancelledByUser,
              reason:
                  'The close reason should be ${DeviceCodeTimerCloseReason.cancelledByUser.name} because it was cancelled due to user request.',
            );
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      },
    );

    test(
      'returns close reason ${DeviceCodeTimerCloseReason.declined} when user cancels the operation',
      () async {
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async => requestCodeResponse(
            expiresIn: expiresInSeconds,
            interval: interval,
          ),
        );
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async => MicrosoftCheckDeviceCodeStatusResult.declined(),
        );
        fakeAsync((async) {
          final future = run();

          async.flushMicrotasks();

          async.elapse(const Duration(seconds: interval));

          flow.cancelPollingTimer();

          bool callbackCompleted = true;
          future.then((result) {
            expect(result.$1, null);
            expect(
              result.$2,
              DeviceCodeTimerCloseReason.declined,
              reason:
                  'The close reason should be ${DeviceCodeTimerCloseReason.declined.name} because the user explicitly denied the authorization request, so the timer was cancelled as a result.',
            );
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      },
    );

    test(
      'does not interact with unrelated $MicrosoftAuthApi methods',
      () async {
        final (_, _) = await simulateSuccess();

        verifyInOrder([
          () => mockMicrosoftAuthApi.requestDeviceCode(),
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ]);
        verifyNoMoreInteractions(mockMicrosoftAuthApi);
      },
    );

    test(
      'returns $MicrosoftOAuthTokenResponse from $MicrosoftAuthApi',
      () async {
        const expectedTokenResponse = MicrosoftOAuthTokenResponse(
          accessToken: 'example-microsoft-oauth-token',
          expiresIn: 3600,
          refreshToken: 'example-microsoft-oauth-refresh-token',
        );
        final (actualTokenResponse, _) = await simulateSuccess(
          mockTokenResponse: expectedTokenResponse,
        );

        expect(actualTokenResponse, same(expectedTokenResponse));
      },
    );
  });
}
