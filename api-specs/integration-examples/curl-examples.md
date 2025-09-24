# 🔧 Ejemplos cURL - Sistema de Inventario PYMES

## 🚀 Configuración Inicial

### Variables de Entorno

```bash
# Configurar variables base
export BASE_URL="https://api.inventario-pymes.com/v1"
export EMAIL="admin@empresa.com"
export PASSWORD="password123"
export ACCESS_TOKEN=""
export REFRESH_TOKEN=""
```

---

## 🔐 Autenticación

### Login

```bash
# Realizar login y obtener tokens
curl -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'"
  }' | jq '.'

# Guardar tokens en variables
RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'"
  }')

export ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.accessToken')
export REFRESH_TOKEN=$(echo $RESPONSE | jq -r '.refreshToken')

echo "Access Token: $ACCESS_TOKEN"
echo "Refresh Token: $REFRESH_TOKEN"
```

### Renovar Token

```bash
# Renovar access token
curl -X POST "$BASE_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "'$REFRESH_TOKEN'"
  }' | jq '.'

# Actualizar access token
NEW_TOKEN=$(curl -s -X POST "$BASE_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "'$REFRESH_TOKEN'"}' | jq -r '.accessToken')

export ACCESS_TOKEN=$NEW_TOKEN
```

### Logout

```bash
# Cerrar sesión
curl -X POST "$BASE_URL/auth/logout" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "'$REFRESH_TOKEN'"
  }'
```

---

## 📦 Gestión de Productos

### Listar Productos

```bash
# Obtener todos los productos (paginado)
curl -X GET "$BASE_URL/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/json" | jq '.'

# Con parámetros de paginación
curl -X GET "$BASE_URL/products?page=1&limit=10" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Buscar productos
curl -X GET "$BASE_URL/products?search=laptop&category=electronics" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Filtrar productos activos
curl -X GET "$BASE_URL/products?isActive=true" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Crear Producto

```bash
# Crear nuevo producto
curl -X POST "$BASE_URL/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "LAPTOP-001",
    "name": "Laptop Dell Inspiron 15",
    "description": "Laptop para uso empresarial con procesador Intel i5",
    "categoryId": "123e4567-e89b-12d3-a456-426614174000",
    "unitPrice": 1500000.00,
    "unitOfMeasure": "unidad",
    "barcode": "7891234567890"
  }' | jq '.'

# Guardar ID del producto creado
PRODUCT_ID=$(curl -s -X POST "$BASE_URL/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "MOUSE-001",
    "name": "Mouse Inalámbrico",
    "description": "Mouse inalámbrico ergonómico",
    "categoryId": "123e4567-e89b-12d3-a456-426614174000",
    "unitPrice": 45000.00,
    "unitOfMeasure": "unidad",
    "barcode": "7891234567891"
  }' | jq -r '.id')

echo "Producto creado con ID: $PRODUCT_ID"
```

### Obtener Producto Específico

```bash
# Obtener producto por ID
curl -X GET "$BASE_URL/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Obtener producto por SKU (usando búsqueda)
curl -X GET "$BASE_URL/products?search=LAPTOP-001" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.data[0]'
```

### Actualizar Producto

```bash
# Actualizar producto completo
curl -X PUT "$BASE_URL/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mouse Inalámbrico Premium",
    "description": "Mouse inalámbrico ergonómico con tecnología avanzada",
    "unitPrice": 55000.00
  }' | jq '.'

# Actualización parcial
curl -X PATCH "$BASE_URL/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "unitPrice": 50000.00
  }' | jq '.'
```

### Eliminar Producto

```bash
# Eliminar producto (soft delete)
curl -X DELETE "$BASE_URL/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Verificar eliminación
curl -X GET "$BASE_URL/products/$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

---

## 📊 Gestión de Inventario

### Consultar Stock

