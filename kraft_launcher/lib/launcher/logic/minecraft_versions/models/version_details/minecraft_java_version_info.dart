import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftJavaVersionInfo extends Equatable {
  const MinecraftJavaVersionInfo({
    required this.component,
    required this.majorVersion,
  });

  final String component;
  final int majorVersion;

  @override
  List<Object?> get props => [component, majorVersion];
}
