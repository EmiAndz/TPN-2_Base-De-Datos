
CREATE DATABASE movilidad_urbana CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE movilidad_urbana;

--  TABLAS
-- 1) Métodos de pago
CREATE TABLE metodos_pago ( 
  id_metodo_pago   INT AUTO_INCREMENT PRIMARY KEY,
  nombre_metodo    VARCHAR(20) NOT NULL,
  fecha_registro   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro  TINYINT     NOT NULL DEFAULT 1,
  CONSTRAINT ck_metodos_pago_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT ck_metodos_pago_valor
    CHECK (LOWER(nombre_metodo) IN ('mercado pago','efectivo','transferencia'))
) ENGINE=InnoDB;

-- 2) Tipos de servicio
CREATE TABLE tipos_servicio (
  id_tipo_servicio INT AUTO_INCREMENT PRIMARY KEY,
  nombre_servicio  ENUM('standard','premium','vip') NOT NULL,
  tarifa_base      DECIMAL(6,2) NOT NULL,
  fecha_registro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro  TINYINT  NOT NULL DEFAULT 1,
  CONSTRAINT ck_tipos_servicio_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT ck_tipos_servicio_tarifa CHECK (tarifa_base >= 0),
  CONSTRAINT uq_tipos_servicio_nombre UNIQUE (nombre_servicio)
) ENGINE=InnoDB;

-- 3) Motivos de cancelación
CREATE TABLE cancelaciones (
  id_cancelacion  INT AUTO_INCREMENT PRIMARY KEY,
  descripcion     VARCHAR(100) NOT NULL,
  fecha_registro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro TINYINT  NOT NULL DEFAULT 1,
  CONSTRAINT ck_cancelaciones_estado CHECK (estado_registro IN (0,1))
) ENGINE=InnoDB;

-- =========================================================
--  ENTIDADES PRINCIPALES
-- =========================================================

-- 4) Pasajeros
CREATE TABLE pasajeros (
  id_pasajero      INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(30)  NOT NULL,
  apellido         VARCHAR(30)  NOT NULL,
  email            VARCHAR(60)  NOT NULL,
  telefono         VARCHAR(20)  NOT NULL,
  fecha_nacimiento DATE         NULL,
  fecha_registro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro  TINYINT      NOT NULL DEFAULT 1,
  CONSTRAINT ck_pasajeros_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT uq_pasajeros_email  UNIQUE (email)
) ENGINE=InnoDB;

-- 5) Conductores
CREATE TABLE conductores (
  id_conductor      INT AUTO_INCREMENT PRIMARY KEY,
  nombre            VARCHAR(30)  NOT NULL,
  apellido          VARCHAR(30)  NOT NULL,
  email             VARCHAR(60)  NOT NULL,
  telefono          VARCHAR(20)  NOT NULL,
  fecha_nacimiento  DATE         NULL,
  licencia_conducir VARCHAR(50)  NOT NULL,
  fecha_registro    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro   TINYINT      NOT NULL DEFAULT 1,
  CONSTRAINT ck_conductores_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT uq_conductores_email     UNIQUE (email),
  CONSTRAINT uq_conductores_licencia  UNIQUE (licencia_conducir)
) ENGINE=InnoDB;

