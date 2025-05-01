import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/build_context_ext.dart';

LoadingErrorWidgetBuilder commonCachedNetworkImageErrorBuilder() {
  return (context, url, error) =>
      Text(context.loc.errorLoadingNetworkImage(error.toString()));
}
