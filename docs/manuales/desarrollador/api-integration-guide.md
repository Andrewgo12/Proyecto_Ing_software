# Guía de Integración API - Sistema de Inventario PYMES

## 🔌 Integración con APIs

### Autenticación
```javascript
// Obtener token
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password })
});
const { accessToken } = await response.json();

// Usar token en requests
const headers = {
  'Authorization': `Bearer ${accessToken}`,
  'Content-Type': 'application/json'
};
```

### Endpoints Principales
```javascript
// Productos
GET    /api/products              // Listar productos
POST   /api/products              // Crear producto
GET    /api/products/:id          // Obtener producto
PUT    /api/products/:id          // Actualizar producto
DELETE /api/products/:id          // Eliminar producto

// Inventario
GET    /api/inventory/stock       // Stock actual
POST   /api/inventory/movements   // Registrar movimiento
GET    /api/inventory/movements   // Historial movimientos

// Reportes
POST   /api/reports/generate      // Generar reporte
GET    /api/reports/:id           // Descargar reporte
```

### Ejemplos de Uso
```javascript
// Crear producto
const product = await fetch('/api/products', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    sku: 'PROD-001',
    name: 'Producto Test',
    price: 100,
    categoryId: 'cat-id'
  })
});

// Registrar movimiento
const movement = await fetch('/api/inventory/movements', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    productId: 'prod-id',
    locationId: 'loc-id',
    quantity: 10,
    type: 'IN'
  })
});
```

### Manejo de Errores
```javascript
try {
  const response = await fetch('/api/products', { headers });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }
  
  const data = await response.json();
  return data;
} catch (error) {
  console.error('API Error:', error.message);
  // Manejar error apropiadamente
}
```

### Rate Limiting
```
Límites por IP:
- 100 requests/minuto (general)
- 10 requests/minuto (auth)
- 1000 requests/hora (total)

Headers de respuesta:
- X-RateLimit-Limit
- X-RateLimit-Remaining
- X-RateLimit-Reset
```

### Webhooks
```javascript
// Configurar webhook
POST /api/webhooks
{
  "url": "https://tu-app.com/webhook",
  "events": ["product.created", "stock.low"],
  "secret": "tu-secret-key"
}

// Verificar webhook
const crypto = require('crypto');
const signature = req.headers['x-webhook-signature'];
const payload = JSON.stringify(req.body);
const expected = crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');
```

### SDKs Disponibles
- **JavaScript/Node.js:** `npm install inventario-pymes-sdk`
- **Python:** `pip install inventario-pymes`
- **PHP:** Composer package disponible
- **Postman:** Colección completa incluida