import '../network/api_client.dart';

String customerError(Object error, {String action = 'save your changes'}) {
  if (error is ApiException) {
    if (error.statusCode == 401) return 'Please sign in again, then retry.';
    if (error.statusCode == 403) {
      return 'This action is unavailable for your account. Contact the care team for help.';
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return 'Please check your details and try again.';
    }
    if (error.statusCode == 409) {
      return 'These details have changed. Refresh and try again.';
    }
  }
  return 'Could not $action. Check your connection and try again.';
}
