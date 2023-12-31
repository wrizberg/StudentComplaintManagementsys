import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

import 'crud_exceptions.dart';

class ComplaintsService {
  Database? _db;

  List<DatabaseComplaints> _complaints = [];

  static final ComplaintsService _shared = ComplaintsService._sharedInstance();
  ComplaintsService._sharedInstance();
  factory ComplaintsService() => _shared;

  final _complaintsStreamController =
      StreamController<List<DatabaseComplaints>>.broadcast();

  Stream<List<DatabaseComplaints>> get allComplaints =>
      _complaintsStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheComplaints() async {
    final allComplaints = await getAllComplaints();
    _complaints = allComplaints.toList();
    _complaintsStreamController.add(_complaints);
  }

  Future<DatabaseComplaints> updateComplaints(
      {required DatabaseComplaints complaints, required String text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    await getComplaints(id: complaints.id);
    final updatesCount = await db.update(complaintTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });
    if (updatesCount == 0) {
      throw CouldNotUpdateComplaint();
    } else {
      final updatedComplaint = await getComplaints(id: complaints.id);
      _complaints
          .removeWhere((complaint) => complaint.id == updatedComplaint.id);
      _complaints.add(updatedComplaint);
      _complaintsStreamController.add(_complaints);
      return updatedComplaint;
    }
  }

  Future<Iterable<DatabaseComplaints>> getAllComplaints() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final complaints = await db.query(complaintTable);

    return complaints
        .map((complaintRow) => DatabaseComplaints.fromRow(complaintRow));
  }

  Future<DatabaseComplaints> getComplaints({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final complaints = await db.query(
      complaintTable,
      limit: 1,
      where: 'id=?',
      whereArgs: [id],
    );
    if (complaints.isEmpty) {
      throw CouldNotFindComplaint();
    } else {
      final complaint = DatabaseComplaints.fromRow(complaints.first);
      _complaints.removeWhere((complaints) => complaints.id == id);
      _complaints.add(complaint);
      _complaintsStreamController.add(_complaints);
      return complaint;
    }
  }

  Future<int> deleteAllComplaints() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(complaintTable);
    _complaints = [];
    _complaintsStreamController.add(_complaints);
    return numberOfDeletions;
  }

  Future<void> deleteComplaint({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      complaintTable,
      where: 'id=?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteComplaint();
    } else {
      _complaints.removeWhere((complaint) => complaint.id == id);
      _complaintsStreamController.add(_complaints);
    }
  }

  Future<DatabaseComplaints> createComplaint(
      {required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }
    const text = '';
    // create table
    final complaintId = await db.insert(complaintTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final complaint = DatabaseComplaints(
      id: complaintId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );
    _complaints.add(complaint);
    _complaintsStreamController.add(_complaints);

    return complaint;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
//empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
// create user table
      await db.execute(createUserTable);
// create complaint table
      await db.execute(createComplaintTable);
      await _cacheComplaints();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID= $id ,email=$email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseComplaints {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseComplaints({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseComplaints.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Complaint, ID=$id, userId=$userId, isSyncedWithCloud=$isSyncedWithCloud, text=$text';

  @override
  bool operator ==(covariant DatabaseComplaints other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'complaints.db';
const complaintTable = 'complaint';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
	"id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);''';

const createComplaintTable = '''CREATE TABLE  IF NOT EXISTS "complaint" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT,
	"is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("user_id") REFERENCES "user"("id")
);''';
