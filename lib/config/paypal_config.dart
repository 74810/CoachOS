class PaypalConfig {
  static const String clientId =
      'AeBMH9c1IgHpwyESDZWbDW8oh7i0p0ogxjv390gKz30tS9LZhChGIZLJ95xhFQqzc4vbCyuSoE8jHG1Z';
  static const String clientSecret =
      'EGzYFjxZSj4tiJk9H6A2V8k6EtRDlxVhCO29dr503eWtTBy1XLNkSB4gAM8byRsGFMIQ1rsjT8bW3c-S';

  // iOS intercepta el scheme coachos:// y devuelve el control a la app
  static const String returnUrl = 'coachos://paypal-success';
  static const String cancelUrl = 'coachos://paypal-cancel';

  static const String apiBase = 'https://api-m.sandbox.paypal.com';
}
