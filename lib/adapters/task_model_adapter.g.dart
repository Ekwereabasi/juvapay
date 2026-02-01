// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapterAdapter extends TypeAdapter<TaskModelAdapter> {
  @override
  final int typeId = 1;

  @override
  TaskModelAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModelAdapter(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      category: fields[2] as String,
      title: fields[3] as String,
      price: fields[4] as double,
      description: fields[5] as String,
      platforms: (fields[6] as List).cast<String>(),
      iconKey: fields[7] as String,
      difficulty: fields[8] as String,
      estimatedTime: fields[9] as int?,
      status: fields[10] as String,
      sortOrder: fields[11] as int,
      isFeatured: fields[12] as bool,
      tags: (fields[13] as List).cast<String>(),
      metadata: (fields[14] as Map).cast<String, dynamic>(),
      version: fields[15] as int,
      minQuantity: fields[16] as int,
      maxQuantity: fields[17] as int,
      requirements: (fields[18] as List).cast<dynamic>(),
      instructions: (fields[19] as List).cast<dynamic>(),
      commissionRate: fields[20] as double,
      workerPayoutRate: fields[21] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModelAdapter obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.platforms)
      ..writeByte(7)
      ..write(obj.iconKey)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(9)
      ..write(obj.estimatedTime)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.sortOrder)
      ..writeByte(12)
      ..write(obj.isFeatured)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.metadata)
      ..writeByte(15)
      ..write(obj.version)
      ..writeByte(16)
      ..write(obj.minQuantity)
      ..writeByte(17)
      ..write(obj.maxQuantity)
      ..writeByte(18)
      ..write(obj.requirements)
      ..writeByte(19)
      ..write(obj.instructions)
      ..writeByte(20)
      ..write(obj.commissionRate)
      ..writeByte(21)
      ..write(obj.workerPayoutRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
