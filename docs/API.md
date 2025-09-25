# 🔌 API Reference - Sistema Inventario PYMES

## 📋 Información General

- **Base URL**: `https://api.inventariopymes.com/api`
- **Versión**: v1.0.0
- **Formato**: JSON
- **Autenticación**: JWT Bearer Token
- **Rate Limit**: 1000 requests/hour

## 🔐 Autenticación

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "role": "manager"
    },
    "accessToken": "eyJhbGciOiJSUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJSUzI1NiIs..."
  }
}
```

### Refresh Token
```http
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJSUzI1NiIs..."
}
```

## 📦 Productos

### Listar Productos
```http
GET /products?page=1&limit=10&search=camisa&category=ropa
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "sku": "CAM-001",
      "name": "Camisa Polo Azul",
      "description": "Camisa polo de algodón",
      "category_id": "uuid",
      "unit_price": 45000,
      "cost_price": 25000,
      "barcode": "1234567890123",
      "is_active": true,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 150,
    "pages": 15
  }
}
```

### Crear Producto
```http
POST /products
Authorization: Bearer <token>
Content-Type: application/json

{
  "sku": "CAM-002",
  "name": "Camisa Polo Roja",
  "description": "Camisa polo de algodón color rojo",
  "category_id": "uuid",
  "unit_price": 45000,
  "cost_price": 25000,
  "barcode": "1234567890124"
}
```

### Obtener Producto
```http
GET /products/{id}
Authorization: Bearer <token>
```

### Actualizar Producto
```http
PUT /products/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Camisa Polo Roja Actualizada",
  "unit_price": 47000
}
```

### Eliminar Producto
```http
DELETE /products/{id}
Authorization: Bearer <token>
```

## 📊 Inventario

### Obtener Stock
```http
GET /inventory/stock?location_id=uuid&low_stock=true
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "product_id": "uuid",
      "product_name": "Camisa Polo Azul",
      "product_sku": "CAM-001",
      "location_id": "uuid",
      "location_name": "Almacén Principal",
      "quantity": 15,
      "min_stock_level": 10,
      "max_stock_level": 100,
      "last_movement_at": "2024-01-15T09:00:00Z"
    }
  ]
}
```

### Crear Movimiento
```http
POST /inventory/movements
Authorization: Bearer <token>
Content-Type: application/json

{
  "product_id": "uuid",
  "location_id": "uuid",
  "movement_type": "IN",
  "quantity": 50,
  "reference_number": "PO-2024-001",
  "notes": "Compra a proveedor ABC"
}
```

### Listar Movimientos
```http
GET /inventory/movements?product_id=uuid&start_date=2024-01-01&end_date=2024-01-31
Authorization: Bearer <token>
```

### Ajustar Stock
```http
POST /inventory/adjust
Authorization: Bearer <token>
Content-Type: application/json

{
  "product_id": "uuid",
  "location_id": "uuid",
  "new_quantity": 25,
  "reason": "Conteo físico",
  "notes": "Ajuste por inventario físico"
}
```

### Transferir Stock
```http
POST /inventory/transfer
Authorization: Bearer <token>
Content-Type: application/json