```bash
# Obtener todos los niveles de stock
curl -X GET "$BASE_URL/inventory/stock" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Stock de producto específico
curl -X GET "$BASE_URL/inventory/stock?productId=$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Stock por ubicación
curl -X GET "$BASE_URL/inventory/stock?locationId=123e4567-e89b-12d3-a456-426614174001" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Productos con stock bajo
curl -X GET "$BASE_URL/inventory/stock?lowStock=true" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Registrar Movimientos de Inventario

```bash
# Entrada de inventario
curl -X POST "$BASE_URL/inventory/movements" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "'$PRODUCT_ID'",
    "locationId": "123e4567-e89b-12d3-a456-426614174001",
    "movementType": "in",
    "quantity": 100,
    "referenceNumber": "PO-2024-001",
    "notes": "Recepción inicial de inventario"
  }' | jq '.'

# Salida de inventario
curl -X POST "$BASE_URL/inventory/movements" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "'$PRODUCT_ID'",
    "locationId": "123e4567-e89b-12d3-a456-426614174001",
    "movementType": "out",
    "quantity": 10,
    "referenceNumber": "SO-2024-001",
    "notes": "Venta a cliente"
  }' | jq '.'

# Ajuste de inventario
curl -X POST "$BASE_URL/inventory/movements" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "'$PRODUCT_ID'",
    "locationId": "123e4567-e89b-12d3-a456-426614174001",
    "movementType": "adjustment",
    "quantity": -5,
    "referenceNumber": "ADJ-2024-001",
    "notes": "Ajuste por conteo físico"
  }' | jq '.'

# Transferencia entre ubicaciones
curl -X POST "$BASE_URL/inventory/movements" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "'$PRODUCT_ID'",
    "locationId": "123e4567-e89b-12d3-a456-426614174001",
    "movementType": "transfer",
    "quantity": 20,
    "referenceNumber": "TRF-2024-001",
    "notes": "Transferencia a tienda principal",
    "destinationLocationId": "123e4567-e89b-12d3-a456-426614174002"
  }' | jq '.'
```

### Historial de Movimientos

```bash
# Obtener todos los movimientos
curl -X GET "$BASE_URL/inventory/movements" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Movimientos de producto específico
curl -X GET "$BASE_URL/inventory/movements?productId=$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Movimientos por rango de fechas
curl -X GET "$BASE_URL/inventory/movements?startDate=2024-01-01&endDate=2024-01-31" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Movimientos por tipo
curl -X GET "$BASE_URL/inventory/movements?movementType=in&limit=50" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Movimientos paginados
curl -X GET "$BASE_URL/inventory/movements?page=1&limit=20" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

---

## 📈 Reportes y Analytics

### Reporte de Stock

```bash
# Reporte resumen de stock
curl -X GET "$BASE_URL/reports/stock-summary" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Reporte por ubicación
curl -X GET "$BASE_URL/reports/stock-summary?locationId=123e4567-e89b-12d3-a456-426614174001" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Reporte por categoría
curl -X GET "$BASE_URL/reports/stock-summary?categoryId=123e4567-e89b-12d3-a456-426614174000" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Reporte de Movimientos

```bash
# Reporte de movimientos por período
curl -X GET "$BASE_URL/reports/movement-summary?startDate=2024-01-01&endDate=2024-01-31" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Reporte agrupado por día
curl -X GET "$BASE_URL/reports/movement-summary?startDate=2024-01-01&endDate=2024-01-31&groupBy=day" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Reporte de productos más vendidos
curl -X GET "$BASE_URL/reports/top-products?period=30days&type=sold" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Exportar Reportes

```bash
# Exportar reporte a CSV
curl -X GET "$BASE_URL/reports/stock-summary/export?format=csv" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: text/csv" \
  -o "stock-summary.csv"

# Exportar reporte a Excel
curl -X GET "$BASE_URL/reports/stock-summary/export?format=xlsx" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" \
  -o "stock-summary.xlsx"

# Exportar reporte a PDF
curl -X GET "$BASE_URL/reports/stock-summary/export?format=pdf" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/pdf" \
  -o "stock-summary.pdf"
```

---

