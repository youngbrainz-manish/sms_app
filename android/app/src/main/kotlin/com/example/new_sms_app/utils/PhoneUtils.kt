package com.example.new_sms_app.utils

object PhoneUtils {

    /**
     * Normalizes Indian phone numbers to: 91XXXXXXXXXX
     *
     * Matches Dart logic exactly:
     * - ignores empty / non-repliable addresses
     * - removes spaces & hyphens
     * - removes leading +
     * - converts:
     *    XXXXXXXXXX      -> 91XXXXXXXXXX
     *    0XXXXXXXXXX     -> 91XXXXXXXXXX
     */
    fun normalize(input: String?, source: String = ""): String {
        if (input.isNullOrBlank() || !canReply(input)) {
            return input ?: ""
        }

        // Debug (optional)
        // Log.d("PhoneUtils", "normalize => $input :: $source")

        var number = input
            .replace("\\s|-".toRegex(), "") // remove spaces & hyphens

        // Remove leading +
        if (number.startsWith("+")) {
            number = number.substring(1)
        }

        // If 10 digits → add India country code
        if (number.length == 10 && number.all { it.isDigit() }) {
            number = "91$number"
        }

        // If starts with 0XXXXXXXXXX (11 digits)
        if (number.startsWith("0") && number.length == 11) {
            number = "91${number.substring(1)}"
        }

        return number
    }

    /**
     * Same logic as Dart canReply()
     */
    fun canReply(address: String?): Boolean {
        if (address.isNullOrBlank()) return false

        return address.length >= 6 &&
                address.matches(Regex("^\\+?\\d+$"))
    }
}
