-- FreshBox EP3 - esquema base y datos de demostracion.
-- Idempotente: se ejecuta en cada despliegue mediante un Job de Kubernetes.

CREATE TABLE IF NOT EXISTS productos (
  id INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  descripcion TEXT NULL,
  precio DECIMAL(10, 2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  categoria VARCHAR(60) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_productos_categoria (categoria)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ordenes (
  id INT NOT NULL AUTO_INCREMENT,
  user_id VARCHAR(120) NOT NULL,
  total DECIMAL(12, 2) NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'procesado',
  items JSON NOT NULL,
  processed_at DATETIME NOT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ordenes_user_id (user_id),
  KEY idx_ordenes_creado_en (creado_en)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

INSERT IGNORE INTO productos (id, nombre, descripcion, precio, stock, categoria) VALUES
  (1, 'Manzana organica', 'Manzana roja organica por unidad', 990.00, 80, 'Frutas'),
  (2, 'Palta Hass', 'Palta Hass madura por unidad', 1490.00, 50, 'Frutas'),
  (3, 'Leche de almendras', 'Bebida vegetal sin azucar 1 L', 2590.00, 30, 'Lacteos vegetales'),
  (4, 'Avena integral', 'Avena integral en hojuelas 500 g', 1990.00, 40, 'Cereales'),
  (5, 'Huevos libres de jaula', 'Bandeja de 12 huevos', 3490.00, 25, 'Proteinas'),
  (6, 'Miel de abeja', 'Miel natural 250 g', 4290.00, 20, 'Endulzantes');
