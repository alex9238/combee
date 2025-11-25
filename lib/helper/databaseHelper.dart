import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('combee.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE location (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idestado int,
        estado TEXT,
        idmunicipio int,
        municipio TEXT,
        dateRecord DATETIME
        
      )
    ''');

    await db.execute('''
      CREATE TABLE rutas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idestado int,
        estado TEXT,
        idmunicipio int,
        municipio TEXT,
        idruta INT,
        ruta TEXT,
        wms TEXT,
        dateRecord DATETIME
        
      )
    ''');
  }

  /*
      PROCESO PARA RUTAS TRACKING
  */

  Future<void> clearLocations() async {
    final db = await instance.database;
    await db.delete('location');
  }

  Future<void> insertLocation({
    required int idestado,
    required String estado,
    required int idmunicipio,
    required String municipio,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'location',
      where: 'idestado = ? and idmunicipio=?  ',
      whereArgs: [idestado, idmunicipio],
    );

    if (existing.isEmpty) {
      await db.insert('location', {
        'idestado': idestado,
        'estado': estado,
        'idmunicipio': idmunicipio,
        'municipio': municipio,
        'dateRecord': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'location',
        {'dateRecord': DateTime.now().toIso8601String()},
        where: 'idestado = ? and idmunicipio=?  ',
        whereArgs: [idestado, idmunicipio],
      );
    }
  }

  Future<Map<String, dynamic>?> getLastLocation() async {
    final db = await instance.database;
    final result = await db.query(
      'location',
      orderBy: 'dateRecord DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /*
      PROCESO PARA RUTAS 
  */

  Future<void> clearRutas() async {
    final db = await instance.database;
    await db.delete('rutas');
  }

  Future<void> insertRutas({
    required int idestado,
    required String estado,
    required int idmunicipio,
    required String municipio,
    required int idruta,
    required String ruta,
    required String wms,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'rutas',
      where: 'idestado = ? and idmunicipio=? and ruta=? and idruta=? ',
      whereArgs: [idestado, idmunicipio, ruta, idruta],
    );

    if (existing.isEmpty) {
      await db.insert('rutas', {
        'idestado': idestado,
        'estado': estado,
        'idmunicipio': idmunicipio,
        'municipio': municipio,
        'idruta': idruta,
        'ruta': ruta,
        'wms': wms,
        'dateRecord': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'rutas',
        {'dateRecord': DateTime.now().toIso8601String()},
        where: 'idestado = ? and idmunicipio=? and ruta=? and idruta=?  ',
        whereArgs: [idestado, idmunicipio, ruta, idruta],
      );
    }
  }

  Future<Map<String, dynamic>?> getLastRuta() async {
    final db = await instance.database;
    final result = await db.query(
      'rutas',
      orderBy: 'dateRecord DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getRutasSaveInDatabase() async {
    final db = await instance.database;
    final result = await db.query(
      'rutas',
      distinct: true,
      orderBy: 'dateRecord DESC',
    );
    return result;
  }

  Future<void> deleteRuta(int estado, int municipio, String ruta) async {
    final db = await instance.database;
    await db.delete(
      'rutas',
      where: 'idestado = ? and idmunicipio=? and ruta=? ',
      whereArgs: [estado, municipio, ruta],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
