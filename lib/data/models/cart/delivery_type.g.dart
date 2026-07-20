// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryTypeAdapter extends TypeAdapter<DeliveryType> {
  @override
  final int typeId = 13;

  @override
  DeliveryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DeliveryType.pickup;
      case 1:
        return DeliveryType.courier;
      default:
        return DeliveryType.pickup;
    }
  }

  @override
  void write(BinaryWriter writer, DeliveryType obj) {
    switch (obj) {
      case DeliveryType.pickup:
        writer.writeByte(0);
        break;
      case DeliveryType.courier:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
