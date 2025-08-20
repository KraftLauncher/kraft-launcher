import 'package:meta/meta_meta.dart';

// NOTE: This is a dummy example of what this package could provide;
// this is an assumption, and anything in here is incorrect.

// ignore: unused_element
const _nestedSealedClassCompositionWorkaround =
    _NestedSealedClassCompositionWorkaround();

/// Marks classes that serve as composition-based workarounds
/// for Dart's current lack of support for nested sealed classes.
///
/// This should never actually be created, but currently,
/// Dart does not support nested sealed classes, and we haven't
/// found a reliable solution without duplicating code other than
/// this composition workaround.
///
/// This annotation is intended purely for documentation purposes
/// to clarify the design intent behind these workaround classes.
///
/// Note: This annotation has no runtime behavior or functional effect.
@Target({TargetKind.classType})
class _NestedSealedClassCompositionWorkaround {
  const _NestedSealedClassCompositionWorkaround();
}
