-- Equipo 1: Tinder para Viejos Egresados (RobbleAffinity)
-- Integrantes: Ana Shek, 19-10096
-- 				Jhonaiker Blanco, 18-10784
--				Junior Lara, 17-10303
--				Laura Parilli, 17-10778
-- DDL_v2.0_Funcional.sql Archivo de creacion de tablas y funciones para la BD de Tinder para Viejos Egresados.

-- IMPORTANTE!! Ejecutar esto primero.
CREATE EXTENSION postgis;
-- Si no tenes postgis ve https://geoinnova.org/blog-territorio/como-instalar-postgis-3-0-en-windows/

-- Luego ejecutar esto por separado.
SET search_path TO tinder_viejos_egresados, public;
SET DATESTYLE TO 'European';

CREATE DOMAIN tiers AS VARCHAR(16)
	CONSTRAINT tiers_validos CHECK (VALUE IN ('Plus', 'Gold', 'Platinum', 'Otro'));

CREATE DOMAIN sexos AS VARCHAR(4)
	CONSTRAINT sexos_validos CHECK (VALUE IN ('M', 'F', 'Otro'));

CREATE DOMAIN orientaciones AS VARCHAR(16)
	CONSTRAINT orientaciones_validas CHECK (VALUE IN ('Heterosexual', 'Gay', 'Lesbiana', 'Bisexual', 'Asexual', 'Demisexual', 'Pansexual', 'Queer', 'Cuestionamiento', 'Buscando Chamba', 'Otro'));

CREATE DOMAIN estudios AS VARCHAR(16)
	CONSTRAINT estudios_validos CHECK (VALUE IN ('Maestria', 'Master', 'Especializacion', 'Diplomado', 'Doctorado', 'Otro'));

CREATE DOMAIN tipo_instituciones AS VARCHAR(16)
	CONSTRAINT tipo_instituciones_validos CHECK (VALUE IN ('Politica', 'Economica', 'Juridica', 'Laboral', 'Cientifica', 'Universitaria', 'Artistica', 'Otro'));

CREATE DOMAIN metodo_pago AS VARCHAR(16)
	CONSTRAINT metodo_pago_validos CHECK (VALUE IN ('Tarjeta', 'Paypal', 'Crypto', 'Otro'));

CREATE DOMAIN tipo_tarjeta AS VARCHAR(16)
	CONSTRAINT tipo_tarjeta_validos CHECK (VALUE IN ('Credito', 'Debito'));

CREATE DOMAIN idiomas_app AS CHAR(3)
	CONSTRAINT idiomas_app_disponibles CHECK (VALUE IN ('ENG', 'ESP'));

CREATE DOMAIN hobbies AS VARCHAR(64)
	CONSTRAINT hobbies_validos CHECK (VALUE IN ('Estudiar', 'Programar', 'Leer libros', 'Futbol', 'Escalar', 'Pescar', 'Fotografias',
	'Trabajar como voluntario', 'Comedia', 'Cafe', 'Comer', 'Disney', 'Amante de los animales', 'Amante de los gatos', 
	'Amante de los perros', 'Caminar', 'Cocinar', 'Al aire libre', 'Baile', 'Picnic', 'Juegos de mesa', 'Cantar',
	'Compras', 'Hacer ejercicios', 'Deportes', 'Hornear', 'Jardineria', 'Lectura', 'Jugar videojuegos', 'Peliculas', 
	'Arte', 'Blogs', 'Yoga', 'Correr', 'Golf', 'Espiritualidad', 'Tomar una copa', 'Viajar', 'Nadar', 'Manualidades', 'Senderismo',
	'Astrologia', 'Redes sociales', 'Musica', 'Museo', 'Vino', 'Gastronomia', 'Escribir', 'Intercambio de idiomas', 'Vlogging', 
	'Naturaleza', 'Netflix', 'Kpop', 'Surf', 'Ciclismo', 'Moda', 'Atleta', 'Politica', 
	'Matematicas', 'Fisica', 'Cerveza artesanal', 'Ver series', 'Dormir', 'Voleibol', 'Fracasar', 'Valer v***a', 'Chismear',
	'Quejarse', 'Jugar Dominio y tomar anicito', 'Sacar los pasos prohibidos', 'Clavar es mi pasion', 'Hacer porritos', 
	'Hablar como Dominicano', 'Hablar con otros acentos', 'Otro'));

