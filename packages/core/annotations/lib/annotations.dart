import 'package:meta/meta_meta.dart';

/// {@macro debugOnlyInfra}
const debugOnlyInfra = _DebugOnlyInfra();

/// {@template debugOnlyInfra}
/// Marks infrastructure-level details that are included in domain APIs
/// **for debugging or logging purposes only**.
///
/// Consumers of the domain API **should not access or rely on** these
/// details, as they are not part of the domain model.
///
/// Examples of infrastructure details include:
///
/// - HTTP (e.g., response body, status code)
/// - JSON payloads
/// - System or external service data
///
/// These details exist purely for logging, diagnostics, or debugging.
///
/// Note: This annotation has **no runtime behavior or functional effect**.
/// {@endtemplate}
@Target({TargetKind.parameter})
class _DebugOnlyInfra {
  const _DebugOnlyInfra();
}
