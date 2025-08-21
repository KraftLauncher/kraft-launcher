// TODO: Probably better to omit all the other progress enums and use this only?
enum MinecraftAuthProgress {
  waitingForUserLogin,
  refreshingMicrosoftTokens,
  exchangingAuthCode,
  requestingXboxToken,
  requestingXstsToken,
  loggingIntoMinecraft,
  fetchingProfile,
  checkingMinecraftJavaOwnership,
}
