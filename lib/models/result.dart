sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = OK._;
  const factory Result.error(String message, [Exception? exception]) = Error._;
}

final class OK<T> extends Result<T> {
  const OK._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  const Error._(this.message, [this.exception]);

  final String message;
  final Exception? exception;

  @override
  String toString() => exception != null
      ? 'Result<$T>.error($message, $exception)'
      : 'Result<$T>.error($message)';
}
