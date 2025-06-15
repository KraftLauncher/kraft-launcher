import 'package:kraft_launcher/account/logic/account_repository.dart';
import 'package:kraft_launcher/account/logic/microsoft/microsoft_oauth_flow_controller.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/minecraft_account_refresher.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_service/minecraft_account_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// TODO: Complete full unit tests for empty groups of this file

void main() {
  late _MockAccountRepository mockAccountRepository;
  late _MockMicrosoftOAuthFlowController mockMicrosoftOAuthFlowController;
  late _MockMinecraftAccountResolver mockMinecraftAccountResolver;
  late _MockMinecraftAccountRefresher mockMinecraftAccountRefresher;

  late MinecraftAccountService service;

  setUp(() {
    mockAccountRepository = _MockAccountRepository();
    mockMicrosoftOAuthFlowController = _MockMicrosoftOAuthFlowController();
    mockMinecraftAccountResolver = _MockMinecraftAccountResolver();
    mockMinecraftAccountRefresher = _MockMinecraftAccountRefresher();

    service = MinecraftAccountService(
      accountRepository: mockAccountRepository,
      microsoftOAuthFlowController: mockMicrosoftOAuthFlowController,
      minecraftAccountResolver: mockMinecraftAccountResolver,
      minecraftAccountRefresher: mockMinecraftAccountRefresher,
    );
  });

  group('loginWithMicrosoftAuthCode', () {});

  group('requestLoginWithMicrosoftDeviceCode', () {});

  test(
    'stopAuthCodeServerIfRunning delegates to $MicrosoftOAuthFlowController',
    () async {
      for (final value in {true, false}) {
        when(
          () => mockMicrosoftOAuthFlowController.stopAuthCodeServerIfRunning(),
        ).thenAnswer((_) async => value);

        expect(await service.stopAuthCodeServerIfRunning(), value);

        verify(
          () => mockMicrosoftOAuthFlowController.stopAuthCodeServerIfRunning(),
        ).called(1);
      }

      verifyNoMoreInteractions(mockMicrosoftOAuthFlowController);
    },
  );

  test(
    'cancelDeviceCodePollingTimer delegates to $MicrosoftOAuthFlowController',
    () {
      for (final value in {true, false}) {
        when(
          () => mockMicrosoftOAuthFlowController.cancelDeviceCodePollingTimer(),
        ).thenAnswer((_) => value);

        expect(service.cancelDeviceCodePollingTimer(), value);

        verify(
          () => mockMicrosoftOAuthFlowController.cancelDeviceCodePollingTimer(),
        ).called(1);
      }

      verifyNoMoreInteractions(mockMicrosoftOAuthFlowController);
    },
  );

  group('refreshMicrosoftAccount', () {});
}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockMicrosoftOAuthFlowController extends Mock
    implements MicrosoftOAuthFlowController {}

class _MockMinecraftAccountResolver extends Mock
    implements MinecraftAccountResolver {}

class _MockMinecraftAccountRefresher extends Mock
    implements MinecraftAccountRefresher {}
