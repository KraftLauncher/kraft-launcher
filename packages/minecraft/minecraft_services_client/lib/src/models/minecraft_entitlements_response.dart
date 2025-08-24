import 'package:collection_utils/collection_utils.dart';
import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftEntitlementsResponse {
  const MinecraftEntitlementsResponse({
    required this.items,
    required this.signature,
    required this.keyId,
  });

  factory MinecraftEntitlementsResponse.fromJson(JsonMap json) {
    final itemsJson = json['items']! as JsonList;
    final itemsList = itemsJson
        .map(
          (itemJson) => MinecraftEntitlementItem.fromJson(itemJson as JsonMap),
        )
        .toList();

    return MinecraftEntitlementsResponse(
      items: itemsList,
      signature: json['signature']! as String,
      keyId: json['keyId']! as String,
    );
  }

  final List<MinecraftEntitlementItem> items;
  final String signature;
  final String keyId;

  @override
  String toString() =>
      'MinecraftEntitlementsResponse(items: $items, signature: $signature, keyId: $keyId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MinecraftEntitlementsResponse &&
        listEquals(other.items, items) &&
        other.signature == signature &&
        other.keyId == keyId;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), signature, keyId);
}

@immutable
class MinecraftEntitlementItem {
  const MinecraftEntitlementItem({required this.name, required this.signature});

  factory MinecraftEntitlementItem.fromJson(JsonMap json) {
    return MinecraftEntitlementItem(
      name: json['name']! as String,
      signature: json['signature']! as String,
    );
  }

  final String name;
  final String signature;

  @override
  String toString() =>
      'MinecraftEntitlementItem(name: $name, signature: $signature)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MinecraftEntitlementItem &&
        other.name == name &&
        other.signature == signature;
  }

  @override
  int get hashCode => Object.hash(name, signature);
}
