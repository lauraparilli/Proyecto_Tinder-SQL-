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

CREATE TABLE IF NOT EXISTS cuenta(
	id_cuenta INT GENERATED ALWAYS AS IDENTITY,
	nombre VARCHAR(32) NOT NULL,
	apellido VARCHAR(32) NOT NULL,
	fecha_nacimiento DATE NOT NULL,
	fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
	email VARCHAR(255) UNIQUE NOT NULL,
	contrasena VARCHAR(128) NOT NULL,
	telefono VARCHAR(16) NOT NULL,
	idioma CHAR(3) DEFAULT 'ESP' NOT NULL,
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

CREATE TABLE IF NOT EXISTS tier(
    nombre_tier tiers,
    PRIMARY KEY (nombre_tier)
);

CREATE TABLE IF NOT EXISTS permiso(
    nombre_permiso VARCHAR(100),
    descripcion_permiso VARCHAR(256) NOT NULL,
    PRIMARY KEY (nombre_permiso)
);

CREATE TABLE IF NOT EXISTS chat(
    id_chat INT GENERATED ALWAYS AS IDENTITY,
    PRIMARY KEY(id_chat)
);

CREATE TABLE IF NOT EXISTS institucion (
    dominio VARCHAR(64),
    nombre VARCHAR(32) NOT NULL,
    coordenada VARCHAR(30) NOT NULL,
    tipo tipo_instituciones NOT NULL,
    ano_fundacion INT NOT NULL,
	PRIMARY KEY(dominio)
);

CREATE TABLE IF NOT EXISTS empresa(
    id_empresa INT GENERATED ALWAYS AS IDENTITY,
    nombre_empresa VARCHAR(100) NOT NULL,
    PRIMARY KEY(id_empresa)
);

CREATE TABLE IF NOT EXISTS perfil(
    id_cuenta INT,
    id_perfil INT GENERATED ALWAYS AS IDENTITY,
    sexo sexos NOT NULL,
    descripcion VARCHAR(256),
    verificado BOOLEAN DEFAULT FALSE NOT NULL,
    coordenada VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_cuenta, id_perfil), 
    CONSTRAINT fk_id_cuenta_perfil
    	FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
         	ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS preferencias(
	id_cuenta INT, 
	id_perfil INT,
	id_pref INT GENERATED ALWAYS AS IDENTITY,
	estudio estudios,
	coordanada_origen VARCHAR(30) NOT NULL,
	distancia_maxima INT DEFAULT 0 CHECK (distancia_maxima <= 3000) NOT NULL,
	min_edad INT DEFAULT 30 CHECK (min_edad BETWEEN 30 AND 99) NOT NULL,
	max_edad INT DEFAULT 99 CHECK (max_edad BETWEEN 30 AND 99) NOT NULL,
	PRIMARY KEY (id_cuenta, id_perfil, id_pref), 
	CONSTRAINT fk_id_cuenta_id_perfil_preferencias
		FOREIGN KEY (id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS mensaje (
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

CREATE TABLE IF NOT EXISTS suscrita(
    id_cuenta INT,
	nombre_tier tiers,
	fecha_inicio DATE DEFAULT CURRENT_DATE NOT NULL,
	fecha_caducidad DATE NOT NULL,
    PRIMARY KEY (id_cuenta, nombre_tier),
	CONSTRAINT fk_id_cuenta_suscrita
		FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_nombre_tier_suscrita
		FOREIGN KEY (nombre_tier) REFERENCES tier(nombre_tier)
			ON DELETE CASCADE	ON UPDATE CASCADE
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

CREATE TABLE IF NOT EXISTS likes(
	id_liker INT,  
	id_liked INT,
	super BOOLEAN DEFAULT FALSE NOT NULL,
	fecha_like TIMESTAMP NOT NULL,
    PRIMARY KEY (id_liker, id_liked),
	CONSTRAINT fk_id_liker_likes
		FOREIGN KEY (id_liker) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_liked_likes
		FOREIGN KEY (id_liked) REFERENCES cuenta(id_cuenta)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS swipes (
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

CREATE TABLE IF NOT EXISTS trabaja_en (
    id_cuenta INT,
    id_perfil INT,
    id_empresa INT,
    cargo VARCHAR(32) NOT NULL,
    fecha_inicio DATE NOT NULL,
    PRIMARY KEY(id_cuenta, id_perfil, id_empresa),
    CONSTRAINT fk_id_cuenta_id_perfil_trabaja_en
        FOREIGN KEY(id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
        	ON DELETE CASCADE	ON UPDATE CASCADE,
    CONSTRAINT fk_id_empresa_trabaja_en
        FOREIGN KEY(id_empresa) REFERENCES empresa(id_empresa)
        	ON DELETE CASCADE	ON UPDATE CASCADE	
);

CREATE TABLE IF NOT EXISTS estudio_en(
	id_cuenta INT,
	id_perfil INT,
	dominio VARCHAR(64),
	titulo VARCHAR(64) NOT NULL, 
	ano_ingreso INT NOT NULL,
	ano_egreso INT NOT NULL,
	PRIMARY KEY(id_cuenta, id_perfil, dominio),
	CONSTRAINT fk_id_cuenta_id_perfil_estudio_en
		FOREIGN KEY(id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_dominio_estudio_en
		FOREIGN KEY(dominio) REFERENCES institucion(dominio)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS chatea_con(
	id_cuenta1 INT,
	id_perfil1 INT,
	id_cuenta2 INT,
	id_perfil2 INT,
	id_chat INT UNIQUE NOT NULL,
	PRIMARY KEY (id_cuenta1, id_perfil1, id_cuenta2, id_perfil2),
	CONSTRAINT fk_id_cuenta1_id_perfil1_chatea_con
		FOREIGN KEY (id_cuenta1, id_perfil1) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_cuenta2_id_perfil2_chatea_con
		FOREIGN KEY (id_cuenta2, id_perfil2) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE,
	CONSTRAINT fk_id_chat_chatea_con 
		FOREIGN KEY (id_chat) REFERENCES chat(id_chat)
			ON DELETE CASCADE	ON UPDATE CASCADE
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

CREATE TABLE IF NOT EXISTS esta_en_agrupacion (
	id_cuenta INT,
	id_perfil INT,
	dominio VARCHAR(64),
	agrupacion VARCHAR(64),
	PRIMARY KEY(id_cuenta, id_perfil, dominio, agrupacion),
	CONSTRAINT fk_id_cuenta_id_perfil_esta_en_agrupacion
		FOREIGN KEY(id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE 	ON UPDATE CASCADE,
	CONSTRAINT fk_domino_esta_en_institucion
		FOREIGN KEY (dominio) REFERENCES institucion(dominio)
			ON DELETE CASCADE 	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_hobby (
    id_cuenta INT,
    id_perfil INT,
    hobby VARCHAR(64),
    PRIMARY KEY(id_cuenta, id_perfil, hobby),
    CONSTRAINT fk_id_cuenta_id_perfil_tiene_hobby
        FOREIGN KEY(id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
        ON DELETE CASCADE	ON UPDATE CASCADE 
);


CREATE TABLE IF NOT EXISTS tiene_habilidades(
	id_cuenta INT,
	id_perfil INT,
	habilidades VARCHAR(256),
	PRIMARY KEY (id_cuenta, id_perfil, habilidades),
	CONSTRAINT fk_id_cuenta_id_perfil_tiene_habilidades
		FOREIGN KEY (id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_foto(
	id_cuenta INT,
	id_perfil INT,
	foto BYTEA,
	PRIMARY KEY(id_cuenta, id_perfil, foto),
	CONSTRAINT fk_id_cuenta_id_perfil_tiene_foto
		FOREIGN KEY(id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_orientacion_sexual(
	id_cuenta INT,
	id_perfil INT,
	orientacion_sexual orientaciones ,
	PRIMARY KEY (id_cuenta, id_perfil, orientacion_sexual),
	CONSTRAINT fk_id_cuenta_id_perfil_tiene_orientacion_sexual
		FOREIGN KEY (id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS tiene_certificaciones(
	id_cuenta INT,
	id_perfil INT,
	certificaciones VARCHAR(256),
	PRIMARY KEY(id_cuenta, id_perfil, certificaciones),
	CONSTRAINT fk_id_cuenta_id_perfil_tiene_certificaciones
		FOREIGN KEY(id_cuenta, id_perfil) REFERENCES perfil(id_cuenta, id_perfil)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS archivo (
	id_chat INT,
	numero_msj INT,
	nombre VARCHAR(128),
	tipo VARCHAR(16),
	contenido BYTEA,
	PRIMARY KEY(id_chat, numero_msj, nombre,tipo, contenido),
	CONSTRAINT fk_id_chat_numero_msj_archivo
		FOREIGN KEY(id_chat, numero_msj) REFERENCES mensaje(id_chat, numero_msj)
			ON DELETE CASCADE 	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS pref_orientacion_sexual(
	id_cuenta INT,
	id_perfil INT,
	id_pref INT,
	orientacion_sexual orientaciones,
	PRIMARY KEY(id_cuenta, id_perfil, id_pref, orientacion_sexual),
	CONSTRAINT fk_id_cuenta_id_perfil_id_pref_pref_orientacion_sexual
		FOREIGN KEY(id_cuenta, id_perfil, id_pref) REFERENCES preferencias(id_cuenta, id_perfil, id_pref)
			ON DELETE CASCADE	ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS pref_sexo(
	id_cuenta INT,
	id_perfil INT,
	id_pref INT,
	sexo sexos,
	PRIMARY KEY (id_cuenta, id_perfil, id_pref, sexo),
	CONSTRAINT fk_id_cuenta_id_perfil_id_pref_pref_sexo
		FOREIGN KEY (id_cuenta, id_perfil, id_pref) REFERENCES preferencias(id_cuenta, id_perfil, id_pref)
			ON DELETE CASCADE	ON UPDATE CASCADE
);
