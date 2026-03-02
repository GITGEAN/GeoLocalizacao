# GeoManager - Documentação Arquitetural

## Visão Geral

O GeoManager segue uma **arquitetura em camadas** (Layered Architecture) inspirada no padrão **MVC** (Model-View-Controller), com separação clara de responsabilidades.

## Diagrama de Camadas

```
┌─────────────────────────────────────────────────────┐
│                    VIEWS (UI)                        │
│  View.Main │ View.POIManager │ View.Config          │
│  - Formulários VCL                                   │
│  - Eventos de interface                              │
│  - NÃO contém lógica de negócio                     │
├─────────────────────────────────────────────────────┤
│                  SERVICES (Negócio)                  │
│  Service.Geo │ Service.POI │ Service.Auth           │
│  - Regras de negócio                                 │
│  - Validações complexas                              │
│  - Orquestra DAOs e integrações                     │
├──────────────────────┬──────────────────────────────┤
│   DAO (Dados)        │  INTEGRATION (Externo)       │
│  DAO.Base            │  ArcGIS REST Client          │
│  DAO.POI             │  SOAP Client                 │
│  DAO.User            │  HTTP Helper                 │
│  DAO.Connection      │                              │
├──────────────────────┴──────────────────────────────┤
│                  UTILS (Cross-cutting)               │
│  Logger │ Config │ GeoCalc                          │
├─────────────────────────────────────────────────────┤
│                  MODELS (Entidades)                  │
│  TPOI │ TUser │ TLogEntry                           │
└─────────────────────────────────────────────────────┘
```

## Padrões de Projeto Utilizados

| Padrão | Onde | Propósito |
|---|---|---|
| **Singleton** | `TConnectionManager`, `TLogger`, `TConfigManager` | Única instância global |
| **DAO** | `TBaseDAO`, `TPOIDAO`, `TUserDAO` | Separar acesso a dados |
| **MVC** | Models/Views/Services | Separar responsabilidades |
| **Template Method** | `TBaseDAO.ExecuteSQL/ExecuteQuery` | Operações comuns herdadas |
| **Factory Method** | `TPOI.StringToTipo` | Criação de objetos baseada em dados |
| **Observer** | DataSource → DBGrid | Notificação de mudanças |

## Fluxo de uma Operação Típica

```
1. Usuário clica "Geocodificar" (View.Main)
2. View chama FGeoService.EnderecoParaCoordenadas (Service.Geo)
3. Service chama FArcGISClient.Geocodificar (Integration.ArcGIS.REST)
4. Integration monta HTTP GET e chama FHTTPHelper.Get (Integration.HTTP.Helper)
5. HTTP Helper faz requisição REST para ArcGIS API
6. Resposta JSON é parseada e retornada pela cadeia
7. View exibe resultado no mapa (JavaScript) e no painel de detalhes
```

## Regras de Dependência

- **Views** dependem de **Services** (nunca de DAOs diretamente)
- **Services** dependem de **DAOs** e **Integration**
- **DAOs** dependem de **Models** e **Connection**
- **Models** são independentes (não dependem de nenhuma outra camada)
- **Utils** podem ser usados por qualquer camada