-- 6) Vehículos
CREATE TABLE vehiculos (
  id_vehiculo       INT AUTO_INCREMENT PRIMARY KEY,
  patente           VARCHAR(10) NOT NULL,
  marca             VARCHAR(25) NOT NULL,
  modelo            VARCHAR(25) NOT NULL,
  anio              YEAR        NOT NULL,
  seguro            VARCHAR(40) NOT NULL,
  id_conductor      INT         NOT NULL,
  id_tipo_servicio  INT         NOT NULL,
  fecha_registro    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro   TINYINT     NOT NULL DEFAULT 1,
  CONSTRAINT ck_vehiculos_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT uq_vehiculos_patente UNIQUE (patente),
  CONSTRAINT fk_vehiculos_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductores(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_vehiculos_tipo_servicio
    FOREIGN KEY (id_tipo_servicio) REFERENCES tipos_servicio(id_tipo_servicio)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================================================
--  ENTIDAD CENTRAL: VIAJES
-- =========================================================

-- 7) Viajes (relaciona pasajero, conductor, vehículo, método de pago y motivo de cancelación)
CREATE TABLE viajes (
  id_viaje         INT AUTO_INCREMENT PRIMARY KEY,
  fecha            DATE        NOT NULL,
  hora             TIME        NOT NULL,
  duracion_viaje   INT         NOT NULL,                         -- en minutos
  tarifa           DECIMAL(10,2) NOT NULL,
  origen           VARCHAR(100) NOT NULL,
  destino          VARCHAR(100) NOT NULL,
  estado_viaje     ENUM('solicitado','en_curso','completado','cancelado') NOT NULL,
  id_pasajero      INT         NOT NULL,
  id_conductor     INT         NOT NULL,
  id_vehiculo      INT         NOT NULL,
  id_metodo_pago   INT         NOT NULL,
  id_cancelacion   INT         NULL,
  fecha_registro   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro  TINYINT     NOT NULL DEFAULT 1,
  CONSTRAINT ck_viajes_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT ck_viajes_tarifa CHECK (tarifa >= 0),
  CONSTRAINT ck_viajes_duracion CHECK (duracion_viaje >= 0),
  CONSTRAINT fk_viajes_pasajero
    FOREIGN KEY (id_pasajero) REFERENCES pasajeros(id_pasajero)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_viajes_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductores(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_viajes_vehiculo
    FOREIGN KEY (id_vehiculo) REFERENCES vehiculos(id_vehiculo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_viajes_metodo_pago
    FOREIGN KEY (id_metodo_pago) REFERENCES metodos_pago(id_metodo_pago)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_viajes_cancelacion
    FOREIGN KEY (id_cancelacion) REFERENCES cancelaciones(id_cancelacion)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


--  ENTIDADES DÉBILES (dependen de VIAJES)

-- 8) Paradas intermedias (PK compuesta para relación identificante)
CREATE TABLE paradas_intermedias (
  id_viaje        INT      NOT NULL,
  orden           INT      NOT NULL,               -- 1,2,3...
  direccion_parada VARCHAR(120) NOT NULL,
  fecha_alta      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro TINYINT  NOT NULL DEFAULT 1,
  CONSTRAINT pk_paradas PRIMARY KEY (id_viaje, orden),
  CONSTRAINT ck_paradas_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT fk_paradas_viaje
    FOREIGN KEY (id_viaje) REFERENCES viajes(id_viaje)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9) Evaluaciones (una del pasajero al conductor y otra del conductor al pasajero)
CREATE TABLE evaluaciones (
  id_evaluacion     INT AUTO_INCREMENT PRIMARY KEY,
  id_viaje          INT      NOT NULL,
  id_conductor      INT      NOT NULL,   
  id_pasajero       INT      NOT NULL,  
  calificacion_numerica TINYINT NOT NULL,
  descripcion       TEXT     NULL,
  fecha_registro    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_registro   TINYINT  NOT NULL DEFAULT 1,
  CONSTRAINT ck_eval_estado CHECK (estado_registro IN (0,1)),
  CONSTRAINT ck_eval_rango  CHECK (calificacion_numerica BETWEEN 1 AND 5),
  CONSTRAINT uq_eval_unica UNIQUE (id_viaje, id_pasajero, id_conductor),
  CONSTRAINT fk_eval_viaje
    FOREIGN KEY (id_viaje) REFERENCES viajes(id_viaje)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_eval_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductores(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eval_pasajero
    FOREIGN KEY (id_pasajero) REFERENCES pasajeros(id_pasajero)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================================================
--  ÍNDICES ÚTILES (ayudan a las consultas del TP)
--  (Los FKs ya crean índices, agregamos algunos adicionales)
-- =========================================================
CREATE INDEX ix_viajes_fecha               ON viajes (fecha, hora);
CREATE INDEX ix_viajes_estado              ON viajes (estado_viaje);
CREATE INDEX ix_viajes_pasajero_fecha      ON viajes (id_pasajero, fecha);
CREATE INDEX ix_viajes_conductor_fecha     ON viajes (id_conductor, fecha);
CREATE INDEX ix_evaluaciones_calificacion  ON evaluaciones (calificacion_numerica);
