-- Consultas que aprovechan los índices propuestos
-- Obtener viajes de una fecha específica ordenados por hora
SELECT id_viaje, id_pasajero, id_conductor, origen, destino, hora
FROM viajes
WHERE fecha = '2025-10-03'
ORDER BY hora;

-- Contar viajes cancelados en los últimos 30 días
SELECT
    COUNT(*) AS cancelados_30d
FROM viajes
WHERE estado_viaje = 'cancelado'
    AND fecha >= CURDATE() - INTERVAL 30 DAY;

-- Obtener últimos 10 viajes de un pasajero específico
SELECT id_viaje, fecha, hora, origen, destino, estado_viaje
FROM viajes
WHERE id_pasajero = 7
ORDER BY fecha DESC, hora DESC
LIMIT 10;

-- Estadísticas de viajes de un conductor en un mes
SELECT
    COUNT(*)                                         AS total,
    SUM(estado_viaje = 'completado')                 AS completados,
    SUM(estado_viaje = 'cancelado')                  AS cancelados,
    ROUND(AVG(CASE WHEN estado_viaje='completado' THEN duracion_viaje END),1) AS duracion_prom
FROM viajes
WHERE id_conductor = 12
    AND fecha BETWEEN '2025-10-01' AND '2025-10-31';

-- Distribución de calificaciones numéricas
SELECT calificacion_numerica, COUNT(*) AS cantidad
FROM evaluaciones
GROUP BY calificacion_numerica
ORDER BY calificacion_numerica;

-- Consultas que ayudan a comprobar la correcta funcion del sistema

-- 1. Listar todos los viajes con nombre del pasajero, nombre del conductor y método de pago
SELECT v.id_viaje, p.nombre AS pasajero, c.nombre AS conductor, m.nombre_metodo, v.origen, v.destino, v.estado_viaje
FROM Viajes v
JOIN Pasajeros p ON v.id_pasajero = p.id_pasajero
JOIN Conductores c ON v.id_conductor = c.id_conductor
JOIN Metodos_Pago m ON v.id_metodo_pago = m.id_metodo_pago;

-- 2. Mostrar las evaluaciones con datos del viaje, pasajero y conductor
SELECT e.id_evaluacion, e.calificacion_numerica, e.descripcion, v.origen, v.destino, p.nombre AS pasajero, c.nombre AS conductor
FROM Evaluaciones e
JOIN Viajes v ON e.id_viaje = v.id_viaje
JOIN Pasajeros p ON e.id_pasajero = p.id_pasajero
JOIN Conductores c ON e.id_conductor = c.id_conductor;

-- 3. Listar viajes cancelados con motivo de cancelación y datos del pasajero
SELECT v.id_viaje, p.nombre AS pasajero, v.estado_viaje, can.descripcion AS motivo_cancelacion
FROM Viajes v
JOIN Pasajeros p ON v.id_pasajero = p.id_pasajero
JOIN Cancelaciones can ON v.id_cancelacion = can.id_cancelacion
WHERE v.estado_viaje = 'Cancelado';

-- 4. Cantidad de viajes realizados por cada pasajero en octubre del 01 al 10 de 2025
SELECT p.nombre, p.apellido, COUNT(v.id_viaje) AS total_viajes
FROM Pasajeros p
JOIN Viajes v ON p.id_pasajero = v.id_pasajero
WHERE v.fecha BETWEEN '2025-10-01' AND '2025-10-10'
GROUP BY p.id_pasajero;

-- 5. Conductores con promedio de calificación mayor a 4
SELECT c.nombre, c.apellido, AVG(e.calificacion_numerica) AS promedio
FROM Conductores c
JOIN Evaluaciones e ON c.id_conductor = e.id_conductor
GROUP BY c.id_conductor
HAVING AVG(e.calificacion_numerica) > 4;

-- 6. Pasajeros que nunca cancelaron un viaje (subconsulta NOT IN)
SELECT p.nombre, p.apellido
FROM Pasajeros p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Viajes v 
    WHERE v.id_pasajero = p.id_pasajero 
    AND v.estado_viaje = 'Cancelado'
);

-- 7. Total de viajes y recaudación por tipo de servicio
SELECT ts.nombre_servicio, COUNT(v.id_viaje) AS total_viajes, SUM(v.tarifa) AS recaudacion
FROM Tipos_Servicio ts
JOIN Vehiculos ve ON ts.id_tipo_servicio = ve.id_tipo_servicio
JOIN Viajes v ON ve.id_conductor = v.id_conductor
GROUP BY ts.id_tipo_servicio;

-- 8. Conductores que no recibieron evaluaciones con calificación menor a 3
SELECT c.nombre, c.apellido
FROM Conductores c
WHERE c.id_conductor NOT IN (
	SELECT e.id_conductor FROM Evaluaciones e WHERE e.calificacion_numerica < 3
);

-- 9. Top 10 motivos de cancelación más frecuentes con porcentaje
SELECT
  c.descripcion,
  COUNT(*) AS cant,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM viajes v
JOIN cancelaciones c ON c.id_cancelacion = v.id_cancelacion
WHERE v.estado_viaje = 'cancelado'
GROUP BY c.descripcion
ORDER BY cant DESC
LIMIT 10;

-- 10. Viajes con más de 1 parada intermedia
SELECT
  v.id_viaje,
  v.origen, v.destino,
  COUNT(pi.orden) AS paradas
FROM viajes v
JOIN paradas_intermedias pi ON pi.id_viaje = v.id_viaje
GROUP BY v.id_viaje
HAVING COUNT(pi.orden) > 1
ORDER BY paradas DESC, v.id_viaje;

-- Vista: rendimiento de conductores y satisfacción promedio
CREATE OR REPLACE VIEW vw_rendimiento_conductores AS
SELECT
  c.id_conductor,
  CONCAT(c.nombre, ' ', c.apellido) AS conductor,
  COUNT(v.id_viaje) AS total_viajes,
  SUM(v.tarifa) AS total_recaudado,
  ROUND(AVG(e.calificacion_numerica), 2) AS calificacion_promedio,
  SUM(v.estado_viaje = 'cancelado') AS viajes_cancelados
FROM conductores c
LEFT JOIN viajes v ON v.id_conductor = c.id_conductor
LEFT JOIN evaluaciones e ON e.id_viaje = v.id_viaje
GROUP BY c.id_conductor;

-- Consulta de ejemplo

SELECT * FROM vw_rendimiento_conductores ORDER BY calificacion_promedio DESC;
