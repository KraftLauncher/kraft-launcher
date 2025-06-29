import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';

@immutable
class MinecraftJavaVersionInfo extends Equatable {
  const MinecraftJavaVersionInfo({
    required this.component,
    required this.majorVersion,
  });

  factory MinecraftJavaVersionInfo.fromJson(JsonMap json) =>
      MinecraftJavaVersionInfo(
        component: json['component']! as String,
        majorVersion: json['majorVersion']! as int,
      );

  final String component;
  final int majorVersion;

  @override
  List<Object?> get props => [component, majorVersion];
}
