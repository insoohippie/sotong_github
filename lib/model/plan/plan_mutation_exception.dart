/// Domain-specific exception thrown when a plan mutation violates rules.
class PlanMutationException implements Exception {
  PlanMutationException(this.message);

  final String message;

  @override
  String toString() => 'PlanMutationException($message)';
}
