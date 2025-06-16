import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kraft_launcher/common/logic/external_stream_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_constants.dart';

void main() {
  late _TestCubit cubit;

  setUp(() {
    cubit = _TestCubit(TestConstants.anyInt);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('has no subscriptions initially', () {
    expect(cubit.subscriptions, isEmpty);
  });

  group('forEach', () {
    test('emits new state from onData (mocked stream)', () {
      // This test uses a mock Stream and subscription to simulate stream events.
      // It verifies that the cubit reacts correctly when the stream calls onData.

      final mockSubscription = _MockStreamSubscription<int>();
      final mockStream = _MockStream<int>();

      late final void Function(int) capturedOnData;

      when(() => mockStream.listen(any())).thenAnswer((invocation) {
        capturedOnData =
            invocation.positionalArguments[0] as void Function(int);
        return mockSubscription;
      });

      cubit.forEach<int>(mockStream, onData: (data) => data * 2);

      // Simulate a stream emitting a value
      capturedOnData(3);

      expect(cubit.state, 6);
    });

    test('emits new state from onData (real $StreamController)', () async {
      // This test uses a real StreamController to simulate actual stream events,
      // verifying the same behavior as the mocked test above.

      final controller = StreamController<int>();

      cubit.forEach<int>(controller.stream, onData: (data) => data * 2);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, 2);

      controller.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, 6);

      await controller.close();
    });

    test('emits new state on error if onError provided', () async {
      final mockSubscription = _MockStreamSubscription<int>();
      final mockStream = _MockStream<int>();

      late final _StreamOnError capturedOnError;
      late final Object capturedError;
      late final StackTrace capturedStackTrace;

      when(
        () => mockStream.listen(any(), onError: any(named: 'onError')),
      ).thenAnswer((invocation) {
        capturedOnError = invocation.namedArguments[#onError] as _StreamOnError;
        return mockSubscription;
      });

      const expectedState = -1;

      cubit.forEach<int>(
        mockStream,
        onData: (_) => TestConstants.anyInt,
        onError: (error, stackTrace) {
          capturedError = error;
          capturedStackTrace = stackTrace;
          return expectedState;
        },
      );

      final expectedError = Exception(TestConstants.anyString);
      final expectedStackTrace = _FakeStackTrace();

      // Simulate a stream emitting an error
      capturedOnError(expectedError, expectedStackTrace);

      expect(
        cubit.state,
        expectedState,
        reason:
            'Should call $Cubit.emit() with the return value from onData correctly',
      );
      expect(
        capturedError,
        expectedError,
        reason: 'Should pass the $Object error argument to onError correctly',
      );
      expect(
        capturedStackTrace,
        expectedStackTrace,
        reason: 'Should pass the $StackTrace argument to onError correctly',
      );

      verify(
        () => mockStream.listen(
          any(),
          onError: any(named: 'onError', that: isNotNull),
        ),
      );
    });

    test('forEach does not emit on error if onError not provided', () async {
      final mockSubscription = _MockStreamSubscription<int>();
      final mockStream = _MockStream<int>();

      when(
        () => mockStream.listen(any(), onError: any(named: 'onError')),
      ).thenAnswer((invocation) {
        return mockSubscription;
      });

      cubit.forEach<int>(
        mockStream,
        onData: (_) => TestConstants.anyInt,
        // Not provided
        onError: null,
      );

      const expectedState = 42;

      cubit.emit(expectedState);

      if (cubit.state != expectedState) {
        throw StateError(
          'Expected the $Cubit state to be $expectedState. This indicates a bug in the test code.',
        );
      }

      expect(
        cubit.state,
        expectedState,
        reason:
            'The onError callback should be silently ignored without updating the state. The state should remain $expectedState without any emits.',
      );

      verify(
        () => mockStream.listen(
          any(),
          onError: any(named: 'onError', that: isNull),
        ),
      );
    });

    test('subscribes correctly', () {
      // ignore: cancel_subscriptions
      final mockStreamSubscription = _MockStreamSubscription<void>();

      final mockStream = _MockStream<void>();
      when(
        () => mockStream.listen(any()),
      ).thenAnswer((_) => mockStreamSubscription);

      cubit.forEach(mockStream, onData: (_) => TestConstants.anyInt);

      expect(cubit.subscriptions, [
        mockStreamSubscription,
      ], reason: 'Should add the subscription to the list');
    });
  });

  group('close', () {
    test('cancels all subscriptions', () async {
      final mockSubscriptions = [
        _MockStreamSubscription<void>(),
        _MockStreamSubscription<void>(),
        _MockStreamSubscription<void>(),
      ];

      cubit.subscriptions = mockSubscriptions;

      await cubit.close();

      for (final mockSubscription in mockSubscriptions) {
        verify(() => mockSubscription.cancel()).called(1);
        verifyNoMoreInteractions(mockSubscription);
      }
    });

    test(
      '$ExternalStreamCubit calls $Cubit.close() in overridden close()',
      () async {
        if (cubit.isClosed) {
          throw StateError(
            'The cubit is expected to be not closed before calling close. This indicates a bug with the test code.',
          );
        }

        await cubit.close();
        expect(cubit.isClosed, true);
      },
    );
  });
}

final class _TestCubit extends ExternalStreamCubit<int> {
  _TestCubit(super.initialState);
}

final class _MockStreamSubscription<T> extends Mock
    implements StreamSubscription<T> {
  _MockStreamSubscription() {
    when(() => cancel()).thenAnswer((_) async {});
  }
}

final class _MockStream<T> extends Mock implements Stream<T> {}

final class _FakeStackTrace extends Mock implements StackTrace {}

typedef _StreamOnError = void Function(Object error, StackTrace stackTrace);
