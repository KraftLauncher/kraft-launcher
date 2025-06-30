import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';

LoadingErrorWidgetBuilder commonCachedNetworkImageErrorBuilder() {
  return (context, url, error) =>
      Text(context.loc.errorLoadingNetworkImage(error.toString()));
}
