# 🔄 Estrategia de Versionado de APIs
## Sistema de Inventario PYMES

---

## 📋 Información General

**Método de Versionado:** URL Path Versioning  
**Formato:** `/api/v{major}/`  
**Versión Actual:** v1  
**Política de Soporte:** 18 meses por versión mayor  
**Deprecation Notice:** 12 meses antes de EOL  

---

## 🎯 Principios de Versionado

### 1. Semantic Versioning Adaptado

**Formato:** `v{MAJOR}.{MINOR}.{PATCH}`

- **MAJOR:** Cambios incompatibles (breaking changes)
- **MINOR:** Nueva funcionalidad compatible hacia atrás
- **PATCH:** Correcciones de bugs compatibles

### 2. Tipos de Cambios

#### 🔴 Breaking Changes (Requieren nueva versión MAJOR)
- Eliminación de endpoints
- Cambios en estructura de respuesta
- Modificación de parámetros requeridos
- Cambios en códigos de error
- Modificación de comportamiento existente

#### 🟡 Non-Breaking Changes (Versión MINOR)
- Nuevos endpoints
- Nuevos campos opcionales en respuestas
- Nuevos parámetros opcionales
- Nuevos headers opcionales
- Mejoras de performance

#### 🟢 Patch Changes
- Corrección de bugs
- Mejoras de documentación
- Optimizaciones internas
- Correcciones de seguridad

---

## 🗂️ Estructura de Versionado

### URL Path Versioning

```http
# Versión actual
GET https://api.inventario-pymes.com/v1/products

# Versión futura
GET https://api.inventario-pymes.com/v2/products

# Versión específica (opcional)
GET https://api.inventario-pymes.com/v1.2/products
```

### Ventajas del URL Path Versioning

✅ **Claridad:** Versión visible en la URL  
✅ **Caching:** Fácil cache por versión  
✅ **Routing:** Simple configuración de rutas  
✅ **Testing:** Fácil testing de múltiples versiones  
✅ **Documentation:** URLs específicas por versión  

---

## 📅 Roadmap de Versiones

### v1.0 (Actual - Enero 2024)
**Estado:** Estable  
**Soporte hasta:** Julio 2025  

**Funcionalidades:**
- Autenticación JWT
- CRUD de productos
- Gestión de inventario básica
- Reportes simples
- Alertas de stock

### v1.1 (Marzo 2024)
**Estado:** En desarrollo  
**Tipo:** Minor release  

**Nuevas funcionalidades:**
- Códigos de barras avanzados
- Múltiples ubicaciones
- Gestión de proveedores
- Reportes avanzados
- API de webhooks

### v1.2 (Junio 2024)
**Estado:** Planificado  
**Tipo:** Minor release  

**Nuevas funcionalidades:**
- Integración con sistemas contables
- Facturación electrónica
- Analytics avanzados
- Mobile SDK
- Bulk operations

### v2.0 (Enero 2025)
**Estado:** Planificado  
**Tipo:** Major release  

**Breaking changes:**
- Nueva estructura de autenticación (OAuth 2.0)
- Respuestas JSON:API compliant
- Nuevos códigos de error
- Eliminación de endpoints deprecated
- GraphQL support

---

## 🔄 Proceso de Migración

### Fase 1: Anuncio (12 meses antes)

```json
{
  "deprecation": {
    "version": "v1",
    "deprecatedAt": "2024-01-15T00:00:00Z",
    "sunsetAt": "2025-07-15T00:00:00Z",
    "migrationGuide": "https://docs.inventario-pymes.com/migration/v1-to-v2",
    "supportContact": "migration@inventario-pymes.com"
  }
}
```

### Fase 2: Headers de Deprecation

```http
# Response headers en v1
Deprecation: true
Sunset: Tue, 15 Jul 2025 00:00:00 GMT
Link: <https://docs.inventario-pymes.com/migration/v1-to-v2>; rel="successor-version"
Warning: 299 - "API v1 will be deprecated on 2025-07-15"
```

### Fase 3: Migración Gradual

```javascript
// Middleware para tracking de uso de versiones
app.use('/api/v1', (req, res, next) => {
  // Log usage for migration planning
  analytics.track('api_version_usage', {
    version: 'v1',
    endpoint: req.path,
    userId: req.user?.id,
    timestamp: new Date()
  });
  
  // Add deprecation headers
  res.set({
    'Deprecation': 'true',
    'Sunset': 'Tue, 15 Jul 2025 00:00:00 GMT',
    'Link': '<https://api.inventario-pymes.com/v2>; rel="successor-version"'
  });
  
  next();
});
```

### Fase 4: Sunset (EOL)

```http
# Respuesta después del sunset
HTTP/1.1 410 Gone
Content-Type: application/json

{
  "error": "Gone",
  "message": "API v1 has been discontinued",
  "code": "API_VERSION_DISCONTINUED",
  "details": {
    "discontinuedAt": "2025-07-15T00:00:00Z",
    "migrationGuide": "https://docs.inventario-pymes.com/migration/v1-to-v2",
    "supportContact": "migration@inventario-pymes.com"
  }
}
```

