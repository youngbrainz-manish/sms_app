class PhoneUtils {
  /// Normalizes Indian phone numbers to: 919XXXXXXXXX
  static String normalize(String input, {required String source}) {
    if (input.isEmpty || (!canReply(address: input))) return input;

    // Remove spaces, hyphens
    var number = input.replaceAll(RegExp(r'\s|-'), '');

    // Remove +
    if (number.startsWith('+')) {
      number = number.substring(1);
    }

    // If 10 digits, add India country code
    if (number.length == 10) {
      number = '91$number';
    }

    // If starts with 0XXXXXXXXXX
    if (number.startsWith('0') && number.length == 11) {
      number = '91${number.substring(1)}';
    }
    return number;
  }

  static bool canReply({required String address}) {
    final addr = address;
    return addr.length >= 6 && RegExp(r'^\+?\d+$').hasMatch(addr);
  }
}