CREATE DOMAIN habilidades AS VARCHAR(64)
	CONSTRAINT habilidades_validas CHECK (VALUE IN ('Analítica', 'Artística', 'Atención al detalle', 'Autodisciplina', 
	'Capacidad de aprendizaje', 'Capacidad de enseñanza', 'Capacidad de escucha', 'Capacidad de negociación', 
	'Capacidad de organización', 'Capacidad de persuasión', 'Capacidad de planificación', 'Capacidad de toma de decisiones',
	'Capacidad para trabajar bajo presión', 'Creatividad', 'Empatía', 'Energía', 'Flexibilidad', 'Habilidades de comunicación',
	'Habilidades de liderazgo', 'Habilidades de venta', 'Habilidades interpersonales', 'Habilidades matemáticas', 
	'Habilidades técnicas', 'Iniciativa', 'Inteligencia emocional', 'Motivación', 'Paciencia', 'Perseverancia', 
	'Resiliencia', 'Visión estratégica', 'Chambeo', 'Procrastinacion productiva', 'Buenisimo en Memardos', 'Llorando pero pa'' lante', 
	'Canta y no llores', 'Otro'));

-- Funcion para importar archivos a la base de datos.
-- Su uso es el siguiente: insert into my_table(bytea_data) select bytea_import('/my/file.name');
-- https://dba.stackexchange.com/questions/1742/how-to-insert-file-data-into-a-postgresql-bytea-column
CREATE OR REPLACE FUNCTION bytea_import(p_path TEXT, p_result OUT BYTEA) LANGUAGE plpgsql AS $$
DECLARE
	l_oid OID;
BEGIN
	SELECT lo_import(p_path) INTO l_oid;
	SELECT lo_get(l_oid) INTO p_result;
	perform lo_unlink(l_oid);
END;$$;

CREATE TABLE IF NOT EXISTS cuenta(
	id_cuenta INT GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR(32) NOT NULL,
	apellido VARCHAR(32) NOT NULL,
	fecha_nacimiento DATE NOT NULL CHECK (EXTRACT(YEAR FROM fecha_nacimiento) > 1900),
	fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
	email VARCHAR(256) UNIQUE NOT NULL,
	contrasena VARCHAR(128) NOT NULL,
	telefono VARCHAR(16) UNIQUE NOT NULL,
	idioma idiomas_app DEFAULT 'ESP' NOT NULL,
	notificaciones BOOLEAN DEFAULT TRUE NOT NULL, 
	tema BOOLEAN DEFAULT TRUE NOT NULL,
	PRIMARY KEY (id_cuenta)
);

CREATE TABLE IF NOT EXISTS pago(
	id_pago INT GENERATED ALWAYS AS IDENTITY,
	numero_factura INT NOT NULL,
	estado BOOLEAN NOT NULL,
	metodo metodo_pago NOT NULL,
	monto DECIMAL(10,2) DEFAULT 0 NOT NULL,
	fecha DATE NOT NULL DEFAULT CURRENT_DATE, 
	documento_factura BYTEA NOT NULL,
 PRIMARY KEY (id_pago)
);

CREATE TABLE IF NOT EXISTS tarjeta (
	digitos_tarjeta VARCHAR(19) CHECK (digitos_tarjeta ~ '^[0-9]{16,19}$'),
	nombre_titular VARCHAR(65) NOT NULL,
	fecha_caducidad DATE NOT NULL,
	codigo_cv VARCHAR(4) CHECK (codigo_cv ~ '^[0-9]{3,4}$'),
	tipo tipo_tarjeta NOT NULL,
	PRIMARY KEY(digitos_tarjeta)
);

