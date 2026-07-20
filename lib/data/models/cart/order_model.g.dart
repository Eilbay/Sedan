// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 14;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      items: (fields[1] as List).cast<CartItem>(),
      subtotal: fields[2] as double,
      deliveryType: fields[3] as DeliveryType,
      deliveryCost: fields[4] as double,
      total: fields[5] as double,
      pickupPointId: fields[6] as String?,
      comment: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      paidAt: fields[9] as DateTime?,
      statusHistory: (fields[10] as List).cast<OrderStatus>(),
      isPaid: fields[11] as bool? ?? false,
      userName: fields[12] as String?,
      userPhone: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.subtotal)
      ..writeByte(3)
      ..write(obj.deliveryType)
      ..writeByte(4)
      ..write(obj.deliveryCost)
      ..writeByte(5)
      ..write(obj.total)
      ..writeByte(6)
      ..write(obj.pickupPointId)
      ..writeByte(7)
      ..write(obj.comment)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.paidAt)
      ..writeByte(10)
      ..write(obj.statusHistory)
      ..writeByte(11)
      ..write(obj.isPaid)
      ..writeByte(12)
      ..write(obj.userName)
      ..writeByte(13)
      ..write(obj.userPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
