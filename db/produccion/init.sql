-- Se ejecuta UNA sola vez, cuando el contenedor de PostgreSQL crea su
-- volumen de datos. Si el volumen ya existe, este archivo se ignora.
--
-- La imagen de postgres ya crea el usuario y la base principal a partir
-- de POSTGRES_USER, POSTGRES_PASSWORD y POSTGRES_DB. Aqui solo faltan
-- las tres que Rails 8 usa para cache, trabajos en segundo plano y
-- websockets.
CREATE DATABASE control_costos_production_cache OWNER control_costos;
CREATE DATABASE control_costos_production_queue OWNER control_costos;
CREATE DATABASE control_costos_production_cable OWNER control_costos;
