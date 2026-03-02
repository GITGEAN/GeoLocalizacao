# GeoManager - Sistema de Geoprocessamento Corporativo

> 🗺️ Projeto de estudo em **Delphi** com integração **ESRI/ArcGIS** para preparação de entrevista técnica.

---

## 📋 O que este projeto cobre

| Requisito da Vaga | Onde no Projeto |
|---|---|
| Desenvolvimento Delphi | Todo o projeto (Object Pascal, VCL, FireDAC) |
| Banco Oracle/SQL Server | `DAO.Connection.pas`, `create_tables.sql` |
| Geoprocessamento ESRI/ArcGIS | `Integration.ArcGIS.REST.pas`, `Utils.GeoCalc.pas` |
| APIs REST | `Integration.HTTP.Helper.pas`, `Integration.ArcGIS.REST.pas` |
| APIs SOAP | `Integration.SOAP.Client.pas` |
| Padrões de Projeto | Singleton, DAO, MVC, Strategy |
| Segurança da Informação | Hash de senhas, perfis de acesso, auditoria |
| Git e Metodologias Ágeis | `Docs/INTERVIEW_GUIDE.md` |
| Governança de TI | Logging, auditoria, controle de acesso |

---

## 🏗️ Arquitetura

```
Projeto segue MVC + DAO em 5 camadas:

Views (Interface) → Services (Negócio) → DAO (Dados) → Banco de Dados
                  → Integration (APIs externas: ArcGIS REST, SOAP)
```

| Camada | Diretório | Responsabilidade |
|---|---|---|
| **Models** | `Src/Models/` | Entidades do domínio (POI, User, LogEntry) |
| **DAO** | `Src/DAO/` | Acesso a dados (CRUD, queries, transações) |
| **Services** | `Src/Services/` | Regras de negócio e orquestração |
| **Integration** | `Src/Integration/` | APIs externas (ArcGIS REST, SOAP) |
| **Utils** | `Src/Utils/` | Logging, configuração, cálculos geográficos |
| **Views** | `Src/Views/` | Formulários VCL (interface do usuário) |

---

## 🚀 Como usar

### Pré-requisitos
- **Delphi 10.x ou superior** (Community Edition é gratuita)
- **SQL Server** ou **Oracle** (opcional - o app funciona sem banco para ver o mapa)
- **Conexão com internet** (para carregar o mapa ArcGIS)

### Passos
1. Abra `GeoManager.dpr` no Delphi IDE
2. Compile e execute (F9)
3. O mapa ArcGIS será carregado automaticamente
4. Para conectar ao banco: Menu Arquivo → Conectar (configure em Arquivo → Configurações)
5. Para criar o banco: execute `SQL/create_tables.sql` no seu SGBD

### Configuração
Edite `GeoManager.ini` para configurar banco, ArcGIS API Key e mapa.

---

## 📁 Estrutura de Arquivos

```
GeoManager/
├── GeoManager.dpr          # Arquivo do projeto Delphi
├── GeoManager.ini          # Configurações (banco, ArcGIS, mapa)
├── SQL/
│   └── create_tables.sql   # DDL Oracle/SQL Server + dados de exemplo
├── Src/
│   ├── Models/             # Entidades: POI, User, LogEntry
│   ├── DAO/                # Acesso a dados: Connection, Base, POI, User
│   ├── Services/           # Negócio: Geo, POI, Auth
│   ├── Integration/        # APIs: ArcGIS REST, SOAP, HTTP Helper
│   ├── Utils/              # Logger, Config, GeoCalc (Haversine)
│   └── Views/              # Forms: Main (mapa), POIManager, Config
└── Docs/
    └── INTERVIEW_GUIDE.md  # Perguntas e respostas para entrevista
```

---

## 🗺️ Conceitos de Geoprocessamento (ESRI/ArcGIS)

| Conceito | Explicação | Onde no projeto |
|---|---|---|
| **WGS84 (EPSG:4326)** | Sistema de coordenadas padrão (GPS, Google Maps, ArcGIS) | `Utils.GeoCalc.pas` |
| **Geocodificação** | Endereço → Coordenadas | `TArcGISClient.Geocodificar` |
| **Geocodificação Reversa** | Coordenadas → Endereço | `TArcGISClient.GeocodificacaoReversa` |
| **Feature Service** | Dados vetoriais editáveis (CRUD) via REST | `TArcGISClient.ConsultarFeatures` |
| **Map Service** | Mapas renderizados no servidor (somente leitura) | `TArcGISClient.ObterInfoServico` |
| **Haversine** | Distância entre dois pontos na esfera terrestre | `TGeoCalc.DistanciaHaversine` |
| **Bounding Box** | Retângulo delimitador para consultas espaciais | `TGeoCalc.CalcularBoundingBox` |
| **ArcGIS JS API** | Biblioteca JavaScript para mapas interativos | `View.Main.GerarHTMLMapa` |

---

## 📚 Para Estudar

1. **Leia o código** na ordem: Models → DAO → Services → Integration → Views
2. **Leia o `INTERVIEW_GUIDE.md`** em `Docs/` — tem perguntas e respostas completas
3. **Todos os arquivos têm comentários extensos** explicando conceitos
4. **Execute o projeto** e explore o mapa ArcGIS
5. **Crie o banco** e teste o CRUD de POIs

### Referências
- [ArcGIS REST API](https://developers.arcgis.com/rest/)
- [ArcGIS JavaScript API](https://developers.arcgis.com/javascript/)
- [FireDAC (Delphi)](https://docwiki.embarcadero.com/RADStudio/en/FireDAC)
- [Delphi Documentation](https://docwiki.embarcadero.com/RADStudio/)