CREATE TABLE IF NOT EXISTS realiza(
	id_cuenta INT NOT NULL,
	id_pago INT,
	digitos_tarjeta VARCHAR(19) CHECK (digitos_tarjeta ~ '^[0-9]{16,19}$'),
	PRIMARY KEY(id_pago),
	CONSTRAINT fk_id_cuenta_realiza
		FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_pago_realiza
		FOREIGN KEY(id_pago) REFERENCES pago(id_pago)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_digitos_tarjeta_realiza
		FOREIGN KEY(digitos_tarjeta) REFERENCES tarjeta(digitos_tarjeta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tier(
    nombre_tier tiers,
    PRIMARY KEY (nombre_tier)
);

CREATE TABLE IF NOT EXISTS permiso(
    nombre_permiso VARCHAR(100),
    descripcion_permiso VARCHAR(256) NOT NULL,
    PRIMARY KEY (nombre_permiso)
);

CREATE TABLE IF NOT EXISTS maneja(
    nombre_tier tiers,
    nombre_permiso VARCHAR(100),
    PRIMARY KEY (nombre_tier, nombre_permiso),
	CONSTRAINT fk_nombre_tier_maneja
		FOREIGN KEY (nombre_tier) REFERENCES tier(nombre_tier)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_nombre_permiso_maneja
		FOREIGN KEY (nombre_permiso) REFERENCES permiso(nombre_permiso)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS perfil(
	id_cuenta INT,
	sexo sexos NOT NULL,
	descripcion VARCHAR(256),
	verificado BOOLEAN DEFAULT FALSE NOT NULL,
	latitud DECIMAL(10, 8) NOT NULL,
	longitud DECIMAL(11, 8) NOT NULL,
	coordenada geometry(POINT, 4326),
	PRIMARY KEY (id_cuenta),
	CONSTRAINT fk_id_cuenta_perfil
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE INDEX perfil_geo_index ON perfil USING GIST (coordenada);

CREATE TABLE IF NOT EXISTS preferencias(
	id_cuenta INT, 
	estudio estudios,
	latitud_origen DECIMAL(10, 8),
	longitud_origen DECIMAL(11, 8),
	distancia_maxima INT DEFAULT 5 CHECK (distancia_maxima <= 3000) NOT NULL,
	min_edad INT DEFAULT 30 CHECK (min_edad BETWEEN 30 AND 99) NOT NULL,
	max_edad INT DEFAULT 99 CHECK (max_edad BETWEEN 30 AND 99) NOT NULL,
	coordenada_origen geometry(POINT, 4326),
	PRIMARY KEY (id_cuenta), 
	CONSTRAINT fk_id_cuenta_preferencias
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE INDEX pref_geo_index ON preferencias USING GIST (coordenada_origen);

CREATE TABLE IF NOT EXISTS institucion (
	dominio VARCHAR(64),
	nombre VARCHAR(32) NOT NULL,
	tipo tipo_instituciones NOT NULL,
	ano_fundacion INT NOT NULL,
	latitud DECIMAL(10, 8) NOT NULL,
	longitud DECIMAL(11, 8) NOT NULL,
	coordenada geometry(POINT, 4326),
	PRIMARY KEY(dominio)
);

CREATE INDEX institucion_geo_index ON institucion USING GIST (coordenada);

CREATE TABLE IF NOT EXISTS estudio_en(
	id_cuenta INT,
	dominio VARCHAR(64),
	titulo VARCHAR(64) NOT NULL, 
	ano_ingreso INT NOT NULL,
	ano_egreso INT NOT NULL,
	PRIMARY KEY(id_cuenta, dominio),
	CONSTRAINT fk_id_cuenta_estudio_en
		FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_dominio_estudio_en
		FOREIGN KEY(dominio) REFERENCES institucion(dominio)
			ON DELETE RESTRICT	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS empresa(
    id_empresa INT GENERATED ALWAYS AS IDENTITY,
    nombre_empresa VARCHAR(100) NOT NULL,
    PRIMARY KEY(id_empresa)
);

CREATE TABLE IF NOT EXISTS trabaja_en(
    id_cuenta INT,
    id_empresa INT,
    cargo VARCHAR(32) NOT NULL,
    fecha_inicio DATE NOT NULL,
    PRIMARY KEY(id_cuenta, id_empresa),
    CONSTRAINT fk_id_cuenta_trabaja_en
        FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
        	ON DELETE CASCADE	ON UPDATE CASCADE,
    CONSTRAINT fk_id_empresa_trabaja_en
        FOREIGN KEY(id_empresa) REFERENCES empresa(id_empresa)
        	ON DELETE CASCADE	ON UPDATE CASCADE	
);

CREATE TABLE IF NOT EXISTS suscrita(
    id_cuenta INT,
	nombre_tier tiers,
	fecha_inicio DATE DEFAULT CURRENT_DATE NOT NULL,
	fecha_caducidad DATE NOT NULL CHECK (fecha_caducidad > fecha_inicio),
    PRIMARY KEY (id_cuenta, nombre_tier, fecha_inicio),
	CONSTRAINT fk_id_cuenta_suscrita
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_nombre_tier_suscrita
		FOREIGN KEY (nombre_tier) REFERENCES tier(nombre_tier)
			ON DELETE RESTRICT	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS likes(
	id_liker INT,  
	id_liked INT,
	super BOOLEAN DEFAULT FALSE NOT NULL,
	fecha_like TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_liker, id_liked),
	CONSTRAINT fk_id_liker_likes
		FOREIGN KEY (id_liker) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_liked_likes
		FOREIGN KEY (id_liked) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS swipes(
    id_disliker INT,
    id_disliked INT,
    PRIMARY KEY (id_disliker, id_disliked),
    CONSTRAINT fk_id_disliker_swipes
    	FOREIGN KEY (id_disliker) REFERENCES cuenta(id_cuenta)
		ON DELETE CASCADE	ON UPDATE CASCADE,
    CONSTRAINT fk_id_disliked_swipes
    	FOREIGN KEY (id_disliked) REFERENCES cuenta(id_cuenta)
		ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS match_with(
	id_matcher INT,
	id_matched INT,
	Fecha DATE DEFAULT CURRENT_DATE NOT NULL,
	PRIMARY KEY(id_matcher, id_matched),
	CONSTRAINT fk_id_matcher_match_with
		FOREIGN KEY(id_matcher) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_matched_match_with
		FOREIGN KEY(id_matched) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS chat(
    id_chat INT GENERATED ALWAYS AS IDENTITY,
    PRIMARY KEY(id_chat)
);

CREATE TABLE IF NOT EXISTS mensaje(
    id_chat INT,
    numero_msj INT GENERATED ALWAYS AS IDENTITY,
    id_remitente INT NOT NULL,
    visto BOOLEAN DEFAULT FALSE,
    texto TEXT DEFAULT '' NOT NULL,
    fecha_msj TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(id_chat, numero_msj),
    CONSTRAINT fk_id_chat_mensaje
        FOREIGN KEY(id_chat) REFERENCES chat(id_chat)
);

CREATE TABLE IF NOT EXISTS archivo(
	id_chat INT,
	numero_msj INT,
	nombre VARCHAR(128),
	tipo VARCHAR(16),
	contenido BYTEA,
	PRIMARY KEY(id_chat, numero_msj, nombre),
	CONSTRAINT fk_id_chat_numero_msj_archivo
		FOREIGN KEY(id_chat, numero_msj) REFERENCES mensaje(id_chat, numero_msj)
			ON DELETE CASCADE 	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS chatea_con(
	id_cuenta1 INT NOT NULL,
	id_cuenta2 INT NOT NULL,
	id_chat INT,
	PRIMARY KEY (id_chat),
	CONSTRAINT fk_id_cuenta1_chatea_con
		FOREIGN KEY (id_cuenta1) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_cuenta2_chatea_con
		FOREIGN KEY (id_cuenta2) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_chat_chatea_con 
		FOREIGN KEY (id_chat) REFERENCES chat(id_chat)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS esta_en_agrupacion(
	id_cuenta INT,
	dominio VARCHAR(64),
	agrupacion VARCHAR(64),
	PRIMARY KEY(id_cuenta, dominio, agrupacion),
	CONSTRAINT fk_id_cuenta_esta_en_agrupacion
		FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE 	ON UPDATE CASCADE,
	CONSTRAINT fk_domino_esta_en_agrupacion
		FOREIGN KEY (dominio) REFERENCES institucion(dominio)
			ON DELETE CASCADE 	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_hobby(
    id_cuenta INT,
    hobby hobbies,
    PRIMARY KEY(id_cuenta, hobby),
    CONSTRAINT fk_id_cuenta_tiene_hobby
        FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
        ON DELETE CASCADE	ON UPDATE CASCADE 
);


CREATE TABLE IF NOT EXISTS tiene_habilidades(
	id_cuenta INT,
	habilidad habilidades,
	PRIMARY KEY (id_cuenta, habilidad),
	CONSTRAINT fk_id_cuenta_tiene_habilidades
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_foto(
	id_cuenta INT,
	foto BYTEA,
	PRIMARY KEY(id_cuenta, foto),
	CONSTRAINT fk_id_cuenta_tiene_foto
		FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_orientacion_sexual(
	id_cuenta INT,
	orientacion_sexual orientaciones ,
	PRIMARY KEY (id_cuenta, orientacion_sexual),
	CONSTRAINT fk_id_cuenta_tiene_orientacion_sexual
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_certificaciones(
	id_cuenta INT,
	certificaciones VARCHAR(256),
	PRIMARY KEY(id_cuenta, certificaciones),
	CONSTRAINT fk_id_cuenta_tiene_certificaciones
		FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS pref_orientacion_sexual(
	id_cuenta INT,
	orientacion_sexual orientaciones,
	PRIMARY KEY(id_cuenta, orientacion_sexual),
	CONSTRAINT fk_id_cuenta_pref_orientacion_sexual
		FOREIGN KEY(id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS pref_sexo(
	id_cuenta INT,
	sexo sexos,
	PRIMARY KEY (id_cuenta, sexo),
	CONSTRAINT fk_id_cuenta_pref_sexo
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);