---

## 🛠️ Implementación Técnica

### Router Configuration

```javascript
// Express.js routing por versión
const v1Router = require('./routes/v1');
const v2Router = require('./routes/v2');

app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);

// Default to latest version
app.use('/api', v2Router);

// Version negotiation middleware
app.use('/api', (req, res, next) => {
  const acceptVersion = req.headers['accept-version'];
  
  if (acceptVersion) {
    const version = parseVersion(acceptVersion);
    req.apiVersion = version;
    
    // Route to appropriate version
    if (version.major === 1) {
      return v1Router(req, res, next);
    } else if (version.major === 2) {
      return v2Router(req, res, next);
    }
  }
  
  // Default to latest
  return v2Router(req, res, next);
});
```

### Version Detection

```javascript
function parseVersion(versionHeader) {
  // Support formats: "1", "1.2", "v1", "v1.2"
  const match = versionHeader.match(/v?(\d+)(?:\.(\d+))?(?:\.(\d+))?/);
  
  if (!match) {
    throw new Error('Invalid version format');
  }
  
  return {
    major: parseInt(match[1]),
    minor: parseInt(match[2]) || 0,
    patch: parseInt(match[3]) || 0,
    full: `${match[1]}.${match[2] || 0}.${match[3] || 0}`
  };
}
```

### Shared Code Management

```javascript
// Shared business logic
const productService = require('../services/productService');

// v1 controller
exports.getProducts_v1 = async (req, res) => {
  const products = await productService.getProducts(req.query);
  
  // v1 response format
  res.json({
    products: products.map(transformProductV1),
    total: products.length
  });
};

// v2 controller
exports.getProducts_v2 = async (req, res) => {
  const products = await productService.getProducts(req.query);
  
  // v2 response format (JSON:API)
  res.json({
    data: products.map(transformProductV2),
    meta: {
      total: products.length,
      version: '2.0'
    }
  });
};
```

---

## 📊 Monitoreo de Versiones

### Métricas de Uso

```yaml
# Prometheus metrics
api_requests_total{version, endpoint, status}
api_version_adoption_rate{version}
api_deprecated_usage{version, endpoint}
api_migration_progress{from_version, to_version}
```

### Dashboard de Versiones

```javascript
// Endpoint para métricas de versiones
app.get('/admin/api/version-metrics', async (req, res) => {
  const metrics = await getVersionMetrics();
  
  res.json({
    versions: {
      v1: {
        usage: metrics.v1.totalRequests,
        uniqueUsers: metrics.v1.uniqueUsers,
        topEndpoints: metrics.v1.topEndpoints,
        deprecationStatus: 'active'
      },
      v2: {
        usage: metrics.v2.totalRequests,
        uniqueUsers: metrics.v2.uniqueUsers,
        topEndpoints: metrics.v2.topEndpoints,
        deprecationStatus: 'current'
      }
    },
    migration: {
      progress: calculateMigrationProgress(),
      timeline: getMigrationTimeline()
    }
  });
});
```

### Alertas de Migración

```yaml
# Alert rules
- alert: HighDeprecatedAPIUsage
  expr: rate(api_requests_total{version="v1"}[5m]) > 100
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Alto uso de API deprecated v1"
    
- alert: MigrationDeadlineApproaching
  expr: (api_sunset_timestamp - time()) < 2592000  # 30 days
  labels:
    severity: critical
  annotations:
    summary: "Deadline de migración en 30 días"
```

---

## 📖 Documentación por Versión

### Estructura de Documentación

```
docs/
├── v1/
│   ├── openapi.yaml
│   ├── getting-started.md
│   ├── authentication.md
│   ├── endpoints/
│   └── migration-guide.md
├── v2/
│   ├── openapi.yaml
│   ├── getting-started.md
│   ├── whats-new.md
│   └── endpoints/
└── migration/
    ├── v1-to-v2.md
    ├── breaking-changes.md
    └── compatibility-matrix.md
```

### OpenAPI Specification por Versión

```yaml
# v1/openapi.yaml
openapi: 3.0.3
info:
  title: Inventario PYMES API
  version: 1.2.0
  description: |
    ⚠️ **DEPRECATED**: Esta versión será discontinuada el 15 de julio de 2025.
    
    Por favor migre a [API v2](../v2/openapi.yaml).
    
    [Guía de migración](../migration/v1-to-v2.md)

# v2/openapi.yaml
openapi: 3.0.3
info:
  title: Inventario PYMES API
  version: 2.0.0
  description: |
    🆕 **NUEVA VERSIÓN**: Incluye mejoras significativas y nuevas funcionalidades.
    
    [¿Qué hay de nuevo?](whats-new.md)
```

---

## 🔧 Herramientas de Migración

### CLI Tool para Migración

