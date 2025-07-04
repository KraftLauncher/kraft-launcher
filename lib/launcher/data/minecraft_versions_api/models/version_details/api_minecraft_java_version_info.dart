import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class ApiMinecraftJavaVersionInfo extends Equatable {
  const ApiMinecraftJavaVersionInfo({
    required this.component,
    required this.majorVersion,
  });

  factory ApiMinecraftJavaVersionInfo.fromJson(JsonMap json) =>
      ApiMinecraftJavaVersionInfo(
        component: json['component']! as String,
        majorVersion: json['majorVersion']! as int,
      );

  final String component;
  final int majorVersion;

  @override
  List<Object?> get props => [component, majorVersion];
}
