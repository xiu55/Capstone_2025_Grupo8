CREATE DATABASE IF NOT EXISTS discoinventario
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE discoinventario;

-- =========================
-- 1. USUARIOS Y PROVEEDORES
-- =========================

CREATE TABLE usuarios (
  rut VARCHAR(12) NOT NULL,
  username VARCHAR(64) NOT NULL,
  email VARCHAR(120) DEFAULT NULL,
  telefono VARCHAR(32) DEFAULT NULL,
  password_hash VARCHAR(255) NOT NULL,
  requiere_cambio_password TINYINT(1) NOT NULL DEFAULT 0,
  nombre VARCHAR(120) NOT NULL,
  profesion VARCHAR(120) DEFAULT NULL,
  rol ENUM('BARRA','BODEGUERO','SUPERVISOR') NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  intentos_fallidos INT DEFAULT NULL,
  bloqueado_hasta DATETIME DEFAULT NULL,
  ultimo_acceso DATETIME DEFAULT NULL,
  reset_token VARCHAR(255) DEFAULT NULL,
  reset_expira DATETIME DEFAULT NULL,
  password_actualizado_en DATETIME DEFAULT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  foto MEDIUMBLOB DEFAULT NULL,
  foto_content_type VARCHAR(100) DEFAULT NULL,
  foto_nombre VARCHAR(255) DEFAULT NULL,
  foto_tamano BIGINT DEFAULT NULL,
  PRIMARY KEY (rut),
  UNIQUE KEY uk_usuarios_username (username),
  UNIQUE KEY uk_usuarios_email (email),
  KEY idx_usuarios_rol_activo_nombre (rol, activo, nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE proveedores (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rut VARCHAR(12) NOT NULL,
  razon_social VARCHAR(150) NOT NULL,
  giro VARCHAR(120) DEFAULT NULL,
  direccion VARCHAR(200) DEFAULT NULL,
  email VARCHAR(120) DEFAULT NULL,
  telefono VARCHAR(30) DEFAULT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_proveedores_rut (rut),
  KEY idx_proveedor_razon (razon_social),
  KEY idx_proveedor_activo (activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- 2. PRODUCTOS Y PRESENTACIONES
-- =========================

CREATE TABLE productos (
  id BIGINT NOT NULL AUTO_INCREMENT,
  codigo_barras VARCHAR(32) NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  marca VARCHAR(255) DEFAULT NULL,
  precio INT UNSIGNED DEFAULT NULL,
  precio_neto INT DEFAULT NULL,
  categoria VARCHAR(32) NOT NULL DEFAULT 'GENERAL',
  unidad_base ENUM('CAJA','KEG','LITRO','ML','PACK','PORCION','UN','UNIDAD') NOT NULL,
  volumen_nominal_ml INT DEFAULT NULL,
  graduacion_alcoholica DOUBLE DEFAULT NULL,
  perecible TINYINT(1) NOT NULL DEFAULT 0,
  retornable TINYINT(1) NOT NULL DEFAULT 0,
  stock_actual INT NOT NULL DEFAULT 0,
  stock_minimo INT DEFAULT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  version BIGINT NOT NULL DEFAULT 0,
  fecha_vencimiento DATE DEFAULT NULL,
  imagen_url VARCHAR(255) DEFAULT NULL,
  imagen_content_type VARCHAR(100) DEFAULT NULL,
  imagen_nombre VARCHAR(255) DEFAULT NULL,
  imagen_tamano BIGINT DEFAULT NULL,
  imagen LONGBLOB DEFAULT NULL,
  costo_neto INT NOT NULL,
  proveedor_id BIGINT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_productos_codigo_barras (codigo_barras),
  KEY idx_productos_nombre (nombre),
  KEY idx_productos_codigobarras (codigo_barras),
  KEY idx_productos_proveedor (proveedor_id),
  CONSTRAINT fk_productos_proveedor FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE presentaciones (
  id BIGINT NOT NULL AUTO_INCREMENT,
  producto_id BIGINT NOT NULL,
  nombre_presentacion VARCHAR(120) NOT NULL,
  tipo_presentacion ENUM('CAJA','KEG','PACK','PORCION','UNIDAD') NOT NULL,
  factorabase BIGINT NOT NULL,
  sku VARCHAR(50) DEFAULT NULL,
  ean VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_presentacion_unica (producto_id, nombre_presentacion),
  UNIQUE KEY uk_presentaciones_sku (sku),
  KEY idx_presentaciones_producto (producto_id),
  CONSTRAINT fk_presentaciones_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- 3. BITÁCORAS
-- =========================

CREATE TABLE bitacoras (
  id BIGINT NOT NULL AUTO_INCREMENT,
  fecha DATE NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_bitacora_fecha (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bitacora_detalles (
  id BIGINT NOT NULL AUTO_INCREMENT,
  maquina VARCHAR(200) NOT NULL,
  payload_json LONGTEXT DEFAULT NULL,
  bitacora_id BIGINT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_bitacora_maquina (bitacora_id, maquina),
  CONSTRAINT fk_bitacora_detalles_bitacora FOREIGN KEY (bitacora_id) REFERENCES bitacoras(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- 4. INGRESOS (CABECERA E ÍTEMS)
-- =========================

CREATE TABLE ingreso (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_doc ENUM('BOLETA','FACTURA','GUIA') NOT NULL,
  folio VARCHAR(20) NOT NULL,
  proveedor_rut VARCHAR(12) NOT NULL,
  proveedor_nombre VARCHAR(200) NOT NULL,
  fecha DATE NOT NULL,
  anio SMALLINT GENERATED ALWAYS AS (YEAR(fecha)) STORED,
  moneda VARCHAR(10) NOT NULL DEFAULT 'CLP',
  neto DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  iva DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  observaciones TEXT DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ingreso_unico (tipo_doc, proveedor_rut, folio, anio),
  KEY idx_ingreso_rut (proveedor_rut),
  KEY idx_ingreso_fecha (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ingresos_compra (
  id BIGINT NOT NULL AUTO_INCREMENT,
  tipo_doc VARCHAR(16) NOT NULL,
  folio VARCHAR(32) NOT NULL,
  fecha_doc DATE NOT NULL,
  rut_proveedor VARCHAR(20) NOT NULL,
  razon_proveedor VARCHAR(200) DEFAULT NULL,
  observaciones VARCHAR(500) DEFAULT NULL,
  estado VARCHAR(16) NOT NULL,
  neto INT NOT NULL,
  iva INT NOT NULL,
  total INT NOT NULL,
  creado_en DATETIME DEFAULT NULL,
  actualizado_en DATETIME DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_ingreso_doc (rut_proveedor, tipo_doc, folio, fecha_doc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ingreso_item (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ingreso_id BIGINT UNSIGNED NOT NULL,
  codigo VARCHAR(80) DEFAULT NULL,
  descripcion VARCHAR(300) NOT NULL,
  uom VARCHAR(20) NOT NULL DEFAULT 'UN',
  cantidad DECIMAL(14,3) NOT NULL,
  costo_unit DECIMAL(14,4) NOT NULL,
  descuento DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  KEY idx_item_ingreso (ingreso_id),
  CONSTRAINT fk_item_ingreso FOREIGN KEY (ingreso_id) REFERENCES ingreso(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- 5. MOVIMIENTOS (N:M ENTRE USUARIOS Y DOCUMENTOS)
-- =========================

CREATE TABLE movimientos (
  id BIGINT NOT NULL AUTO_INCREMENT,
  tipo VARCHAR(20) NOT NULL,
  motivo VARCHAR(120) DEFAULT NULL,
  referencia VARCHAR(120) DEFAULT NULL,
  usuario_rut VARCHAR(12) NOT NULL,
  ingreso_id BIGINT UNSIGNED DEFAULT NULL,
  ingreso_item_id BIGINT UNSIGNED DEFAULT NULL,
  ingreso_compra_id BIGINT DEFAULT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_movimientos_tipo (tipo),
  KEY idx_movimientos_creado_en (creado_en),
  KEY idx_movimientos_usuario (usuario_rut),
  KEY idx_movimientos_ingreso (ingreso_id),
  KEY idx_movimientos_ingreso_item (ingreso_item_id),
  KEY idx_movimientos_ingreso_compra (ingreso_compra_id),
  CONSTRAINT fk_movimientos_usuario FOREIGN KEY (usuario_rut) REFERENCES usuarios(rut),
  CONSTRAINT fk_movimientos_ingreso FOREIGN KEY (ingreso_id) REFERENCES ingreso(id),
  CONSTRAINT fk_movimientos_ingreso_item FOREIGN KEY (ingreso_item_id) REFERENCES ingreso_item(id),
  CONSTRAINT fk_movimientos_ingreso_compra FOREIGN KEY (ingreso_compra_id) REFERENCES ingresos_compra(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- 6. MOVIMIENTOS DE INVENTARIO
-- =========================

CREATE TABLE movimientos_inventario (
  id BIGINT NOT NULL AUTO_INCREMENT,
  actualizado_en DATETIME(6) DEFAULT NULL,
  comentario VARCHAR(255) DEFAULT NULL,
  creado_en DATETIME(6) DEFAULT NULL,
  fecha DATETIME(6) DEFAULT NULL,
  tipo ENUM('AJUSTE','ENTRADA','SALIDA') NOT NULL,
  referencia VARCHAR(128) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mi_referencia (referencia),
  KEY idx_mi_fecha (fecha),
  KEY idx_mi_tipo (tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE movimiento_lineas (
  id BIGINT NOT NULL AUTO_INCREMENT,
  movimiento_id BIGINT NOT NULL,
  producto_id BIGINT NOT NULL,
  cantidad INT NOT NULL,
  created_at DATETIME(6) DEFAULT NULL,
  updated_at DATETIME(6) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_ml_movimiento (movimiento_id),
  KEY idx_ml_producto (producto_id),
  CONSTRAINT fk_ml_movimiento FOREIGN KEY (movimiento_id) REFERENCES movimientos_inventario(id) ON DELETE CASCADE,
  CONSTRAINT fk_ml_producto FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;