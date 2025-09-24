# 🚨 Catálogo de Códigos de Error
## Sistema de Inventario PYMES API

---

## 📋 Información General

**Formato de Error:** JSON estructurado  
**Códigos HTTP:** Estándar RFC 7231  
**Idiomas:** Español (es), Inglés (en)  
**Logging:** Todos los errores se registran con ID único  

---

## 🏗️ Estructura de Respuesta de Error

### Formato Estándar

```json
{
  "error": "Error Type",
  "message": "Descripción legible del error",
  "code": "ERROR_CODE_CONSTANT",
  "details": {
    "field": "Detalle específico del campo",
    "constraint": "Restricción violada"
  },
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products",
  "requestId": "req-123e4567-e89b-12d3-a456-426614174000",
  "documentation": "https://docs.inventario-pymes.com/errors/ERROR_CODE_CONSTANT"
}
```

### Campos Explicados

| Campo | Tipo | Descripción | Requerido |
|-------|------|-------------|-----------|
| `error` | string | Tipo de error legible | ✅ |
| `message` | string | Descripción detallada | ✅ |
| `code` | string | Código único del error | ✅ |
| `details` | object | Información adicional | ❌ |
| `timestamp` | string | Timestamp ISO 8601 | ✅ |
| `path` | string | Endpoint donde ocurrió | ✅ |
| `requestId` | string | ID único de la request | ✅ |
| `documentation` | string | URL de documentación | ❌ |

---

## 🔢 Códigos de Error por Categoría

### 4xx - Errores del Cliente

#### 400 - Bad Request

| Código | Descripción | Solución |
|--------|-------------|----------|
| `INVALID_REQUEST_FORMAT` | Formato de request inválido | Verificar Content-Type y estructura JSON |
| `MISSING_REQUIRED_FIELD` | Campo requerido faltante | Incluir todos los campos obligatorios |
| `INVALID_FIELD_TYPE` | Tipo de dato incorrecto | Verificar tipos de datos según documentación |
| `INVALID_FIELD_VALUE` | Valor de campo inválido | Usar valores permitidos según especificación |
| `REQUEST_TOO_LARGE` | Request excede tamaño máximo | Reducir tamaño del payload |
| `INVALID_JSON_SYNTAX` | JSON malformado | Validar sintaxis JSON |

**Ejemplo:**
```json
{
  "error": "Bad Request",
  "message": "El campo 'unitPrice' debe ser un número positivo",
  "code": "INVALID_FIELD_VALUE",
  "details": {
    "field": "unitPrice",
    "value": -100,
    "constraint": "must be positive number"
  },
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products",
  "requestId": "req-abc123"
}
```

#### 401 - Unauthorized

| Código | Descripción | Solución |
|--------|-------------|----------|
| `MISSING_AUTHORIZATION` | Header Authorization faltante | Incluir header Authorization |
| `INVALID_TOKEN_FORMAT` | Formato de token incorrecto | Usar formato Bearer {token} |
| `TOKEN_EXPIRED` | Token JWT expirado | Renovar token usando refresh endpoint |
| `TOKEN_INVALID` | Token JWT inválido | Obtener nuevo token mediante login |
| `TOKEN_REVOKED` | Token revocado | Realizar login nuevamente |
| `INVALID_CREDENTIALS` | Credenciales incorrectas | Verificar email y contraseña |
| `ACCOUNT_LOCKED` | Cuenta bloqueada | Contactar administrador |
| `ACCOUNT_DISABLED` | Cuenta deshabilitada | Contactar administrador |

**Ejemplo:**
```json
{
  "error": "Unauthorized",
  "message": "Token JWT ha expirado",
  "code": "TOKEN_EXPIRED",
  "details": {
    "expiredAt": "2024-01-15T15:30:00Z",
    "currentTime": "2024-01-15T16:30:00Z"
  },
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products",
  "requestId": "req-def456",
  "documentation": "https://docs.inventario-pymes.com/auth/token-refresh"
}
```

#### 403 - Forbidden

| Código | Descripción | Solución |
|--------|-------------|----------|
| `INSUFFICIENT_PERMISSIONS` | Sin permisos suficientes | Contactar administrador para permisos |
| `RESOURCE_ACCESS_DENIED` | Acceso denegado al recurso | Verificar ownership del recurso |
| `OPERATION_NOT_ALLOWED` | Operación no permitida | Verificar estado del recurso |
| `IP_BLOCKED` | IP bloqueada | Contactar soporte técnico |
| `MAINTENANCE_MODE` | Sistema en mantenimiento | Esperar fin de mantenimiento |

