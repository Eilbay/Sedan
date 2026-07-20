// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_status_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderStatusTypeAdapter extends TypeAdapter<OrderStatusType> {
  @override
  final int typeId = 11;

  @override
  OrderStatusType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatusType.created;
      case 1:
        return OrderStatusType.assembling;
      case 2:
        return OrderStatusType.delivered;
      default:
        return OrderStatusType.created;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatusType obj) {
    switch (obj) {
      case OrderStatusType.created:
        writer.writeByte(0);
        break;
      case OrderStatusType.assembling:
        writer.writeByte(1);
        break;
      case OrderStatusType.delivered:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 12;

  @override
  OrderStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderStatus(
      type: fields[0] as OrderStatusType,
      timestamp: fields[1] as DateTime,
      message: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.message);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
