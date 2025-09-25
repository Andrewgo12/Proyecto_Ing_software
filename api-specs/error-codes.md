# 🚨 Catálogo de Códigos de Error - API Inventario PYMES

## 📋 Códigos de Error Generales

### 1xx - Información
| Código | Nombre | Descripción |
|--------|--------|-------------|
| 100 | Continue | Continuar con la solicitud |

### 2xx - Éxito
| Código | Nombre | Descripción |
|--------|--------|-------------|
| 200 | OK | Solicitud exitosa |
| 201 | Created | Recurso creado exitosamente |
| 204 | No Content | Solicitud exitosa sin contenido |

### 4xx - Errores del Cliente
| Código | Nombre | Descripción |
|--------|--------|-------------|
| 400 | Bad Request | Solicitud malformada |
| 401 | Unauthorized | No autenticado |
| 403 | Forbidden | Sin permisos |
| 404 | Not Found | Recurso no encontrado |
| 409 | Conflict | Conflicto con estado actual |
| 422 | Unprocessable Entity | Error de validación |
| 429 | Too Many Requests | Límite de rate excedido |

### 5xx - Errores del Servidor
| Código | Nombre | Descripción |
|--------|--------|-------------|
| 500 | Internal Server Error | Error interno |
| 502 | Bad Gateway | Gateway inválido |
| 503 | Service Unavailable | Servicio no disponible |

## 🔐 Códigos de Autenticación

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| AUTH_001 | Invalid credentials | Credenciales inválidas |
| AUTH_002 | Token expired | Token expirado |
| AUTH_003 | Token invalid | Token inválido |
| AUTH_004 | Account locked | Cuenta bloqueada |
| AUTH_005 | Password too weak | Contraseña muy débil |

## 📦 Códigos de Productos

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| PROD_001 | SKU already exists | SKU ya existe |
| PROD_002 | Product not found | Producto no encontrado |
| PROD_003 | Invalid barcode | Código de barras inválido |
| PROD_004 | Category required | Categoría requerida |
| PROD_005 | Price invalid | Precio inválido |

## 📊 Códigos de Inventario

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| INV_001 | Insufficient stock | Stock insuficiente |
| INV_002 | Location not found | Ubicación no encontrada |
| INV_003 | Invalid movement type | Tipo de movimiento inválido |
| INV_004 | Negative quantity | Cantidad negativa |
| INV_005 | Stock level not found | Nivel de stock no encontrado |

## 👥 Códigos de Usuarios

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| USER_001 | Email already exists | Email ya existe |
| USER_002 | User not found | Usuario no encontrado |
| USER_003 | Invalid role | Rol inválido |
| USER_004 | Permission denied | Permiso denegado |
| USER_005 | Account inactive | Cuenta inactiva |

## 📈 Códigos de Reportes

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| REP_001 | Invalid date range | Rango de fechas inválido |
| REP_002 | No data found | No se encontraron datos |
| REP_003 | Export failed | Falló la exportación |
| REP_004 | Format not supported | Formato no soportado |

## 🔧 Códigos de Sistema

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| SYS_001 | Database connection failed | Falló conexión a BD |
| SYS_002 | Cache unavailable | Cache no disponible |
| SYS_003 | External service error | Error servicio externo |
| SYS_004 | Configuration error | Error de configuración |
| SYS_005 | Maintenance mode | Modo mantenimiento |

## 📝 Formato de Respuesta de Error

```json
{
  "success": false,
  "error": {
    "code": "PROD_001",
    "message": "SKU already exists",
    "details": {
      "field": "sku",
      "value": "CAM-001",
      "suggestion": "Use a different SKU"
    },
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_123456789"
  }
}
```

## 🔍 Debugging

### Headers de Debug
```http
X-Request-ID: req_123456789
X-Error-Code: PROD_001
X-Timestamp: 2024-01-15T10:30:00Z
```

### Logs de Error
```json
{
  "level": "error",
  "code": "PROD_001",
  "message": "SKU already exists",
  "request_id": "req_123456789",
  "user_id": "user_456",
  "endpoint": "/api/products",
  "method": "POST",
  "timestamp": "2024-01-15T10:30:00Z"
}
```