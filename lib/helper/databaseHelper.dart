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
    _database = await _initDB('cart.db');
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
        ruta TEXT,
        unidad TEXT,
        dateRecord DATETIME
        
      )
    ''');

    await db.execute('''
      CREATE TABLE concesionario_rutas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idestado int,
        estado TEXT,
        idmunicipio int,
        municipio TEXT,
        ruta TEXT,
        unidad TEXT,
        dateRecord DATETIME
        
      )
    ''');

    await db.execute('''
      CREATE TABLE checador (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idestado int,
        estado TEXT,
        idmunicipio int,
        municipio TEXT,
        ruta TEXT,
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
    required String ruta,
    required String unidad,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'location',
      where: 'idestado = ? and idmunicipio=? and ruta=? and unidad=? ',
      whereArgs: [idestado, idmunicipio, ruta, unidad],
    );

    if (existing.isEmpty) {
      await db.insert('location', {
        'idestado': idestado,
        'estado': estado,
        'idmunicipio': idmunicipio,
        'municipio': municipio,
        'ruta': ruta,
        'unidad': unidad,
        'dateRecord': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'location',
        {'dateRecord': DateTime.now().toIso8601String()},
        where: 'idestado = ? and idmunicipio=? and ruta=? and unidad=? ',
        whereArgs: [idestado, idmunicipio, ruta, unidad],
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

  Future<List<Map<String, dynamic>>> getRutasSaveInDatabase({
    required int estado,
    required int municipio,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'location',
      columns: ['ruta'],
      where: 'idestado = ? and idmunicipio=? ',
      whereArgs: [estado, municipio],
      distinct: true,
      orderBy: 'dateRecord DESC',
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getUnidadSaveInDatabase({
    required int estado,
    required int municipio,
    required String ruta,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'location',
      columns: ['unidad'],
      where: 'idestado = ? and idmunicipio=? and ruta=? ',
      whereArgs: [estado, municipio, ruta],
      orderBy: 'dateRecord DESC',
      distinct: true,
      groupBy: ' unidad ',
    );
    return result;
  }

  /*
      PROCESO PARA CONCESIONARIO
  */

  Future<void> insertRutaConcesionario({
    required int idestado,
    required String estado,
    required int idmunicipio,
    required String municipio,
    required String ruta,
    required String unidad,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'concesionario_rutas',
      where: 'idestado = ? and idmunicipio=? and ruta=? and unidad=? ',
      whereArgs: [idestado, idmunicipio, ruta, unidad],
    );

    if (existing.isEmpty) {
      await db.insert('concesionario_rutas', {
        'idestado': idestado,
        'estado': estado,
        'idmunicipio': idmunicipio,
        'municipio': municipio,
        'ruta': ruta,
        'unidad': unidad,
        'dateRecord': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'concesionario_rutas',
        {'dateRecord': DateTime.now().toIso8601String()},
        where: 'idestado = ? and idmunicipio=? and ruta=? and unidad=? ',
        whereArgs: [idestado, idmunicipio, ruta, unidad],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRutasConcesionarioSaveInDatabase({
    required int estado,
    required int municipio,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'concesionario_rutas',
      columns: ['ruta'],
      where: 'idestado = ? and idmunicipio=? ',
      whereArgs: [estado, municipio],
      distinct: true,
      orderBy: 'dateRecord DESC',
    );
    return result;
  }

  Future<Map<String, dynamic>?> getLastLocationConcesionario() async {
    final db = await instance.database;
    final result = await db.query(
      'concesionario_rutas',
      orderBy: 'dateRecord DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>?> getAllUnidadConcesionario() async {
    final db = await instance.database;
    final result = await db.query(
      'concesionario_rutas',
      orderBy: 'dateRecord DESC',
    );
    if (result.isNotEmpty) return result;
    return null;
  }

  Future<void> deleteUnidadConcesionario(
    int idestado,
    int idmunicipio,
    String ruta,
    String unidad,
  ) async {
    final db = await instance.database;
    await db.delete(
      'concesionario_rutas',
      where: 'idestado = ? and idmunicipio= ? and ruta = ?  and unidad= ? ',
      whereArgs: [idestado, idmunicipio, ruta, unidad],
    );
  }

  // PROCESO PARA CHECADOR

  Future<void> insertRutaChecador({
    required int idestado,
    required String estado,
    required int idmunicipio,
    required String municipio,
    required String ruta,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'checador',
      where: 'idestado = ? and idmunicipio=? and ruta=?  ',
      whereArgs: [idestado, idmunicipio, ruta],
    );

    if (existing.isEmpty) {
      await db.insert('checador', {
        'idestado': idestado,
        'estado': estado,
        'idmunicipio': idmunicipio,
        'municipio': municipio,
        'ruta': ruta,
        'dateRecord': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'checador',
        {'dateRecord': DateTime.now().toIso8601String()},
        where: 'idestado = ? and idmunicipio=? and ruta=? ',
        whereArgs: [idestado, idmunicipio, ruta],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRutasChecadorSaveInDatabase({
    required int estado,
    required int municipio,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'checador',
      columns: ['ruta'],
      where: 'idestado = ? and idmunicipio=? ',
      whereArgs: [estado, municipio],
      distinct: true,
      orderBy: 'dateRecord DESC',
    );
    return result;
  }

  Future<Map<String, dynamic>?> getLastLocationChecador() async {
    final db = await instance.database;
    final result = await db.query(
      'checador',
      orderBy: 'dateRecord DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
