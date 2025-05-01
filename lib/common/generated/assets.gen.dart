/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart' as _lottie;

class $AssetsLottieGen {
  const $AssetsLottieGen();

  /// Directory path: assets/lottie/errors
  $AssetsLottieErrorsGen get errors => const $AssetsLottieErrorsGen();

  /// Directory path: assets/lottie/loading
  $AssetsLottieLoadingGen get loading => const $AssetsLottieLoadingGen();

  /// Directory path: assets/lottie/no_data_found
  $AssetsLottieNoDataFoundGen get noDataFound =>
      const $AssetsLottieNoDataFoundGen();
}

class $AssetsLottieErrorsGen {
  const $AssetsLottieErrorsGen();

  /// File path: assets/lottie/errors/server_error.json
  LottieGenImage get serverError =>
      const LottieGenImage('assets/lottie/errors/server_error.json');

  /// File path: assets/lottie/errors/unknown_error.json
  LottieGenImage get unknownError =>
      const LottieGenImage('assets/lottie/errors/unknown_error.json');

  /// List of all assets
  List<LottieGenImage> get values => [serverError, unknownError];
}

class $AssetsLottieLoadingGen {
  const $AssetsLottieLoadingGen();

  /// File path: assets/lottie/loading/loading_1.json
  LottieGenImage get loading1 =>
      const LottieGenImage('assets/lottie/loading/loading_1.json');

  /// File path: assets/lottie/loading/loading_2.json
  LottieGenImage get loading2 =>
      const LottieGenImage('assets/lottie/loading/loading_2.json');

  /// File path: assets/lottie/loading/loading_3.json
  LottieGenImage get loading3 =>
      const LottieGenImage('assets/lottie/loading/loading_3.json');

  /// File path: assets/lottie/loading/world_loading.json
  LottieGenImage get worldLoading =>
      const LottieGenImage('assets/lottie/loading/world_loading.json');

  /// List of all assets
  List<LottieGenImage> get values => [
    loading1,
    loading2,
    loading3,
    worldLoading,
  ];
}

class $AssetsLottieNoDataFoundGen {
  const $AssetsLottieNoDataFoundGen();

  /// File path: assets/lottie/no_data_found/no_data_coffee.json
  LottieGenImage get noDataCoffee =>
      const LottieGenImage('assets/lottie/no_data_found/no_data_coffee.json');

  /// File path: assets/lottie/no_data_found/no_data_found_1.json
  LottieGenImage get noDataFound1 =>
      const LottieGenImage('assets/lottie/no_data_found/no_data_found_1.json');

  /// File path: assets/lottie/no_data_found/no_data_found_2.json
  LottieGenImage get noDataFound2 =>
      const LottieGenImage('assets/lottie/no_data_found/no_data_found_2.json');

  /// File path: assets/lottie/no_data_found/no_data_found_3.json
  LottieGenImage get noDataFound3 =>
      const LottieGenImage('assets/lottie/no_data_found/no_data_found_3.json');

  /// List of all assets
  List<LottieGenImage> get values => [
    noDataCoffee,
    noDataFound1,
    noDataFound2,
    noDataFound3,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsLottieGen lottie = $AssetsLottieGen();
}

class LottieGenImage {
  const LottieGenImage(this._assetName, {this.flavors = const {}});

  final String _assetName;
  final Set<String> flavors;

  _lottie.LottieBuilder lottie({
    Animation<double>? controller,
    bool? animate,
    _lottie.FrameRate? frameRate,
    bool? repeat,
    bool? reverse,
    _lottie.LottieDelegates? delegates,
    _lottie.LottieOptions? options,
    void Function(_lottie.LottieComposition)? onLoaded,
    _lottie.LottieImageProviderFactory? imageProviderFactory,
    Key? key,
    AssetBundle? bundle,
    Widget Function(BuildContext, Widget, _lottie.LottieComposition?)?
    frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    String? package,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    void Function(String)? onWarning,
    _lottie.LottieDecoder? decoder,
    _lottie.RenderCache? renderCache,
    bool? backgroundLoading,
  }) {
    return _lottie.Lottie.asset(
      _assetName,
      controller: controller,
      animate: animate,
      frameRate: frameRate,
      repeat: repeat,
      reverse: reverse,
      delegates: delegates,
      options: options,
      onLoaded: onLoaded,
      imageProviderFactory: imageProviderFactory,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      package: package,
      addRepaintBoundary: addRepaintBoundary,
      filterQuality: filterQuality,
      onWarning: onWarning,
      decoder: decoder,
      renderCache: renderCache,
      backgroundLoading: backgroundLoading,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