```bash
# Instalar herramienta de migración
npm install -g @inventario-pymes/migration-tool

# Analizar uso actual de API
migration-tool analyze --api-key YOUR_API_KEY

# Generar plan de migración
migration-tool plan --from v1 --to v2

# Validar compatibilidad
migration-tool validate --config migration.json

# Ejecutar migración
migration-tool migrate --dry-run
migration-tool migrate --execute
```

### SDK Compatibility Layer

```javascript
// SDK que maneja múltiples versiones automáticamente
const InventoryAPI = require('@inventario-pymes/sdk');

const client = new InventoryAPI({
  apiKey: 'your-api-key',
  version: 'auto', // Usa la mejor versión disponible
  fallback: 'v1'   // Fallback si v2 falla
});

// El SDK maneja la migración transparentemente
const products = await client.products.list();
```

### Migration Assistant

```javascript
class MigrationAssistant {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.v1Client = new APIClient({ version: 'v1', apiKey });
    this.v2Client = new APIClient({ version: 'v2', apiKey });
  }
  
  async analyzeUsage() {
    const usage = await this.v1Client.admin.getUsageStats();
    
    return {
      totalRequests: usage.totalRequests,
      uniqueEndpoints: usage.endpoints.length,
      migrationComplexity: this.calculateComplexity(usage),
      estimatedEffort: this.estimateEffort(usage),
      recommendations: this.generateRecommendations(usage)
    };
  }
  
  async testMigration(endpoint, params) {
    try {
      const v1Response = await this.v1Client.request(endpoint, params);
      const v2Response = await this.v2Client.request(endpoint, params);
      
      return {
        compatible: this.compareResponses(v1Response, v2Response),
        differences: this.findDifferences(v1Response, v2Response),
        migrationRequired: this.needsMigration(v1Response, v2Response)
      };
    } catch (error) {
      return {
        error: error.message,
        migrationRequired: true
      };
    }
  }
}
```

---

## 🧪 Testing de Versiones

### Contract Testing

```javascript
describe('API Version Compatibility', () => {
  test('v1 and v2 should return compatible data structures', async () => {
    const v1Response = await request(app)
      .get('/api/v1/products')
      .set('Authorization', `Bearer ${token}`);
      
    const v2Response = await request(app)
      .get('/api/v2/products')
      .set('Authorization', `Bearer ${token}`);
    
    // Verify core data is compatible
    expect(v1Response.body.products).toBeDefined();
    expect(v2Response.body.data).toBeDefined();
    
    // Verify data mapping
    const v1Product = v1Response.body.products[0];
    const v2Product = v2Response.body.data[0];
    
    expect(v1Product.id).toBe(v2Product.id);
    expect(v1Product.name).toBe(v2Product.attributes.name);
  });
  
  test('deprecated endpoints should include deprecation headers', async () => {
    const response = await request(app)
      .get('/api/v1/products')
      .set('Authorization', `Bearer ${token}`);
    
    expect(response.headers.deprecation).toBe('true');
    expect(response.headers.sunset).toBeDefined();
    expect(response.headers.link).toContain('successor-version');
  });
});
```

### Load Testing por Versión

```javascript
// k6 script para testing de carga
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  scenarios: {
    v1_load: {
      executor: 'constant-vus',
      vus: 50,
      duration: '5m',
      env: { API_VERSION: 'v1' }
    },
    v2_load: {
      executor: 'constant-vus',
      vus: 50,
      duration: '5m',
      env: { API_VERSION: 'v2' }
    }
  }
};

export default function() {
  const version = __ENV.API_VERSION;
  const response = http.get(`${__ENV.BASE_URL}/api/${version}/products`);
  
  check(response, {
    [`${version} status is 200`]: (r) => r.status === 200,
    [`${version} response time < 500ms`]: (r) => r.timings.duration < 500,
  });
}
```

---

## 📋 Checklist de Nueva Versión

### Pre-Release

- [ ] Análisis de breaking changes
- [ ] Actualización de documentación
- [ ] Creación de guía de migración
- [ ] Testing de compatibilidad
- [ ] Configuración de métricas
- [ ] Preparación de herramientas de migración

### Release

- [ ] Deploy de nueva versión
- [ ] Activación de headers de deprecation
- [ ] Notificación a desarrolladores
- [ ] Publicación de documentación
- [ ] Monitoreo de adopción

### Post-Release

- [ ] Seguimiento de métricas de uso
- [ ] Soporte a migración
- [ ] Corrección de issues reportados
- [ ] Planificación de sunset de versión anterior

---

## 📞 Soporte de Migración

**Migration Support Team:** migration@inventario-pymes.com  
**Documentation:** https://docs.inventario-pymes.com/migration/  
**Community Forum:** https://community.inventario-pymes.com/migration  
**Office Hours:** Martes y Jueves 2:00-4:00 PM COT  

**SLA de Soporte:**
- Consultas generales: 48 horas
- Issues críticos de migración: 4 horas
- Revisión de código: 1 semana

---

**Última actualización:** Enero 2024  
**Versión del documento:** 1.0.0  
**Próxima revisión:** Abril 2024