#### 404 - Not Found

| Código | Descripción | Solución |
|--------|-------------|----------|
| `RESOURCE_NOT_FOUND` | Recurso no encontrado | Verificar ID del recurso |
| `ENDPOINT_NOT_FOUND` | Endpoint no existe | Verificar URL y versión de API |
| `USER_NOT_FOUND` | Usuario no encontrado | Verificar ID de usuario |
| `PRODUCT_NOT_FOUND` | Producto no encontrado | Verificar ID de producto |
| `LOCATION_NOT_FOUND` | Ubicación no encontrada | Verificar ID de ubicación |

#### 409 - Conflict

| Código | Descripción | Solución |
|--------|-------------|----------|
| `RESOURCE_ALREADY_EXISTS` | Recurso ya existe | Usar endpoint de actualización |
| `DUPLICATE_SKU` | SKU duplicado | Usar SKU único |
| `DUPLICATE_EMAIL` | Email ya registrado | Usar email diferente |
| `CONCURRENT_MODIFICATION` | Modificación concurrente | Recargar y reintentar |
| `STOCK_CONFLICT` | Conflicto de stock | Verificar disponibilidad actual |

#### 422 - Unprocessable Entity

| Código | Descripción | Solución |
|--------|-------------|----------|
| `VALIDATION_ERROR` | Error de validación | Corregir campos según detalles |
| `BUSINESS_RULE_VIOLATION` | Violación de regla de negocio | Verificar reglas específicas |
| `INSUFFICIENT_STOCK` | Stock insuficiente | Verificar disponibilidad |
| `INVALID_MOVEMENT_TYPE` | Tipo de movimiento inválido | Usar tipos permitidos |
| `INVALID_DATE_RANGE` | Rango de fechas inválido | Verificar fechas de inicio y fin |

**Ejemplo:**
```json
{
  "error": "Unprocessable Entity",
  "message": "Errores de validación en los datos enviados",
  "code": "VALIDATION_ERROR",
  "details": {
    "name": "El nombre es requerido",
    "unitPrice": "El precio debe ser mayor a 0",
    "sku": "El SKU debe tener entre 3 y 20 caracteres"
  },
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products",
  "requestId": "req-ghi789"
}
```

#### 429 - Too Many Requests

| Código | Descripción | Solución |
|--------|-------------|----------|
| `RATE_LIMIT_EXCEEDED` | Límite de requests excedido | Esperar hasta reset del límite |
| `LOGIN_RATE_LIMIT` | Demasiados intentos de login | Esperar 15 minutos |
| `BULK_OPERATION_LIMIT` | Límite de operaciones masivas | Reducir tamaño del lote |
| `EXPORT_RATE_LIMIT` | Límite de exportaciones | Esperar 1 hora |

---

### 5xx - Errores del Servidor

#### 500 - Internal Server Error

| Código | Descripción | Acción |
|--------|-------------|--------|
| `INTERNAL_SERVER_ERROR` | Error interno del servidor | Reportar a soporte técnico |
| `DATABASE_ERROR` | Error de base de datos | Reintentar en unos minutos |
| `EXTERNAL_SERVICE_ERROR` | Error en servicio externo | Verificar estado de servicios |
| `CONFIGURATION_ERROR` | Error de configuración | Contactar administrador |

#### 502 - Bad Gateway

| Código | Descripción | Acción |
|--------|-------------|--------|
| `UPSTREAM_SERVICE_ERROR` | Servicio upstream no disponible | Reintentar más tarde |
| `GATEWAY_TIMEOUT` | Timeout en gateway | Reintentar con timeout mayor |

#### 503 - Service Unavailable

| Código | Descripción | Acción |
|--------|-------------|--------|
| `SERVICE_TEMPORARILY_UNAVAILABLE` | Servicio temporalmente no disponible | Reintentar más tarde |
| `MAINTENANCE_MODE` | Sistema en mantenimiento | Esperar fin de mantenimiento |
| `OVERLOADED` | Sistema sobrecargado | Reducir frecuencia de requests |

---

## 🎯 Errores Específicos del Dominio

### Gestión de Productos

| Código | HTTP | Descripción |
|--------|-----|-------------|
| `PRODUCT_SKU_DUPLICATE` | 409 | SKU ya existe en el sistema |
| `PRODUCT_CATEGORY_INVALID` | 422 | Categoría no válida o no existe |
| `PRODUCT_PRICE_INVALID` | 422 | Precio debe ser mayor a 0 |
| `PRODUCT_IN_USE` | 409 | Producto tiene movimientos, no se puede eliminar |
| `PRODUCT_BARCODE_INVALID` | 422 | Código de barras no válido |