{
  "product_id": "uuid",
  "from_location_id": "uuid",
  "to_location_id": "uuid",
  "quantity": 10,
  "notes": "Transferencia entre tiendas"
}
```

## 📈 Reportes

### Dashboard Metrics
```http
GET /reports/dashboard
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "inventory": {
      "total_products": 1247,
      "total_value": 2450000,
      "low_stock_count": 23
    },
    "movements": {
      "total_movements": 156,
      "inbound_quantity": 1200,
      "outbound_quantity": 800
    },
    "alerts": {
      "low_stock_count": 23,
      "out_of_stock_count": 5
    }
  }
}
```

### Reporte de Inventario
```http
GET /reports/inventory?location_id=uuid&format=json
Authorization: Bearer <token>
```

### Reporte de Movimientos
```http
GET /reports/movements?start_date=2024-01-01&end_date=2024-01-31&format=csv
Authorization: Bearer <token>
```

### Reporte de Valorización
```http
GET /reports/valuation?location_id=uuid
Authorization: Bearer <token>
```

## 🏢 Ubicaciones

### Listar Ubicaciones
```http
GET /locations
Authorization: Bearer <token>
```

### Crear Ubicación
```http
POST /locations
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Tienda Centro",
  "address": "Calle 123 #45-67",
  "city": "Bogotá",
  "type": "store"
}
```

## 🏷️ Categorías

### Listar Categorías
```http
GET /categories
Authorization: Bearer <token>
```

### Crear Categoría
```http
POST /categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Ropa",
  "description": "Productos de vestir",
  "parent_id": null
}
```

## 👥 Usuarios

### Listar Usuarios (Admin)
```http
GET /users
Authorization: Bearer <admin-token>
```

### Crear Usuario (Admin)
```http
POST /users
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "email": "nuevo@example.com",
  "password": "password123",
  "first_name": "Juan",
  "last_name": "Pérez",
  "role": "warehouse"
}
```

## 🔍 Búsqueda

### Búsqueda Global
```http
GET /search?q=camisa&type=products&limit=10
Authorization: Bearer <token>
```

### Búsqueda por Código de Barras
```http
GET /products/search?barcode=1234567890123
Authorization: Bearer <token>
```

## 📊 Códigos de Estado HTTP

| Código | Descripción |
|--------|-------------|
| 200 | OK - Solicitud exitosa |
| 201 | Created - Recurso creado |
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - Token inválido |
| 403 | Forbidden - Sin permisos |
| 404 | Not Found - Recurso no encontrado |
| 409 | Conflict - Recurso duplicado |
| 422 | Unprocessable Entity - Validación fallida |
| 429 | Too Many Requests - Rate limit excedido |
| 500 | Internal Server Error - Error del servidor |

## 🚨 Manejo de Errores

### Formato de Error Estándar
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Los datos proporcionados no son válidos",
    "details": {
      "sku": "SKU ya existe",
      "price": "Precio debe ser mayor a 0"
    }
  }
}
```

### Códigos de Error Comunes
- `VALIDATION_ERROR`: Error de validación
- `AUTHENTICATION_ERROR`: Error de autenticación
- `AUTHORIZATION_ERROR`: Sin permisos
- `RESOURCE_NOT_FOUND`: Recurso no encontrado
- `DUPLICATE_RESOURCE`: Recurso duplicado
- `INSUFFICIENT_STOCK`: Stock insuficiente
- `RATE_LIMIT_EXCEEDED`: Límite de requests excedido

## 📝 Ejemplos de Uso

### JavaScript/Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'https://api.inventariopymes.com/api',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

// Obtener productos
const products = await api.get('/products');

// Crear movimiento
const movement = await api.post('/inventory/movements', {
  product_id: 'uuid',
  location_id: 'uuid',
  movement_type: 'IN',
  quantity: 10
});
```

### Python
```python
import requests

headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

# Obtener stock
response = requests.get(
    'https://api.inventariopymes.com/api/inventory/stock',
    headers=headers
)
stock = response.json()
```

### cURL
```bash
# Login
curl -X POST https://api.inventariopymes.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Obtener productos
curl -X GET https://api.inventariopymes.com/api/products \
  -H "Authorization: Bearer <token>"
```

## 🔄 Webhooks

### Configurar Webhook
```http
POST /webhooks
Authorization: Bearer <token>
Content-Type: application/json

{
  "url": "https://mi-sistema.com/webhook",
  "events": ["product.created", "stock.low", "movement.created"],
  "secret": "mi-secret-key"
}
```

### Eventos Disponibles
- `product.created`: Producto creado
- `product.updated`: Producto actualizado
- `stock.low`: Stock bajo
- `stock.out`: Stock agotado
- `movement.created`: Movimiento creado

## 📚 SDKs Disponibles

- **JavaScript**: `npm install @inventario-pymes/js-sdk`
- **Python**: `pip install inventario-pymes-sdk`
- **PHP**: `composer require inventario-pymes/php-sdk`

## 🆘 Soporte

- **Documentación**: https://docs.inventariopymes.com
- **Email**: api-support@inventariopymes.com
- **Status**: https://status.inventariopymes.com

---

*Para más ejemplos y documentación detallada, visita nuestra [documentación completa](https://docs.inventariopymes.com).*