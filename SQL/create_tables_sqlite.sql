-- SQLite version for GeoManager
-- Community Edition Delphi compatible

-- =============================================================================
-- TABELA: GEO_USUARIOS
-- =============================================================================
CREATE TABLE IF NOT EXISTS GEO_USUARIOS (
    USU_ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    USU_LOGIN           TEXT NOT NULL UNIQUE,
    USU_NOME            TEXT NOT NULL,
    USU_EMAIL           TEXT NOT NULL UNIQUE,
    USU_SENHA_HASH      TEXT NOT NULL,
    USU_PERFIL          TEXT NOT NULL DEFAULT 'VISUALIZADOR',
    USU_ATIVO           INTEGER NOT NULL DEFAULT 1,
    USU_DATA_CRIACAO    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    USU_DATA_ALTERACAO  DATETIME
);

-- =============================================================================
-- TABELA: GEO_PONTOS_INTERESSE (POI)
-- =============================================================================
CREATE TABLE IF NOT EXISTS GEO_PONTOS_INTERESSE (
    POI_ID                  INTEGER PRIMARY KEY AUTOINCREMENT,
    POI_NOME                TEXT NOT NULL,
    POI_DESCRICAO           TEXT,
    POI_LATITUDE            REAL NOT NULL,
    POI_LONGITUDE           REAL NOT NULL,
    POI_TIPO                TEXT NOT NULL DEFAULT 'GERAL',
    POI_ENDERECO            TEXT,
    POI_USUARIO_ID          INTEGER NOT NULL,
    POI_ATIVO               INTEGER NOT NULL DEFAULT 1,
    POI_DATA_CRIACAO        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    POI_DATA_ALTERACAO      DATETIME,
    FOREIGN KEY (POI_USUARIO_ID) REFERENCES GEO_USUARIOS(USU_ID),
    CHECK (POI_LATITUDE BETWEEN -90 AND 90),
    CHECK (POI_LONGITUDE BETWEEN -180 AND 180)
);

-- =============================================================================
-- TABELA: GEO_CAMADAS (Layers)
-- =============================================================================
CREATE TABLE IF NOT EXISTS GEO_CAMADAS (
    CAM_ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    CAM_NOME            TEXT NOT NULL,
    CAM_DESCRICAO       TEXT,
    CAM_URL_SERVICO     TEXT,
    CAM_TIPO_SERVICO    TEXT NOT NULL DEFAULT 'MapServer',
    CAM_VISIVEL         INTEGER NOT NULL DEFAULT 1,
    CAM_ORDEM           INTEGER NOT NULL DEFAULT 0,
    CAM_OPACIDADE       REAL NOT NULL DEFAULT 1.00,
    CAM_ATIVO           INTEGER NOT NULL DEFAULT 1,
    CAM_DATA_CRIACAO    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (CAM_OPACIDADE BETWEEN 0 AND 1)
);

-- =============================================================================
-- TABELA: GEO_LOG_AUDITORIA
-- =============================================================================
CREATE TABLE IF NOT EXISTS GEO_LOG_AUDITORIA (
    LOG_ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    LOG_DATA_HORA       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LOG_USUARIO_ID      INTEGER,
    LOG_USUARIO_NOME    TEXT,
    LOG_ACAO            TEXT NOT NULL,
    LOG_TABELA          TEXT,
    LOG_REGISTRO_ID     TEXT,
    LOG_DESCRICAO       TEXT,
    LOG_NIVEL           TEXT NOT NULL DEFAULT 'INFO',
    LOG_IP_MAQUINA      TEXT,
    LOG_NOME_MAQUINA    TEXT,
    FOREIGN KEY (LOG_USUARIO_ID) REFERENCES GEO_USUARIOS(USU_ID)
);

