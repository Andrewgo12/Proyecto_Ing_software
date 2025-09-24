# 📚 API Documentation - Sistema de Inventario PYMES

## 🌐 Información General

**Base URL:** `https://api.inventario-pymes.com/v1`  
**Versión:** 1.0.0  
**Protocolo:** HTTPS  
**Formato:** JSON  
**Autenticación:** JWT Bearer Token  

---

## 🔐 Autenticación

### Flujo de Autenticación

1. **Login:** Obtener tokens de acceso
2. **Uso:** Incluir token en header `Authorization: Bearer {token}`
3. **Renovación:** Usar refresh token cuando expire el access token

### Endpoints de Autenticación

#### POST /auth/login
Autentica un usuario y devuelve tokens JWT.

**Request Body:**
```json
{
  "email": "admin@empresa.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "admin@empresa.com",
    "firstName": "Juan",
    "lastName": "Pérez",
    "role": "admin"
  }
}
```

#### POST /auth/refresh
Renueva el access token usando el refresh token.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 📦 Gestión de Productos

### GET /products
Obtiene lista paginada de productos.

**Query Parameters:**
- `page` (integer, default: 1): Número de página
- `limit` (integer, default: 20): Elementos por página
- `search` (string): Búsqueda por nombre o SKU
- `category` (string): Filtrar por categoría
- `isActive` (boolean): Filtrar por estado activo

