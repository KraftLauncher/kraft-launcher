import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

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
