// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConnectionProfileHiveAdapter extends TypeAdapter<ConnectionProfileHive> {
  @override
  final int typeId = 0;

  @override
  ConnectionProfileHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConnectionProfileHive(
      id: fields[0] as String,
      name: fields[1] as String,
      baseUrl: fields[2] as String,
      username: fields[3] as String,
      rememberMe: fields[4] as bool,
      hasSavedPassword: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ConnectionProfileHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.baseUrl)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.rememberMe)
      ..writeByte(5)
      ..write(obj.hasSavedPassword);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionProfileHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalProjectHiveAdapter extends TypeAdapter<LocalProjectHive> {
  @override
  final int typeId = 1;

  @override
  LocalProjectHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalProjectHive(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalProjectHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalProjectHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalColumnHiveAdapter extends TypeAdapter<LocalColumnHive> {
  @override
  final int typeId = 2;

  @override
  LocalColumnHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalColumnHive(
      id: fields[0] as String,
      projectId: fields[1] as String,
      title: fields[2] as String,
      position: fields[3] as int,
      taskLimit: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LocalColumnHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.position)
      ..writeByte(4)
      ..write(obj.taskLimit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalColumnHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalTaskHiveAdapter extends TypeAdapter<LocalTaskHive> {
  @override
  final int typeId = 3;

  @override
  LocalTaskHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalTaskHive(
      id: fields[0] as String,
      projectId: fields[1] as String,
      columnId: fields[2] as String,
      swimlaneId: fields[3] as String,
      title: fields[4] as String,
      description: fields[5] as String,
      position: fields[6] as int,
      colorId: fields[7] as String,
      dateDue: fields[8] as DateTime?,
      ownerId: fields[9] as String?,
      priority: fields[10] as int,
      dateCreation: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalTaskHive obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.columnId)
      ..writeByte(3)
      ..write(obj.swimlaneId)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.position)
      ..writeByte(7)
      ..write(obj.colorId)
      ..writeByte(8)
      ..write(obj.dateDue)
      ..writeByte(9)
      ..write(obj.ownerId)
      ..writeByte(10)
      ..write(obj.priority)
      ..writeByte(11)
      ..write(obj.dateCreation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTaskHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalSubtaskHiveAdapter extends TypeAdapter<LocalSubtaskHive> {
  @override
  final int typeId = 5;

  @override
  LocalSubtaskHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSubtaskHive(
      id: fields[0] as String,
      taskId: fields[1] as String,
      title: fields[2] as String,
      status: fields[3] as int,
      position: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSubtaskHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.position);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSubtaskHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalCommentHiveAdapter extends TypeAdapter<LocalCommentHive> {
  @override
  final int typeId = 6;

  @override
  LocalCommentHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalCommentHive(
      id: fields[0] as String,
      taskId: fields[1] as String,
      content: fields[2] as String,
      dateCreation: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocalCommentHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.dateCreation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalCommentHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalExternalLinkHiveAdapter extends TypeAdapter<LocalExternalLinkHive> {
  @override
  final int typeId = 7;

  @override
  LocalExternalLinkHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalExternalLinkHive(
      id: fields[0] as String,
      taskId: fields[1] as String,
      title: fields[2] as String,
      url: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalExternalLinkHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.url);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalExternalLinkHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalAttachmentHiveAdapter extends TypeAdapter<LocalAttachmentHive> {
  @override
  final int typeId = 8;

  @override
  LocalAttachmentHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalAttachmentHive(
      id: fields[0] as String,
      taskId: fields[1] as String,
      name: fields[2] as String,
      isImage: fields[3] as bool,
      date: fields[4] as DateTime,
      base64Blob: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalAttachmentHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.isImage)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.base64Blob);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAttachmentHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedProviderDataHiveAdapter
    extends TypeAdapter<CachedProviderDataHive> {
  @override
  final int typeId = 4;

  @override
  CachedProviderDataHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProviderDataHive(
      profileId: fields[0] as String,
      projects: (fields[1] as List)
          .map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          .toList(),
      lastSyncedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProviderDataHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.projects)
      ..writeByte(2)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProviderDataHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