## 🔔 Gestión de Alertas

### Configurar Alertas

```bash
# Crear alerta de stock bajo
curl -X POST "$BASE_URL/alerts" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "'$PRODUCT_ID'",
    "alertType": "low_stock",
    "threshold": 10,
    "enabled": true,
    "notificationMethods": ["email", "webhook"]
  }' | jq '.'

# Crear alerta de stock alto
curl -X POST "$BASE_URL/alerts" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "'$PRODUCT_ID'",
    "alertType": "high_stock",
    "threshold": 100,
    "enabled": true,
    "notificationMethods": ["email"]
  }' | jq '.'
```

### Listar Alertas

```bash
# Obtener todas las alertas
curl -X GET "$BASE_URL/alerts" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Alertas activas
curl -X GET "$BASE_URL/alerts?status=active" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Alertas por producto
curl -X GET "$BASE_URL/alerts?productId=$PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

---

## 🔗 Gestión de Webhooks

### Crear Webhook

```bash
# Registrar webhook
curl -X POST "$BASE_URL/webhooks" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://mi-sistema.com/webhooks/inventario",
    "events": [
      "inventory.stock.updated",
      "inventory.stock.low",
      "product.created"
    ],
    "secret": "mi-secreto-super-seguro",
    "active": true,
    "description": "Webhook para sincronización de inventario"
  }' | jq '.'

# Guardar ID del webhook
WEBHOOK_ID=$(curl -s -X POST "$BASE_URL/webhooks" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://webhook.site/unique-id",
    "events": ["inventory.stock.updated"],
    "secret": "test-secret",
    "active": true
  }' | jq -r '.id')

echo "Webhook creado con ID: $WEBHOOK_ID"
```

### Gestionar Webhooks

```bash
# Listar webhooks
curl -X GET "$BASE_URL/webhooks" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Obtener webhook específico
curl -X GET "$BASE_URL/webhooks/$WEBHOOK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Actualizar webhook
curl -X PUT "$BASE_URL/webhooks/$WEBHOOK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      "inventory.stock.updated",
      "inventory.stock.low",
      "product.created",
      "product.updated"
    ],
    "active": true
  }' | jq '.'

# Probar webhook
curl -X POST "$BASE_URL/webhooks/$WEBHOOK_ID/test" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "inventory.stock.updated",
    "testData": {
      "productId": "'$PRODUCT_ID'",
      "quantity": 45
    }
  }' | jq '.'

# Obtener estadísticas del webhook
curl -X GET "$BASE_URL/webhooks/$WEBHOOK_ID/stats" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Obtener logs del webhook
curl -X GET "$BASE_URL/webhooks/$WEBHOOK_ID/logs?limit=10" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

---

## 👥 Gestión de Usuarios (Admin)

### Listar Usuarios

```bash
# Obtener todos los usuarios (solo admin)
curl -X GET "$BASE_URL/users" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Filtrar por rol
curl -X GET "$BASE_URL/users?role=manager" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Usuarios activos
curl -X GET "$BASE_URL/users?isActive=true" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Crear Usuario

```bash
# Crear nuevo usuario
curl -X POST "$BASE_URL/users" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "gerente@empresa.com",
    "password": "password123",
    "firstName": "María",
    "lastName": "González",
    "role": "manager",
    "isActive": true
  }' | jq '.'
```

### Actualizar Usuario

```bash
# Actualizar información de usuario
USER_ID="123e4567-e89b-12d3-a456-426614174003"

curl -X PUT "$BASE_URL/users/$USER_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "María José",
    "lastName": "González Pérez",
    "role": "admin"
  }' | jq '.'

# Desactivar usuario
curl -X PATCH "$BASE_URL/users/$USER_ID/deactivate" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Reactivar usuario
curl -X PATCH "$BASE_URL/users/$USER_ID/activate" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

---

## 🔍 Búsquedas Avanzadas

### Búsqueda de Productos

