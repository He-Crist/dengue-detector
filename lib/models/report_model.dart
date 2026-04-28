class ReportModel {
  String id;
  String userId;
  String userName;
  String nombreReporte;
  String direccion;
  double latitud;
  double longitud;
  DateTime fecha;
  List<String> fotosUrls;
  List<String> tiposCriadero;        // ← CAMBIADO: ahora es LISTA
  String estadoCriadero;
  String personasAfectadas;
  String descripcion;
  String recomendacionesIA;
  String estado;
  String accionTomada;

  ReportModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.nombreReporte,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.fecha,
    required this.fotosUrls,
    required this.tiposCriadero,      // ← LISTA
    required this.estadoCriadero,
    required this.personasAfectadas,
    required this.descripcion,
    required this.recomendacionesIA,
    this.estado = 'pendiente',
    this.accionTomada = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'nombreReporte': nombreReporte,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'fecha': fecha.toIso8601String(),
      'fotosUrls': fotosUrls,
      'tiposCriadero': tiposCriadero,    // ← LISTA
      'estadoCriadero': estadoCriadero,
      'personasAfectadas': personasAfectadas,
      'descripcion': descripcion,
      'recomendacionesIA': recomendacionesIA,
      'estado': estado,
      'accionTomada': accionTomada,
    };
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> data) {
    return ReportModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      nombreReporte: data['nombreReporte'] ?? 'Sin titulo',
      direccion: data['direccion'] ?? '',
      latitud: data['latitud'] ?? 0.0,
      longitud: data['longitud'] ?? 0.0,
      fecha: data['fecha'] != null
          ? DateTime.parse(data['fecha'])
          : DateTime.now(),
      fotosUrls: List<String>.from(data['fotosUrls'] ?? []),
      tiposCriadero: List<String>.from(data['tiposCriadero'] ?? []),  // ← LISTA
      estadoCriadero: data['estadoCriadero'] ?? '',
      personasAfectadas: data['personasAfectadas'] ?? '',
      descripcion: data['descripcion'] ?? '',
      recomendacionesIA: data['recomendacionesIA'] ?? '',
      estado: data['estado'] ?? 'pendiente',
      accionTomada: data['accionTomada'] ?? '',
    );
  }
}