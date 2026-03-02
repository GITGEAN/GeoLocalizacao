CREATE DATABASE GeoManagerDB;
GO

USE GeoManagerDB;
GO

-- Tabela de Usuários
CREATE TABLE GEO_USUARIOS (
    USU_ID INT IDENTITY(1,1) PRIMARY KEY,
    USU_LOGIN VARCHAR(50) NOT NULL UNIQUE,
    USU_NOME VARCHAR(100) NOT NULL,
    USU_EMAIL VARCHAR(100) NOT NULL,
    USU_SENHA_HASH VARCHAR(255) NOT NULL,
    USU_PERFIL VARCHAR(20) NOT NULL,
    USU_ATIVO BIT DEFAULT 1,
    USU_DATA_CRIACAO DATETIME DEFAULT GETDATE(),
    USU_DATA_ALTERACAO DATETIME NULL
);
GO

-- Tabela de Pontos de Interesse (POI)
CREATE TABLE GEO_PONTOS_INTERESSE (
    POI_ID INT IDENTITY(1,1) PRIMARY KEY,
    POI_NOME VARCHAR(200) NOT NULL,
    POI_DESCRICAO TEXT NULL,
    POI_LATITUDE FLOAT NOT NULL,
    POI_LONGITUDE FLOAT NOT NULL,
    POI_TIPO VARCHAR(50) NOT NULL,
    POI_ENDERECO VARCHAR(255) NULL,
    POI_USUARIO_ID INT NOT NULL,
    POI_ATIVO BIT DEFAULT 1,
    POI_DATA_CRIACAO DATETIME DEFAULT GETDATE(),
    POI_DATA_ALTERACAO DATETIME NULL,
    
    CONSTRAINT FK_POI_USUARIO FOREIGN KEY (POI_USUARIO_ID) 
    REFERENCES GEO_USUARIOS(USU_ID)
);
GO

-- ==========================================================
-- CARGA DE DADOS INICIAIS (SEED DATA)
-- ==========================================================

-- 1. Inserindo Usuário Administrador (senha: admin123)
-- (O hash aqui precisaria ser compatível com Delphi,
--  estamos inserindo um mock para login funcionar caso a senha 
--  não seja validada de forma estrita, ou você cria no app depois)
INSERT INTO GEO_USUARIOS (USU_LOGIN, USU_NOME, USU_EMAIL, USU_SENHA_HASH, USU_PERFIL)
VALUES ('admin', 'Administrador do Sistema', 'admin@geomanager.com', 'admin_hash_mock', 'ADMIN');

INSERT INTO GEO_USUARIOS (USU_LOGIN, USU_NOME, USU_EMAIL, USU_SENHA_HASH, USU_PERFIL)
VALUES ('operador', 'Operador Padrão', 'operador@geomanager.com', 'oper_hash_mock', 'ANALISTA');
GO

-- 2. Inserindo Pontos de Interesse no Brasil (Brasília e São Paulo)
INSERT INTO GEO_PONTOS_INTERESSE (POI_NOME, POI_DESCRICAO, POI_LATITUDE, POI_LONGITUDE, POI_TIPO, POI_ENDERECO, POI_USUARIO_ID)
VALUES 
('Congresso Nacional', 'Sede do poder legislativo brasileiro.', -15.7997, -47.8641, 'GOVERNO', 'Praça dos Três Poderes, Brasília - DF', 1),
('MASP', 'Museu de Arte de São Paulo Assis Chateaubriand.', -23.5614, -46.6559, 'CULTURA', 'Av. Paulista, 1578 - Bela Vista, São Paulo - SP', 1),
('Cristo Redentor', 'Estátua art déco de Jesus Cristo no Rio de Janeiro.', -22.9519, -43.2104, 'MONUMENTO', 'Parque Nacional da Tijuca, Rio de Janeiro - RJ', 1),
('Aeroporto de Guarulhos', 'Aeroporto Internacional de São Paulo.', -23.4305, -46.4730, 'TRANSPORTE', 'Guarulhos - SP', 2),
('Jardim Botânico do RJ', 'Instituto de pesquisas do Jardim Botânico do Rio de Janeiro.', -22.9672, -43.2218, 'MEIO_AMBIENTE', 'Rua Jardim Botânico, 1008 - Rio de Janeiro - RJ', 2);
GO