```bash
# Búsqueda por texto completo
curl -X GET "$BASE_URL/products/search?q=laptop+dell" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Búsqueda con filtros múltiples
curl -X GET "$BASE_URL/products/search" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -G \
  -d "q=mouse" \
  -d "category=peripherals" \
  -d "minPrice=20000" \
  -d "maxPrice=100000" \
  -d "inStock=true" | jq '.'

# Búsqueda por código de barras
curl -X GET "$BASE_URL/products/search?barcode=7891234567890" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Búsqueda de Movimientos

```bash
# Búsqueda avanzada de movimientos
curl -X GET "$BASE_URL/inventory/movements/search" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -G \
  -d "startDate=2024-01-01" \
  -d "endDate=2024-01-31" \
  -d "movementType=in" \
  -d "userId=123e4567-e89b-12d3-a456-426614174004" \
  -d "minQuantity=10" | jq '.'
```

---

## 📊 Operaciones en Lote

### Crear Múltiples Productos

```bash
# Crear productos en lote
curl -X POST "$BASE_URL/products/batch" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "products": [
      {
        "sku": "KEYBOARD-001",
        "name": "Teclado Mecánico",
        "categoryId": "123e4567-e89b-12d3-a456-426614174000",
        "unitPrice": 150000.00,
        "unitOfMeasure": "unidad"
      },
      {
        "sku": "MONITOR-001",
        "name": "Monitor 24 pulgadas",
        "categoryId": "123e4567-e89b-12d3-a456-426614174000",
        "unitPrice": 800000.00,
        "unitOfMeasure": "unidad"
      }
    ]
  }' | jq '.'
```

### Actualizar Stock en Lote

```bash
# Actualizar múltiples stocks
curl -X POST "$BASE_URL/inventory/stock/batch-update" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "updates": [
      {
        "productId": "'$PRODUCT_ID'",
        "locationId": "123e4567-e89b-12d3-a456-426614174001",
        "quantity": 50,
        "operation": "set"
      },
      {
        "productId": "123e4567-e89b-12d3-a456-426614174005",
        "locationId": "123e4567-e89b-12d3-a456-426614174001",
        "quantity": 25,
        "operation": "add"
      }
    ],
    "referenceNumber": "BATCH-2024-001",
    "notes": "Actualización masiva de inventario"
  }' | jq '.'
```

---

## 🧪 Testing y Debugging

### Verificar Estado de la API

```bash
# Health check
curl -X GET "$BASE_URL/health" | jq '.'

# Información de la API
curl -X GET "$BASE_URL/info" | jq '.'

# Métricas (solo admin)
curl -X GET "$BASE_URL/metrics" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Validar Token

```bash
# Verificar validez del token
curl -X GET "$BASE_URL/auth/verify" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'

# Obtener información del usuario actual
curl -X GET "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

### Debug de Requests

```bash
# Request con headers de debug
curl -X GET "$BASE_URL/products" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-Debug: true" \
  -H "X-Request-ID: debug-$(date +%s)" \
  -v | jq '.'

# Obtener logs de request específico
REQUEST_ID="debug-$(date +%s)"
curl -X GET "$BASE_URL/admin/logs?requestId=$REQUEST_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
```

---

## 📝 Scripts de Automatización

### Script de Setup Completo

```bash
#!/bin/bash
# setup-inventory.sh

set -e

echo "🚀 Configurando Sistema de Inventario PYMES..."

# Variables
BASE_URL="https://api.inventario-pymes.com/v1"
EMAIL="admin@empresa.com"
PASSWORD="password123"

# 1. Login
echo "🔐 Realizando login..."
RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'"
  }')

ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.accessToken')
echo "✅ Login exitoso"

# 2. Crear categoría
echo "📁 Creando categoría..."
CATEGORY_RESPONSE=$(curl -s -X POST "$BASE_URL/categories" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Electrónicos",
    "description": "Productos electrónicos y tecnológicos"
  }')

CATEGORY_ID=$(echo $CATEGORY_RESPONSE | jq -r '.id')
echo "✅ Categoría creada: $CATEGORY_ID"