**Response (200):**
```json
{
  "data": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "sku": "LAPTOP-001",
      "name": "Laptop Dell Inspiron 15",
      "description": "Laptop para uso empresarial",
      "categoryId": "cat-123",
      "category": {
        "id": "cat-123",
        "name": "Electrónicos"
      },
      "unitPrice": 1500000.00,
      "unitOfMeasure": "unidad",
      "barcode": "7891234567890",
      "isActive": true,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

### POST /products
Crea un nuevo producto.

**Request Body:**
```json
{
  "sku": "LAPTOP-002",
  "name": "Laptop HP Pavilion",
  "description": "Laptop para uso general",
  "categoryId": "cat-123",
  "unitPrice": 1200000.00,
  "unitOfMeasure": "unidad",
  "barcode": "7891234567891"
}
```

**Response (201):**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174001",
  "sku": "LAPTOP-002",
  "name": "Laptop HP Pavilion",
  "description": "Laptop para uso general",
  "categoryId": "cat-123",
  "unitPrice": 1200000.00,
  "unitOfMeasure": "unidad",
  "barcode": "7891234567891",
  "isActive": true,
  "createdAt": "2024-01-15T11:00:00Z",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

### GET /products/{id}
Obtiene un producto específico por ID.

**Path Parameters:**
- `id` (UUID): ID del producto

**Response (200):**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "sku": "LAPTOP-001",
  "name": "Laptop Dell Inspiron 15",
  "description": "Laptop para uso empresarial",
  "categoryId": "cat-123",
  "category": {
    "id": "cat-123",
    "name": "Electrónicos",
    "description": "Productos electrónicos"
  },
  "unitPrice": 1500000.00,
  "unitOfMeasure": "unidad",
  "barcode": "7891234567890",
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### PUT /products/{id}
Actualiza un producto existente.

**Path Parameters:**
- `id` (UUID): ID del producto

**Request Body:**
```json
{
  "name": "Laptop Dell Inspiron 15 - Actualizado",
  "description": "Laptop para uso empresarial con mejoras",
  "unitPrice": 1600000.00
}
```

### DELETE /products/{id}
Elimina un producto (soft delete).

**Path Parameters:**
- `id` (UUID): ID del producto

**Response (204):** No Content

---

## 📊 Gestión de Inventario

### GET /inventory/stock
Obtiene niveles de stock por producto y ubicación.

**Query Parameters:**
- `productId` (UUID): Filtrar por producto específico
- `locationId` (UUID): Filtrar por ubicación específica
- `lowStock` (boolean): Solo productos con stock bajo

**Response (200):**
```json
[
  {
    "id": "stock-123",
    "productId": "123e4567-e89b-12d3-a456-426614174000",
    "product": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "sku": "LAPTOP-001",
      "name": "Laptop Dell Inspiron 15"
    },
    "locationId": "loc-123",
    "location": {
      "id": "loc-123",
      "name": "Bodega Principal",
      "type": "warehouse"
    },
    "quantity": 45.0,
    "reservedQuantity": 5.0,
    "availableQuantity": 40.0,
    "minStock": 10.0,
    "maxStock": 100.0,
    "lastUpdated": "2024-01-15T14:30:00Z"
  }
]
```

### POST /inventory/movements
Registra un nuevo movimiento de inventario.

**Request Body:**
```json
{
  "productId": "123e4567-e89b-12d3-a456-426614174000",
  "locationId": "loc-123",
  "movementType": "in",
  "quantity": 20.0,
  "referenceNumber": "PO-2024-001",
  "notes": "Recepción de mercancía del proveedor ABC"
}
```

**Response (201):**
```json
{
  "id": "mov-123",
  "productId": "123e4567-e89b-12d3-a456-426614174000",
  "product": {
    "sku": "LAPTOP-001",
    "name": "Laptop Dell Inspiron 15"
  },
  "locationId": "loc-123",
  "location": {
    "name": "Bodega Principal"
  },
  "movementType": "in",
  "quantity": 20.0,
  "referenceNumber": "PO-2024-001",
  "notes": "Recepción de mercancía del proveedor ABC",
  "userId": "user-123",
  "user": {
    "firstName": "Juan",
    "lastName": "Pérez"
  },
  "createdAt": "2024-01-15T15:00:00Z"
}
```

### GET /inventory/movements
Obtiene historial de movimientos de inventario.

**Query Parameters:**
- `productId` (UUID): Filtrar por producto
- `locationId` (UUID): Filtrar por ubicación
- `movementType` (string): Filtrar por tipo (in, out, adjustment, transfer)
- `startDate` (date): Fecha inicio del rango
- `endDate` (date): Fecha fin del rango
- `page` (integer): Número de página
- `limit` (integer): Elementos por página

**Response (200):**
```json
[
  {
    "id": "mov-123",
    "productId": "123e4567-e89b-12d3-a456-426614174000",
    "product": {
      "sku": "LAPTOP-001",
      "name": "Laptop Dell Inspiron 15"
    },
    "locationId": "loc-123",
    "location": {
      "name": "Bodega Principal"
    },
    "movementType": "in",
    "quantity": 20.0,
    "referenceNumber": "PO-2024-001",
    "notes": "Recepción de mercancía",
    "userId": "user-123",
    "user": {
      "firstName": "Juan",
      "lastName": "Pérez"
    },
    "createdAt": "2024-01-15T15:00:00Z"
  }
]
```

---

## 📈 Reportes y Analytics

### GET /reports/stock-summary
Genera reporte resumen del estado actual del inventario.

**Query Parameters:**
- `locationId` (UUID): Filtrar por ubicación específica
- `categoryId` (UUID): Filtrar por categoría específica

**Response (200):**
```json
{
  "totalProducts": 150,
  "totalValue": 50000000.00,
  "lowStockProducts": 12,
  "outOfStockProducts": 3,
  "categories": [
    {
      "categoryId": "cat-123",
      "categoryName": "Electrónicos",
      "productCount": 45,
      "totalValue": 25000000.00,
      "averageValue": 555555.56
    },
    {
      "categoryId": "cat-124",
      "categoryName": "Oficina",
      "productCount": 30,
      "totalValue": 15000000.00,
      "averageValue": 500000.00
    }
  ],
  "locations": [
    {
      "locationId": "loc-123",
      "locationName": "Bodega Principal",
      "productCount": 120,
      "totalValue": 40000000.00
    }
  ],
  "generatedAt": "2024-01-15T16:00:00Z"
}
```

### GET /reports/movement-summary
Genera reporte de movimientos por período.

**Query Parameters:**
- `startDate` (date, required): Fecha inicio
- `endDate` (date, required): Fecha fin
- `groupBy` (string): Agrupar por (day, week, month)

**Response (200):**
```json
{
  "period": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-31"
  },
  "summary": {
    "totalMovements": 245,
    "totalIn": 120,
    "totalOut": 100,
    "totalAdjustments": 25,
    "netChange": 20
  },
  "byType": [
    {
      "movementType": "in",
      "count": 120,
      "totalQuantity": 2500.0,
      "percentage": 48.98
    },
    {
      "movementType": "out",
      "count": 100,
      "totalQuantity": 2000.0,
      "percentage": 40.82
    }
  ],
  "timeline": [
    {
      "date": "2024-01-01",
      "movements": 8,
      "totalIn": 5,
      "totalOut": 3
    }
  ]
}
```

---

## 🚨 Manejo de Errores

### Códigos de Estado HTTP

| Código | Descripción | Uso |
|--------|-------------|-----|
| 200 | OK | Operación exitosa |
| 201 | Created | Recurso creado exitosamente |
| 204 | No Content | Operación exitosa sin contenido |
| 400 | Bad Request | Solicitud malformada |
| 401 | Unauthorized | Token inválido o faltante |
| 403 | Forbidden | Sin permisos para la operación |
| 404 | Not Found | Recurso no encontrado |
| 422 | Unprocessable Entity | Error de validación |
| 429 | Too Many Requests | Rate limit excedido |
| 500 | Internal Server Error | Error interno del servidor |

### Formato de Respuestas de Error

```json
{
  "error": "Validation Error",
  "message": "Los datos enviados no son válidos",
  "code": "VALIDATION_ERROR",
  "details": {
    "name": "El campo name es requerido",
    "email": "El formato del email es inválido",
    "unitPrice": "El precio debe ser un número positivo"
  },
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products"
}
```

### Códigos de Error Específicos

| Código | Descripción |
|--------|-------------|
| `VALIDATION_ERROR` | Error en validación de datos |
| `UNAUTHORIZED` | Token inválido o expirado |
| `FORBIDDEN` | Sin permisos suficientes |
| `NOT_FOUND` | Recurso no encontrado |
| `DUPLICATE_ENTRY` | Recurso ya existe |
| `INSUFFICIENT_STOCK` | Stock insuficiente |
| `INVALID_MOVEMENT` | Movimiento de inventario inválido |
| `RATE_LIMIT_EXCEEDED` | Límite de requests excedido |
| `INTERNAL_ERROR` | Error interno del servidor |

---

## 🔒 Seguridad

### Headers Requeridos

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Accept: application/json
```

