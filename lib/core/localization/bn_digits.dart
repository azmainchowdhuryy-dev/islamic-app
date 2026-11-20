/// সব সংখ্যা এই একটি ফাংশন দিয়ে দেখাবেন, যাতে বাংলা অঙ্ক এক জায়গা থেকে নিয়ন্ত্রিত হয়।
String localizeDigits(Object value, String lang) {
  final s = value.toString();
  if (lang != 'bn') return s;
  const en = '0123456789';
  const bn = '০১২৩৪৫৬৭৮৯';
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final i = en.indexOf(ch);
    buf.write(i == -1 ? ch : bn[i]);
  }
  return buf.toString();
}