# 3. Crear productos
echo "📦 Creando productos..."
PRODUCTS=(
  '{"sku":"LAPTOP-001","name":"Laptop Dell","unitPrice":1500000,"categoryId":"'$CATEGORY_ID'"}'
  '{"sku":"MOUSE-001","name":"Mouse Logitech","unitPrice":45000,"categoryId":"'$CATEGORY_ID'"}'
  '{"sku":"KEYBOARD-001","name":"Teclado Mecánico","unitPrice":150000,"categoryId":"'$CATEGORY_ID'"}'
)

for product in "${PRODUCTS[@]}"; do
  PRODUCT_RESPONSE=$(curl -s -X POST "$BASE_URL/products" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$product")
  
  PRODUCT_ID=$(echo $PRODUCT_RESPONSE | jq -r '.id')
  PRODUCT_NAME=$(echo $PRODUCT_RESPONSE | jq -r '.name')
  echo "✅ Producto creado: $PRODUCT_NAME ($PRODUCT_ID)"
  
  # Agregar stock inicial
  curl -s -X POST "$BASE_URL/inventory/movements" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "productId": "'$PRODUCT_ID'",
      "locationId": "123e4567-e89b-12d3-a456-426614174001",
      "movementType": "in",
      "quantity": 50,
      "referenceNumber": "INITIAL-STOCK",
      "notes": "Stock inicial"
    }' > /dev/null
  
  echo "✅ Stock inicial agregado para $PRODUCT_NAME"
done

echo "🎉 Setup completado exitosamente!"
```

### Script de Monitoreo

```bash
#!/bin/bash
# monitor-inventory.sh

BASE_URL="https://api.inventario-pymes.com/v1"
ACCESS_TOKEN="your-access-token"

echo "📊 Reporte de Inventario - $(date)"
echo "=================================="

# Stock summary
STOCK_SUMMARY=$(curl -s -X GET "$BASE_URL/reports/stock-summary" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

TOTAL_PRODUCTS=$(echo $STOCK_SUMMARY | jq -r '.totalProducts')
LOW_STOCK=$(echo $STOCK_SUMMARY | jq -r '.lowStockProducts')
OUT_OF_STOCK=$(echo $STOCK_SUMMARY | jq -r '.outOfStockProducts')

echo "📦 Total de productos: $TOTAL_PRODUCTS"
echo "⚠️  Productos con stock bajo: $LOW_STOCK"
echo "🚫 Productos sin stock: $OUT_OF_STOCK"

if [ "$LOW_STOCK" -gt 0 ]; then
  echo ""
  echo "⚠️  Productos con stock bajo:"
  curl -s -X GET "$BASE_URL/inventory/stock?lowStock=true" \
    -H "Authorization: Bearer $ACCESS_TOKEN" | \
    jq -r '.[] | "- \(.product.name): \(.quantity) unidades"'
fi

echo ""
echo "📈 Movimientos del día:"
TODAY=$(date +%Y-%m-%d)
MOVEMENTS=$(curl -s -X GET "$BASE_URL/inventory/movements?startDate=$TODAY&endDate=$TODAY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo $MOVEMENTS | jq -r '.[] | "- \(.product.name): \(.movementType) \(.quantity) (\(.notes))"'
```

---

## 📞 Soporte y Recursos

### URLs Útiles

```bash
# Documentación de la API
open "https://docs.inventario-pymes.com"

# Status de servicios
curl -X GET "https://status.inventario-pymes.com/api/status" | jq '.'

# Postman Collection
curl -o "inventario-pymes.postman_collection.json" \
  "https://api.inventario-pymes.com/postman/collection"
```

### Contacto de Soporte

```bash
# Crear ticket de soporte
curl -X POST "https://support.inventario-pymes.com/api/tickets" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Problema con API",
    "description": "Descripción del problema",
    "priority": "medium",
    "category": "api"
  }'
```

---

**Última actualización:** Enero 2024  
**Versión:** 1.0.0