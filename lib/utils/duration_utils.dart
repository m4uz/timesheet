String toHmString(Duration duration, {bool negativeToZero = true}) {
  if (duration.isNegative && negativeToZero) return '0m';

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  final buffer = StringBuffer();
  if (hours != 0) buffer.write('${hours}h');
  if (minutes != 0) buffer.write('${minutes}m');

  return buffer.isEmpty ? '0m' : buffer.toString();
}
