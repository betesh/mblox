### 0.6.0 (3/11/2015)

* BREAKING CHANGES:
  * Mblox::Sms#message will now raise an exception if the message was split.  Use Mblox::Sms#messages in that case.  If the message was not split, Mblox::Sms#message returns the message as a String directly instead of warpping it in an array.
  * `on_message_too_long`, `logger`, and `log_at` are configured in SmsValidation, a dependency of this gem.  See https://github.com/betesh/sms_validation/blob/master/README.md for details