-- =============================================================================
-- TABELA: GEO_CONFIGURACOES
-- =============================================================================
CREATE TABLE IF NOT EXISTS GEO_CONFIGURACOES (
    CFG_ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    CFG_CHAVE           TEXT NOT NULL UNIQUE,
    CFG_VALOR           TEXT,
    CFG_DESCRICAO       TEXT,
    CFG_GRUPO           TEXT NOT NULL DEFAULT 'GERAL',
    CFG_DATA_ALTERACAO  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- ÍNDICES
-- =============================================================================
CREATE INDEX IF NOT EXISTS IX_POI_TIPO ON GEO_PONTOS_INTERESSE(POI_TIPO);
CREATE INDEX IF NOT EXISTS IX_POI_USUARIO ON GEO_PONTOS_INTERESSE(POI_USUARIO_ID);
CREATE INDEX IF NOT EXISTS IX_POI_ATIVO ON GEO_PONTOS_INTERESSE(POI_ATIVO);
CREATE INDEX IF NOT EXISTS IX_POI_COORDS ON GEO_PONTOS_INTERESSE(POI_LATITUDE, POI_LONGITUDE);
CREATE INDEX IF NOT EXISTS IX_LOG_DATA ON GEO_LOG_AUDITORIA(LOG_DATA_HORA);
CREATE INDEX IF NOT EXISTS IX_LOG_USUARIO ON GEO_LOG_AUDITORIA(LOG_USUARIO_ID);
CREATE INDEX IF NOT EXISTS IX_LOG_NIVEL ON GEO_LOG_AUDITORIA(LOG_NIVEL);
CREATE INDEX IF NOT EXISTS IX_CAM_ORDEM ON GEO_CAMADAS(CAM_ORDEM);

-- =============================================================================
-- DADOS INICIAIS
-- =============================================================================

-- Usuário administrador
INSERT OR IGNORE INTO GEO_USUARIOS (USU_LOGIN, USU_NOME, USU_EMAIL, USU_SENHA_HASH, USU_PERFIL)
VALUES ('admin', 'Administrador do Sistema', 'admin@geomanager.com',
        '240BE518FABD2724DDB6F04EEB1DA5967448D7E831C08C8FA822809F74C720A9', 'ADMIN');

INSERT OR IGNORE INTO GEO_USUARIOS (USU_LOGIN, USU_NOME, USU_EMAIL, USU_SENHA_HASH, USU_PERFIL)
VALUES ('analista', 'Analista GIS', 'analista@geomanager.com',
        '6CA13D52CA70C883E0F0BB101E425A89E8624DE51DB2D2392593AF6A84118090', 'ANALISTA');

-- Pontos de interesse de exemplo
INSERT OR IGNORE INTO GEO_PONTOS_INTERESSE (POI_NOME, POI_DESCRICAO, POI_LATITUDE, POI_LONGITUDE, POI_TIPO, POI_ENDERECO, POI_USUARIO_ID)
VALUES ('Cristo Redentor', 'Monumento icônico do Rio de Janeiro', -22.95191, -43.21048, 'MONUMENTO',
        'Parque Nacional da Tijuca - Alto da Boa Vista, Rio de Janeiro - RJ', 1);

INSERT OR IGNORE INTO GEO_PONTOS_INTERESSE (POI_NOME, POI_DESCRICAO, POI_LATITUDE, POI_LONGITUDE, POI_TIPO, POI_ENDERECO, POI_USUARIO_ID)
VALUES ('Congresso Nacional', 'Sede do Poder Legislativo Federal', -15.79997, -47.86437, 'GOVERNO',
        'Praça dos Três Poderes, Brasília - DF', 1);

INSERT OR IGNORE INTO GEO_PONTOS_INTERESSE (POI_NOME, POI_DESCRICAO, POI_LATITUDE, POI_LONGITUDE, POI_TIPO, POI_ENDERECO, POI_USUARIO_ID)
VALUES ('MASP', 'Museu de Arte de São Paulo', -23.56120, -46.65586, 'CULTURA',
        'Av. Paulista, 1578 - Bela Vista, São Paulo - SP', 1);

INSERT OR IGNORE INTO GEO_PONTOS_INTERESSE (POI_NOME, POI_DESCRICAO, POI_LATITUDE, POI_LONGITUDE, POI_TIPO, POI_ENDERECO, POI_USUARIO_ID)
VALUES ('Usina de Itaipu', 'Maior usina hidrelétrica do mundo em geração', -25.40830, -54.58883, 'INFRAESTRUTURA',
        'Foz do Iguaçu - PR', 1);

-- Camadas de mapa
INSERT OR IGNORE INTO GEO_CAMADAS (CAM_NOME, CAM_DESCRICAO, CAM_URL_SERVICO, CAM_TIPO_SERVICO, CAM_ORDEM)
VALUES ('Mapa Base Mundial', 'World Topographic Map da ESRI',
        'https://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer',
        'MapServer', 0);

INSERT OR IGNORE INTO GEO_CAMADAS (CAM_NOME, CAM_DESCRICAO, CAM_URL_SERVICO, CAM_TIPO_SERVICO, CAM_ORDEM)
VALUES ('Imagem de Satélite', 'World Imagery da ESRI',
        'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer',
        'MapServer', 1);

INSERT OR IGNORE INTO GEO_CAMADAS (CAM_NOME, CAM_DESCRICAO, CAM_URL_SERVICO, CAM_TIPO_SERVICO, CAM_ORDEM)
VALUES ('Limites Administrativos', 'Fronteiras e divisões administrativas',
        'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer',
        'MapServer', 2);

-- Configurações
INSERT OR IGNORE INTO GEO_CONFIGURACOES (CFG_CHAVE, CFG_VALOR, CFG_DESCRICAO, CFG_GRUPO)
VALUES ('ARCGIS_BASE_URL', 'https://geocode.arcgis.com/arcgis/rest/services', 'URL base do ArcGIS REST API', 'ARCGIS');

INSERT OR IGNORE INTO GEO_CONFIGURACOES (CFG_CHAVE, CFG_VALOR, CFG_DESCRICAO, CFG_GRUPO)
VALUES ('ARCGIS_API_KEY', '', 'Chave de API do ArcGIS Developer', 'ARCGIS');

INSERT OR IGNORE INTO GEO_CONFIGURACOES (CFG_CHAVE, CFG_VALOR, CFG_DESCRICAO, CFG_GRUPO)
VALUES ('LOG_NIVEL_MINIMO', 'INFO', 'Nível mínimo de log', 'SISTEMA');

INSERT OR IGNORE INTO GEO_CONFIGURACOES (CFG_CHAVE, CFG_VALOR, CFG_DESCRICAO, CFG_GRUPO)
VALUES ('MAPA_CENTRO_LAT', '-15.7939', 'Latitude central padrão do mapa', 'MAPA');

INSERT OR IGNORE INTO GEO_CONFIGURACOES (CFG_CHAVE, CFG_VALOR, CFG_DESCRICAO, CFG_GRUPO)
VALUES ('MAPA_CENTRO_LON', '-47.8828', 'Longitude central padrão do mapa', 'MAPA');

INSERT OR IGNORE INTO GEO_CONFIGURACOES (CFG_CHAVE, CFG_VALOR, CFG_DESCRICAO, CFG_GRUPO)
VALUES ('MAPA_ZOOM_PADRAO', '5', 'Nível de zoom padrão do mapa', 'MAPA');

-- =============================================================================
-- VIEWS
-- =============================================================================
CREATE VIEW IF NOT EXISTS VW_PONTOS_INTERESSE AS
SELECT
    p.POI_ID,
    p.POI_NOME,
    p.POI_DESCRICAO,
    p.POI_LATITUDE,
    p.POI_LONGITUDE,
    p.POI_TIPO,
    p.POI_ENDERECO,
    p.POI_ATIVO,
    p.POI_DATA_CRIACAO,
    p.POI_DATA_ALTERACAO,
    u.USU_ID AS CRIADO_POR_ID,
    u.USU_NOME AS CRIADO_POR_NOME
FROM GEO_PONTOS_INTERESSE p
INNER JOIN GEO_USUARIOS u ON p.POI_USUARIO_ID = u.USU_ID;
