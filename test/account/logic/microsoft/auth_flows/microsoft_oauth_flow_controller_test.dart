import 'dart:io';

import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/microsoft_oauth_flow_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../data/microsoft_auth_api/microsoft_auth_api_dummy_values.dart';

void main() {
  late _MockMicrosoftAuthCodeFlow mockMicrosoftAuthCodeFlow;
  late _MockMicrosoftDeviceCodeFlow mockMicrosoftDeviceCodeFlow;

  late MicrosoftOAuthFlowController controller;

  setUp(() {
    mockMicrosoftAuthCodeFlow = _MockMicrosoftAuthCodeFlow();
    mockMicrosoftDeviceCodeFlow = _MockMicrosoftDeviceCodeFlow();

    controller = MicrosoftOAuthFlowController(
      microsoftAuthCodeFlow: mockMicrosoftAuthCodeFlow,
      microsoftDeviceCodeFlow: mockMicrosoftDeviceCodeFlow,
    );
  });

  setUpAll(() {
    registerFallbackValue(_dummyAuthCodePageVariants());
  });

  group('loginWithMicrosoftAuthCode', () {
    setUp(() {
      when(
        () => mockMicrosoftDeviceCodeFlow.cancelPollingTimer(),
      ).thenAnswer((_) => false);
    });

    void mockRun(MicrosoftOAuthTokenResponse tokenResponse) => when(
      () => mockMicrosoftAuthCodeFlow.run(
        onProgress: any(named: 'onProgress'),
        onAuthCodeLoginUrlAvailable: any(named: 'onAuthCodeLoginUrlAvailable'),
        authCodeResponsePageVariants: any(
          named: 'authCodeResponsePageVariants',
        ),
      ),
    ).thenAnswer((_) async => tokenResponse);

    test('passes arguments to $MicrosoftAuthCodeFlow correctly', () async {
      mockRun(_dummyTokenResponse());

      void expectedOnProgress(MicrosoftAuthCodeProgress _) {}
      void expectedOnAuthCodeLoginUrlAvailable(String _) {}

      final expectedAuthCodeResponsePageVariants = _dummyAuthCodePageVariants();

      await controller.loginWithMicrosoftAuthCode(
        onProgress: expectedOnProgress,
        onAuthCodeLoginUrlAvailable: expectedOnAuthCodeLoginUrlAvailable,
        authCodeResponsePageVariants: expectedAuthCodeResponsePageVariants,
      );

      verify(
        () => mockMicrosoftAuthCodeFlow.run(
          onProgress: any(that: same(expectedOnProgress), named: 'onProgress'),
          authCodeResponsePageVariants: any(
            that: same(expectedAuthCodeResponsePageVariants),
            named: 'authCodeResponsePageVariants',
          ),
          onAuthCodeLoginUrlAvailable: any(
            that: same(expectedOnAuthCodeLoginUrlAvailable),
            named: 'onAuthCodeLoginUrlAvailable',
          ),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockMicrosoftAuthCodeFlow);
    });

    test(
      'returns $MicrosoftOAuthTokenResponse from $MicrosoftAuthCodeFlow correctly',
      () async {
        final expectedTokenResponse = _dummyTokenResponse();

        mockRun(expectedTokenResponse);

        void expectedOnProgress(MicrosoftAuthCodeProgress _) {}
        void expectedOnAuthCodeLoginUrlAvailable(String _) {}

        final expectedAuthCodeResponsePageVariants =
            _dummyAuthCodePageVariants();

        final actualTokenResponse = await controller.loginWithMicrosoftAuthCode(
          onProgress: expectedOnProgress,
          onAuthCodeLoginUrlAvailable: expectedOnAuthCodeLoginUrlAvailable,
          authCodeResponsePageVariants: expectedAuthCodeResponsePageVariants,
        );

        expect(actualTokenResponse, expectedTokenResponse);
      },
    );

    test('cancels device code polling timer', () async {
      mockRun(_dummyTokenResponse());

      await controller.loginWithMicrosoftAuthCode(
        onProgress: (_) {},
        onAuthCodeLoginUrlAvailable: (_) {},
        authCodeResponsePageVariants: _dummyAuthCodePageVariants(),
      );

      verify(() => mockMicrosoftDeviceCodeFlow.cancelPollingTimer()).called(1);
      verifyNoMoreInteractions(mockMicrosoftDeviceCodeFlow);
    });
  });

  group('requestLoginWithMicrosoftDeviceCode', () {
    void mockRun(DeviceCodeLoginResult deviceCodeLoginResult) => when(
      () => mockMicrosoftDeviceCodeFlow.run(
        onProgress: any(named: 'onProgress'),
        onUserDeviceCodeAvailable: any(named: 'onUserDeviceCodeAvailable'),
      ),
    ).thenAnswer((_) async => deviceCodeLoginResult);

    test('passes arguments to $MicrosoftDeviceCodeFlow correctly', () async {
      mockRun((_dummyTokenResponse(), DeviceCodeTimerCloseReason.approved));

      void expectedOnProgress(MicrosoftDeviceCodeProgress _) {}
      void expectedOnUserDeviceCodeAvailable(String _) {}

      await controller.requestLoginWithMicrosoftDeviceCode(
        onProgress: expectedOnProgress,
        onUserDeviceCodeAvailable: expectedOnUserDeviceCodeAvailable,
      );

      verify(
        () => mockMicrosoftDeviceCodeFlow.run(
          onProgress: any(that: same(expectedOnProgress), named: 'onProgress'),
          onUserDeviceCodeAvailable: any(
            that: same(expectedOnUserDeviceCodeAvailable),
            named: 'onUserDeviceCodeAvailable',
          ),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockMicrosoftDeviceCodeFlow);
    });
    test(
      'returns $MicrosoftOAuthTokenResponse from $MicrosoftDeviceCodeFlow correctly',
      () async {
        final expectedTokenResponse = _dummyTokenResponse();
        const expectedDeviceCodeCloseReason =
            DeviceCodeTimerCloseReason.approved;

        mockRun((expectedTokenResponse, expectedDeviceCodeCloseReason));

        final (actualTokenResponse, actualCloseReason) = await controller
            .requestLoginWithMicrosoftDeviceCode(
              onProgress: (_) {},
              onUserDeviceCodeAvailable: (_) {},
            );
        expect(actualTokenResponse, same(expectedTokenResponse));
        expect(actualCloseReason, same(expectedDeviceCodeCloseReason));
      },
    );
  });

  test(
    'startAuthCodeServer delegates to $MicrosoftAuthCodeFlow correctly',
    () async {
      when(
        () => mockMicrosoftAuthCodeFlow.startServer(),
      ).thenAnswer((_) async => _FakeHttpServer());

      await controller.startAuthCodeServer();

      verify(() => mockMicrosoftAuthCodeFlow.startServer()).called(1);
      verifyNoMoreInteractions(mockMicrosoftAuthCodeFlow);
    },
  );

  test(
    'stopAuthCodeServerIfRunning delegates to $MicrosoftAuthCodeFlow correctly',
    () async {
      for (final value in {true, false}) {
        when(
          () => mockMicrosoftAuthCodeFlow.stopServerIfRunning(),
        ).thenAnswer((_) async => value);
        expect(await controller.stopAuthCodeServerIfRunning(), value);
        verify(() => mockMicrosoftAuthCodeFlow.stopServerIfRunning()).called(1);
      }
      verifyNoMoreInteractions(mockMicrosoftAuthCodeFlow);
    },
  );

  test(
    'cancelDeviceCodePollingTimer delegates to $MicrosoftDeviceCodeFlow correctly',
    () async {
      for (final value in {true, false}) {
        when(
          () => mockMicrosoftDeviceCodeFlow.cancelPollingTimer(),
        ).thenReturn(value);

        expect(controller.cancelDeviceCodePollingTimer(), value);

        verify(
          () => mockMicrosoftDeviceCodeFlow.cancelPollingTimer(),
        ).called(1);
      }
      verifyNoMoreInteractions(mockMicrosoftDeviceCodeFlow);
    },
  );
}

class _MockMicrosoftAuthCodeFlow extends Mock
    implements MicrosoftAuthCodeFlow {}

class _MockMicrosoftDeviceCodeFlow extends Mock
    implements MicrosoftDeviceCodeFlow {}

MicrosoftOAuthTokenResponse _dummyTokenResponse() =>
    dummyMicrosoftOAuthTokenResponse;

MicrosoftAuthCodeResponsePageContent _dummyAuthCodePageContent() =>
    const MicrosoftAuthCodeResponsePageContent(
      pageTitle: 'Example page title',
      title: 'Example title',
      subtitle: 'Example subtitle',
      pageLangCode: 'Example lang code',
      pageDir: 'Example page dir',
    );

MicrosoftAuthCodeResponsePageVariants _dummyAuthCodePageVariants() =>
    MicrosoftAuthCodeResponsePageVariants(
      accessDenied: _dummyAuthCodePageContent(),
      approved: _dummyAuthCodePageContent(),
      missingAuthCode: _dummyAuthCodePageContent(),
      unknownError: (_, _) => _dummyAuthCodePageContent(),
    );

class _FakeHttpServer extends Fake implements HttpServer {}