### Gestión de Inventario

| Código | HTTP | Descripción |
|--------|-----|-------------|
| `INSUFFICIENT_STOCK` | 422 | Stock insuficiente para la operación |
| `NEGATIVE_STOCK_NOT_ALLOWED` | 422 | No se permite stock negativo |
| `INVALID_MOVEMENT_TYPE` | 422 | Tipo de movimiento no válido |
| `LOCATION_NOT_ACTIVE` | 422 | Ubicación no está activa |
| `MOVEMENT_ALREADY_PROCESSED` | 409 | Movimiento ya fue procesado |
| `STOCK_RESERVED` | 409 | Stock está reservado |

### Autenticación y Autorización

| Código | HTTP | Descripción |
|--------|-----|-------------|
| `PASSWORD_TOO_WEAK` | 422 | Contraseña no cumple requisitos |
| `EMAIL_NOT_VERIFIED` | 403 | Email no verificado |
| `ACCOUNT_SUSPENDED` | 403 | Cuenta suspendida |
| `SESSION_EXPIRED` | 401 | Sesión expirada |
| `INVALID_REFRESH_TOKEN` | 401 | Refresh token inválido |

### Reportes

| Código | HTTP | Descripción |
|--------|-----|-------------|
| `REPORT_GENERATION_FAILED` | 500 | Error generando reporte |
| `REPORT_TOO_LARGE` | 422 | Reporte excede tamaño máximo |
| `INVALID_DATE_RANGE` | 422 | Rango de fechas inválido |
| `NO_DATA_AVAILABLE` | 404 | No hay datos para el período |

---

## 🌐 Internacionalización de Errores

### Soporte Multi-idioma

```http
# Request con header de idioma
GET /api/v1/products/invalid-id
Accept-Language: es-CO

# Response en español
{
  "error": "No Encontrado",
  "message": "El producto solicitado no existe",
  "code": "PRODUCT_NOT_FOUND"
}
```

```http
# Request en inglés
GET /api/v1/products/invalid-id
Accept-Language: en-US

# Response en inglés
{
  "error": "Not Found",
  "message": "The requested product does not exist",
  "code": "PRODUCT_NOT_FOUND"
}
```

### Mensajes por Idioma

```javascript
const errorMessages = {
  'es-CO': {
    PRODUCT_NOT_FOUND: 'El producto solicitado no existe',
    INSUFFICIENT_STOCK: 'Stock insuficiente para completar la operación',
    VALIDATION_ERROR: 'Los datos enviados contienen errores'
  },
  'en-US': {
    PRODUCT_NOT_FOUND: 'The requested product does not exist',
    INSUFFICIENT_STOCK: 'Insufficient stock to complete the operation',
    VALIDATION_ERROR: 'The submitted data contains errors'
  }
};
```

---

## 🔍 Debugging y Troubleshooting

### Request ID para Tracking

```javascript
// Middleware para generar request ID
app.use((req, res, next) => {
  req.requestId = `req-${uuidv4()}`;
  res.set('X-Request-ID', req.requestId);
  next();
});

// Incluir en logs
logger.error('Database connection failed', {
  requestId: req.requestId,
  userId: req.user?.id,
  endpoint: req.path,
  error: error.message
});
```

### Error Context

```json
{
  "error": "Internal Server Error",
  "message": "Error interno del servidor",
  "code": "DATABASE_ERROR",
  "details": {
    "operation": "SELECT products",
    "table": "products",
    "constraint": "foreign_key_violation"
  },
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products",
  "requestId": "req-123e4567",
  "context": {
    "userId": "user-456",
    "userRole": "manager",
    "clientVersion": "1.2.0",
    "userAgent": "InventoryApp/1.0.0"
  }
}
```

---

## 📊 Monitoreo de Errores

### Métricas de Error

```yaml
# Prometheus metrics
api_errors_total{code, endpoint, status}
api_error_rate{endpoint}
api_error_duration{code}
api_client_errors_total{user_id, code}
```

### Alertas Automáticas

```yaml
# Alert rules
- alert: HighErrorRate
  expr: rate(api_errors_total[5m]) > 10
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Alta tasa de errores en API"
    
- alert: CriticalError
  expr: increase(api_errors_total{status="500"}[1m]) > 5
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Errores críticos del servidor"
```

