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
      isFeatured: fields[8] as bool,
      tags: (fields[9] as List).cast<String>(),
      metadata: (fields[10] as Map).cast<String, dynamic>(),
      difficulty: fields[11] as String?,
      estimatedTime: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModelAdapter obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.isFeatured)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.metadata)
      ..writeByte(11)
      ..write(obj.difficulty)
      ..writeByte(12)
      ..write(obj.estimatedTime);
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
