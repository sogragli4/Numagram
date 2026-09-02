/// Google UMP consent flow. Must run to completion — and only then may an
/// ad SDK be initialised or asked for an ad — per the Phase 4 compliance
/// requirement ("No ad requests before consent resolves").
abstract class ConsentService {
  /// Requests the latest consent info, shows a consent form if one is
  /// required, and resolves once the user has responded (or none was
  /// needed). Returns whether ads may now be requested.
  Future<bool> resolveConsent();
}