### Rate Limiting

- **Límite general:** 1000 requests/hora por usuario
- **Login:** 5 intentos/minuto por IP
- **Creación de recursos:** 100 requests/hora
- **Consultas:** 500 requests/hora

### Headers de Respuesta de Rate Limiting

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642262400
```

---

## 📝 Ejemplos de Uso

### Flujo Completo: Crear Producto y Registrar Stock

```bash
# 1. Login
curl -X POST https://api.inventario-pymes.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@empresa.com",
    "password": "password123"
  }'

# 2. Crear producto
curl -X POST https://api.inventario-pymes.com/v1/products \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "MOUSE-001",
    "name": "Mouse Inalámbrico",
    "description": "Mouse inalámbrico ergonómico",
    "categoryId": "cat-123",
    "unitPrice": 45000.00,
    "unitOfMeasure": "unidad",
    "barcode": "7891234567892"
  }'

# 3. Registrar entrada de inventario
curl -X POST https://api.inventario-pymes.com/v1/inventory/movements \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "{product_id}",
    "locationId": "loc-123",
    "movementType": "in",
    "quantity": 100,
    "referenceNumber": "PO-2024-002",
    "notes": "Stock inicial"
  }'

# 4. Consultar stock actual
curl -X GET "https://api.inventario-pymes.com/v1/inventory/stock?productId={product_id}" \
  -H "Authorization: Bearer {token}"
```

### Búsqueda Avanzada de Productos

```bash
# Buscar productos por nombre
curl -X GET "https://api.inventario-pymes.com/v1/products?search=laptop&page=1&limit=10" \
  -H "Authorization: Bearer {token}"

# Filtrar por categoría y estado
curl -X GET "https://api.inventario-pymes.com/v1/products?category=electronics&isActive=true" \
  -H "Authorization: Bearer {token}"
```

---

## 🔄 Versionado de API

### Estrategia de Versionado
- **URL Path:** `/v1/`, `/v2/`
- **Backward Compatibility:** Mantenida por 12 meses
- **Deprecation Notice:** 6 meses antes de remover versión

### Versiones Disponibles
- **v1.0:** Versión actual (estable)
- **v1.1:** En desarrollo (beta)

---

## 📞 Soporte y Contacto

**Documentación:** https://docs.inventario-pymes.com  
**Status Page:** https://status.inventario-pymes.com  
**Soporte Técnico:** dev@inventario-pymes.com  
**Slack Community:** https://inventario-pymes.slack.com  

**Horarios de Soporte:**
- Lunes a Viernes: 8:00 AM - 6:00 PM (COT)
- Emergencias: 24/7 para clientes enterprise

---

**Última actualización:** Enero 2024  
**Versión del documento:** 1.0.0