---

## 🛠️ Manejo de Errores en Cliente

### JavaScript/TypeScript

```typescript
class APIError extends Error {
  constructor(
    public code: string,
    public message: string,
    public status: number,
    public details?: any,
    public requestId?: string
  ) {
    super(message);
    this.name = 'APIError';
  }
  
  static fromResponse(response: Response, data: any): APIError {
    return new APIError(
      data.code,
      data.message,
      response.status,
      data.details,
      data.requestId
    );
  }
  
  isRetryable(): boolean {
    return this.status >= 500 || this.code === 'RATE_LIMIT_EXCEEDED';
  }
  
  getRetryDelay(): number {
    if (this.code === 'RATE_LIMIT_EXCEEDED') {
      return this.details?.retryAfter * 1000 || 60000;
    }
    return Math.min(1000 * Math.pow(2, this.retryCount || 0), 30000);
  }
}

// Uso en cliente
async function handleAPICall(apiCall: () => Promise<Response>) {
  try {
    const response = await apiCall();
    
    if (!response.ok) {
      const errorData = await response.json();
      throw APIError.fromResponse(response, errorData);
    }
    
    return await response.json();
  } catch (error) {
    if (error instanceof APIError) {
      // Manejo específico por código de error
      switch (error.code) {
        case 'TOKEN_EXPIRED':
          await refreshToken();
          return handleAPICall(apiCall); // Retry
          
        case 'INSUFFICIENT_PERMISSIONS':
          showPermissionError();
          break;
          
        case 'VALIDATION_ERROR':
          showValidationErrors(error.details);
          break;
          
        default:
          if (error.isRetryable()) {
            await delay(error.getRetryDelay());
            return handleAPICall(apiCall); // Retry
          }
          showGenericError(error);
      }
    }
    
    throw error;
  }
}
```

### Error Recovery Strategies

```typescript
class ErrorRecoveryService {
  private retryStrategies = new Map([
    ['TOKEN_EXPIRED', this.refreshTokenAndRetry],
    ['RATE_LIMIT_EXCEEDED', this.waitAndRetry],
    ['NETWORK_ERROR', this.exponentialBackoffRetry],
    ['VALIDATION_ERROR', this.showValidationUI]
  ]);
  
  async handleError(error: APIError, originalRequest: () => Promise<any>) {
    const strategy = this.retryStrategies.get(error.code);
    
    if (strategy) {
      return await strategy.call(this, error, originalRequest);
    }
    
    // Default error handling
    this.logError(error);
    this.showUserFriendlyMessage(error);
  }
  
  private async refreshTokenAndRetry(error: APIError, originalRequest: () => Promise<any>) {
    try {
      await this.authService.refreshToken();
      return await originalRequest();
    } catch (refreshError) {
      this.redirectToLogin();
    }
  }
  
  private async waitAndRetry(error: APIError, originalRequest: () => Promise<any>) {
    const delay = error.details?.retryAfter * 1000 || 60000;
    await this.delay(delay);
    return await originalRequest();
  }
}
```

---

## 📋 Checklist de Implementación

### Para Desarrolladores Backend

- [ ] Implementar estructura estándar de error
- [ ] Generar request IDs únicos
- [ ] Configurar logging estructurado
- [ ] Implementar códigos de error específicos
- [ ] Agregar contexto útil en errores
- [ ] Configurar monitoreo y alertas
- [ ] Documentar todos los códigos de error

### Para Desarrolladores Frontend

- [ ] Crear clase de error personalizada
- [ ] Implementar manejo específico por código
- [ ] Configurar retry automático
- [ ] Mostrar mensajes user-friendly
- [ ] Implementar error recovery
- [ ] Logging de errores del cliente
- [ ] Testing de escenarios de error

---

## 📞 Soporte y Escalación

**Niveles de Soporte:**

1. **Errores 4xx:** Documentación y community forum
2. **Errores 5xx:** Ticket de soporte técnico
3. **Errores críticos:** Escalación inmediata

**Información Requerida:**
- Request ID
- Timestamp del error
- Endpoint afectado
- Pasos para reproducir
- Logs del cliente (si aplica)

**Contactos:**
- **Soporte General:** support@inventario-pymes.com
- **Soporte Técnico:** tech-support@inventario-pymes.com
- **Emergencias:** +57 1 234-5678

---

**Última actualización:** Enero 2024  
**Versión:** 1.0.0  
**Próxima revisión:** Marzo 2024