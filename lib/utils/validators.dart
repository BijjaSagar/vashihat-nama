class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";
    if (!RegExp(r"^\d{10}$").hasMatch(value)) return "Enter a valid 10-digit phone number";
    return null;
  }
}
