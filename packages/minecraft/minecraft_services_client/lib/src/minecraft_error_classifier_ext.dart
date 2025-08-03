import 'package:minecraft_services_client/src/models/minecraft_error_response.dart';

extension MinecraftErrorClassifierExt on MinecraftErrorResponse {
  // Could occur when uploading a skin image file that's invalid Minecraft skin.
  bool get isCouldNotValidateSkinImageData =>
      errorMessage == 'Could not validate image data.';

  // Could occur when uploading a new skin which uses Multipart,
  // and `variant` field name is invalid.
  bool get isInvalidRequestBodyForSkinUpload =>
      errorMessage == 'Invalid request body for skin upload';

  bool get isAccountNotFound => error == 'NOT_FOUND';
}
