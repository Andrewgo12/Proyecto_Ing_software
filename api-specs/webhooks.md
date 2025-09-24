# 🔗 Webhooks - Sistema de Inventario PYMES

## 📋 Información General

**Protocolo:** HTTP/HTTPS POST  
**Formato:** JSON  
**Autenticación:** HMAC-SHA256  
**Timeout:** 30 segundos  
**Reintentos:** 3 intentos con backoff exponencial  
**Versión:** 1.0  

---

## 🎯 Eventos Disponibles

### Inventario

| Evento | Descripción | Payload |
|--------|-------------|---------|
| `inventory.stock.updated` | Stock de producto actualizado | StockUpdatePayload |
| `inventory.stock.low` | Stock bajo el mínimo configurado | LowStockPayload |
| `inventory.movement.created` | Nuevo movimiento de inventario | MovementPayload |
| `inventory.adjustment.created` | Ajuste de inventario realizado | AdjustmentPayload |

### Productos

| Evento | Descripción | Payload |
|--------|-------------|---------|
| `product.created` | Producto creado | ProductPayload |
| `product.updated` | Producto actualizado | ProductPayload |
| `product.deleted` | Producto eliminado | ProductDeletedPayload |
| `product.price.changed` | Precio de producto modificado | PriceChangePayload |

### Alertas

| Evento | Descripción | Payload |
|--------|-------------|---------|
| `alert.stock.low` | Alerta de stock bajo | AlertPayload |
| `alert.stock.out` | Producto sin stock | AlertPayload |
| `alert.expiry.warning` | Producto próximo a vencer | ExpiryAlertPayload |

### Sistema

| Evento | Descripción | Payload |
|--------|-------------|---------|
| `system.backup.completed` | Backup completado exitosamente | BackupPayload |
| `system.maintenance.scheduled` | Mantenimiento programado | MaintenancePayload |
| `system.error.critical` | Error crítico del sistema | ErrorPayload |

---

## 🔧 Configuración de Webhooks

### Registro de Webhook

```http
POST /api/v1/webhooks
Authorization: Bearer {token}
Content-Type: application/json

{
  "url": "https://mi-sistema.com/webhooks/inventario",
  "events": [
    "inventory.stock.updated",
    "inventory.stock.low",
    "product.created"
  ],
  "secret": "mi-secreto-super-seguro",
  "active": true,
  "description": "Webhook para sincronización de inventario"
}
```

**Response (201):**
```json
{
  "id": "webhook-123e4567-e89b-12d3-a456-426614174000",
  "url": "https://mi-sistema.com/webhooks/inventario",
  "events": [
    "inventory.stock.updated",
    "inventory.stock.low",
    "product.created"
  ],
  "secret": "mi-secreto-super-seguro",
  "active": true,
  "description": "Webhook para sincronización de inventario",
  "createdAt": "2024-01-15T10:30:00Z",
  "lastTriggered": null,
  "deliveryStats": {
    "totalDeliveries": 0,
    "successfulDeliveries": 0,
    "failedDeliveries": 0,
    "lastDeliveryStatus": null
  }
}
```

### Gestión de Webhooks

```http
# Listar webhooks
GET /api/v1/webhooks

# Obtener webhook específico
GET /api/v1/webhooks/{id}

# Actualizar webhook
PUT /api/v1/webhooks/{id}

# Eliminar webhook
DELETE /api/v1/webhooks/{id}

# Activar/Desactivar webhook
PATCH /api/v1/webhooks/{id}/toggle
```

---

## 📦 Estructura de Payload

### Header Estándar

Todos los webhooks incluyen estos headers:

```http
POST /your-webhook-url
Content-Type: application/json
X-Webhook-Event: inventory.stock.updated
X-Webhook-ID: webhook-123e4567
X-Webhook-Delivery: delivery-456e7890
X-Webhook-Signature: sha256=a1b2c3d4e5f6...
X-Webhook-Timestamp: 1642262400
User-Agent: InventarioPYMES-Webhook/1.0
```

### Payload Base

```json
{
  "event": "inventory.stock.updated",
  "timestamp": "2024-01-15T16:30:00Z",
  "webhookId": "webhook-123e4567-e89b-12d3-a456-426614174000",
  "deliveryId": "delivery-456e7890-e89b-12d3-a456-426614174001",
  "data": {
    // Datos específicos del evento
  },
  "metadata": {
    "version": "1.0",
    "source": "inventario-pymes-api",
    "environment": "production"
  }
}
```

---

## 📊 Payloads Específicos por Evento

### inventory.stock.updated

```json
{
  "event": "inventory.stock.updated",
  "timestamp": "2024-01-15T16:30:00Z",
  "webhookId": "webhook-123",
  "deliveryId": "delivery-456",
  "data": {
    "product": {
      "id": "prod-123",
      "sku": "LAPTOP-001",
      "name": "Laptop Dell Inspiron 15"
    },
    "location": {
      "id": "loc-123",
      "name": "Bodega Principal"
    },
    "stockChange": {
      "previousQuantity": 50.0,
      "newQuantity": 45.0,
      "difference": -5.0,
      "movementType": "out",
      "reason": "sale"
    },
    "movement": {
      "id": "mov-789",
      "referenceNumber": "SO-2024-001",
      "userId": "user-456",
      "notes": "Venta a cliente"
    }
  }
}
```

### inventory.stock.low

```json
{
  "event": "inventory.stock.low",
  "timestamp": "2024-01-15T16:30:00Z",
  "webhookId": "webhook-123",
  "deliveryId": "delivery-457",
  "data": {
    "product": {
      "id": "prod-124",
      "sku": "MOUSE-001",
      "name": "Mouse Inalámbrico"
    },
    "location": {
      "id": "loc-123",
      "name": "Bodega Principal"
    },
    "stock": {
      "currentQuantity": 8.0,
      "minStock": 10.0,
      "maxStock": 100.0,
      "daysOfStock": 3.2
    },
    "alert": {
      "severity": "warning",
      "triggeredAt": "2024-01-15T16:30:00Z",
      "previousAlert": "2024-01-10T10:00:00Z"
    }
  }
}
```

### product.created

```json
{
  "event": "product.created",
  "timestamp": "2024-01-15T16:30:00Z",
  "webhookId": "webhook-123",
  "deliveryId": "delivery-458",
  "data": {
    "product": {
      "id": "prod-125",
      "sku": "KEYBOARD-001",
      "name": "Teclado Mecánico",
      "description": "Teclado mecánico para gaming",
      "category": {
        "id": "cat-123",
        "name": "Periféricos"
      },
      "unitPrice": 150000.00,
      "unitOfMeasure": "unidad",
      "barcode": "7891234567893",
      "isActive": true,
      "createdAt": "2024-01-15T16:30:00Z"
    },
    "createdBy": {
      "id": "user-456",
      "email": "admin@empresa.com",
      "name": "Juan Pérez"
    }
  }
}
```

### alert.stock.out

```json
{
  "event": "alert.stock.out",
  "timestamp": "2024-01-15T16:30:00Z",
  "webhookId": "webhook-123",
  "deliveryId": "delivery-459",
  "data": {
    "product": {
      "id": "prod-126",
      "sku": "CABLE-001",
      "name": "Cable HDMI"
    },
    "location": {
      "id": "loc-123",
      "name": "Bodega Principal"
    },
    "stock": {
      "currentQuantity": 0.0,
      "lastMovement": {
        "date": "2024-01-15T14:00:00Z",
        "type": "out",
        "quantity": 2.0
      }
    },
    "alert": {
      "severity": "critical",
      "impact": "high",
      "affectedSales": 3,
      "estimatedLoss": 45000.00
    }
  }
}
```

---

## 🔐 Seguridad y Autenticación

### Verificación de Firma HMAC

```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload, 'utf8')
    .digest('hex');
    
  const expectedHeader = `sha256=${expectedSignature}`;
  
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedHeader)
  );
}

// Uso en endpoint
app.post('/webhooks/inventario', (req, res) => {
  const signature = req.headers['x-webhook-signature'];
  const payload = JSON.stringify(req.body);
  const secret = process.env.WEBHOOK_SECRET;
  
  if (!verifyWebhookSignature(payload, signature, secret)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  
  // Procesar webhook
  processWebhook(req.body);
  res.status(200).json({ received: true });
});
```

### Validación de Timestamp

```javascript
function validateTimestamp(timestamp, tolerance = 300) {
  const now = Math.floor(Date.now() / 1000);
  const webhookTime = parseInt(timestamp);
  
  return Math.abs(now - webhookTime) <= tolerance;
}

// Uso
const timestamp = req.headers['x-webhook-timestamp'];
if (!validateTimestamp(timestamp)) {
  return res.status(401).json({ error: 'Request too old' });
}
```

---

## 🔄 Manejo de Reintentos

### Política de Reintentos

1. **Primer intento:** Inmediato
2. **Segundo intento:** 1 minuto después
3. **Tercer intento:** 5 minutos después
4. **Cuarto intento:** 15 minutos después
5. **Quinto intento:** 1 hora después

### Códigos de Respuesta

| Código HTTP | Acción | Descripción |
|-------------|--------|-------------|
| 200-299 | ✅ Éxito | Webhook procesado correctamente |
| 400-499 | ❌ No reintentar | Error del cliente, no se reintenta |
| 500-599 | 🔄 Reintentar | Error del servidor, se reintenta |
| Timeout | 🔄 Reintentar | Sin respuesta en 30 segundos |

### Headers de Reintento

```http
# En reintentos
X-Webhook-Retry-Count: 2
X-Webhook-First-Attempt: 2024-01-15T16:30:00Z
X-Webhook-Last-Attempt: 2024-01-15T16:35:00Z
```

---

## 📊 Monitoreo y Logs

### Dashboard de Webhooks

```http
GET /api/v1/webhooks/{id}/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
  "webhookId": "webhook-123",
  "stats": {
    "totalDeliveries": 1250,
    "successfulDeliveries": 1200,
    "failedDeliveries": 50,
    "successRate": 96.0,
    "averageResponseTime": 245,
    "lastDelivery": {
      "timestamp": "2024-01-15T16:30:00Z",
      "status": "success",
      "responseTime": 180,
      "httpStatus": 200
    }
  },
  "recentDeliveries": [
    {
      "deliveryId": "delivery-456",
      "event": "inventory.stock.updated",
      "timestamp": "2024-01-15T16:30:00Z",
      "status": "success",
      "httpStatus": 200,
      "responseTime": 180,
      "retryCount": 0
    }
  ]
}
```

### Logs de Webhook

```http
GET /api/v1/webhooks/{id}/logs?limit=50&offset=0
Authorization: Bearer {token}
```

**Response:**
```json
{
  "logs": [
    {
      "deliveryId": "delivery-456",
      "event": "inventory.stock.updated",
      "timestamp": "2024-01-15T16:30:00Z",
      "url": "https://mi-sistema.com/webhooks/inventario",
      "httpStatus": 200,
      "responseTime": 180,
      "retryCount": 0,
      "payload": {
        "event": "inventory.stock.updated",
        "data": { /* ... */ }
      },
      "response": {
        "headers": {
          "content-type": "application/json"
        },
        "body": "{\"received\": true}"
      }
    }
  ],
  "pagination": {
    "total": 1250,
    "limit": 50,
    "offset": 0
  }
}
```

---

## 🧪 Testing de Webhooks

### Webhook de Prueba

```http
POST /api/v1/webhooks/{id}/test
Authorization: Bearer {token}
Content-Type: application/json

{
  "event": "inventory.stock.updated",
  "testData": {
    "productId": "prod-123",
    "locationId": "loc-123",
    "quantity": 45.0
  }
}
```

### Herramientas de Testing

#### ngrok para Testing Local

```bash
# Instalar ngrok
npm install -g ngrok

# Exponer puerto local
ngrok http 3000

# URL pública: https://abc123.ngrok.io
```

#### Webhook Testing Tool

```javascript
// webhook-tester.js
const express = require('express');
const app = express();

app.use(express.json());

app.post('/webhook-test', (req, res) => {
  console.log('Webhook recibido:');
  console.log('Headers:', req.headers);
  console.log('Body:', JSON.stringify(req.body, null, 2));
  
  // Simular procesamiento
  setTimeout(() => {
    res.status(200).json({ 
      received: true, 
      timestamp: new Date().toISOString() 
    });
  }, 100);
});

app.listen(3000, () => {
  console.log('Webhook tester corriendo en puerto 3000');
});
```

---

## 🔧 Implementación en Cliente

### Node.js/Express

```javascript
const express = require('express');
const crypto = require('crypto');
const app = express();

// Middleware para raw body (necesario para verificar firma)
app.use('/webhooks', express.raw({ type: 'application/json' }));

app.post('/webhooks/inventario', (req, res) => {
  try {
    // Verificar firma
    const signature = req.headers['x-webhook-signature'];
    const payload = req.body;
    
    if (!verifySignature(payload, signature)) {
      return res.status(401).json({ error: 'Invalid signature' });
    }
    
    // Parsear JSON
    const webhookData = JSON.parse(payload);
    
    // Procesar según tipo de evento
    switch (webhookData.event) {
      case 'inventory.stock.updated':
        await handleStockUpdate(webhookData.data);
        break;
        
      case 'inventory.stock.low':
        await handleLowStock(webhookData.data);
        break;
        
      case 'product.created':
        await handleProductCreated(webhookData.data);
        break;
        
      default:
        console.log(`Evento no manejado: ${webhookData.event}`);
    }
    
    res.status(200).json({ received: true });
    
  } catch (error) {
    console.error('Error procesando webhook:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

async function handleStockUpdate(data) {
  console.log(`Stock actualizado para ${data.product.name}:`);
  console.log(`Cantidad anterior: ${data.stockChange.previousQuantity}`);
  console.log(`Cantidad nueva: ${data.stockChange.newQuantity}`);
  
  // Actualizar sistema local
  await updateLocalStock(data.product.id, data.stockChange.newQuantity);
  
  // Enviar notificación si es necesario
  if (data.stockChange.newQuantity < 10) {
    await sendLowStockNotification(data.product);
  }
}

async function handleLowStock(data) {
  console.log(`⚠️ Stock bajo para ${data.product.name}`);
  console.log(`Cantidad actual: ${data.stock.currentQuantity}`);
  console.log(`Mínimo requerido: ${data.stock.minStock}`);
  
  // Crear orden de compra automática
  await createPurchaseOrder(data.product, data.stock);
  
  // Notificar al equipo de compras
  await notifyPurchasingTeam(data);
}
```

### Python/Flask

```python
import hmac
import hashlib
import json
from flask import Flask, request, jsonify

app = Flask(__name__)

def verify_signature(payload, signature, secret):
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    expected_header = f"sha256={expected_signature}"
    return hmac.compare_digest(signature, expected_header)

@app.route('/webhooks/inventario', methods=['POST'])
def handle_webhook():
    try:
        # Verificar firma
        signature = request.headers.get('X-Webhook-Signature')
        payload = request.get_data()
        
        if not verify_signature(payload, signature, WEBHOOK_SECRET):
            return jsonify({'error': 'Invalid signature'}), 401
        
        # Procesar webhook
        webhook_data = json.loads(payload)
        event_type = webhook_data['event']
        
        if event_type == 'inventory.stock.updated':
            handle_stock_update(webhook_data['data'])
        elif event_type == 'inventory.stock.low':
            handle_low_stock(webhook_data['data'])
        elif event_type == 'product.created':
            handle_product_created(webhook_data['data'])
        
        return jsonify({'received': True}), 200
        
    except Exception as e:
        print(f"Error procesando webhook: {e}")
        return jsonify({'error': 'Internal server error'}), 500

def handle_stock_update(data):
    product = data['product']
    stock_change = data['stockChange']
    
    print(f"Stock actualizado para {product['name']}")
    print(f"Cantidad: {stock_change['previousQuantity']} → {stock_change['newQuantity']}")
    
    # Actualizar base de datos local
    update_local_stock(product['id'], stock_change['newQuantity'])

if __name__ == '__main__':
    app.run(debug=True)
```

---

## 📋 Mejores Prácticas

### Para Proveedores de Webhooks (Nosotros)

1. **Idempotencia:** Incluir IDs únicos para evitar procesamiento duplicado
2. **Orden:** No garantizar orden de entrega
3. **Timeout:** Configurar timeout razonable (30s)
4. **Reintentos:** Implementar backoff exponencial
5. **Monitoreo:** Trackear tasas de éxito y fallos
6. **Documentación:** Mantener ejemplos actualizados

### Para Consumidores de Webhooks (Clientes)

1. **Verificación:** Siempre verificar firma HMAC
2. **Idempotencia:** Manejar webhooks duplicados
3. **Respuesta Rápida:** Responder en <30 segundos
4. **Procesamiento Asíncrono:** Usar colas para procesamiento pesado
5. **Logging:** Registrar todos los webhooks recibidos
6. **Manejo de Errores:** Implementar manejo robusto de errores

### Ejemplo de Procesamiento Asíncrono

```javascript
const Queue = require('bull');
const webhookQueue = new Queue('webhook processing');

// Endpoint que recibe webhook
app.post('/webhooks/inventario', (req, res) => {
  // Verificar firma rápidamente
  if (!verifySignature(req.body, req.headers['x-webhook-signature'])) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  
  // Agregar a cola para procesamiento asíncrono
  webhookQueue.add('process-webhook', {
    webhookData: req.body,
    receivedAt: new Date().toISOString()
  });
  
  // Responder inmediatamente
  res.status(200).json({ received: true });
});

// Procesador de cola
webhookQueue.process('process-webhook', async (job) => {
  const { webhookData } = job.data;
  
  try {
    await processWebhookData(webhookData);
    console.log(`Webhook procesado: ${webhookData.event}`);
  } catch (error) {
    console.error(`Error procesando webhook: ${error.message}`);
    throw error; // Bull reintentará automáticamente
  }
});
```

---

## 📞 Soporte y Troubleshooting

### Problemas Comunes

| Problema | Causa | Solución |
|----------|-------|----------|
| Webhook no llega | URL incorrecta o inaccesible | Verificar URL y conectividad |
| Firma inválida | Secret incorrecto | Verificar secret en configuración |
| Timeout | Procesamiento muy lento | Implementar procesamiento asíncrono |
| Reintentos excesivos | Endpoint siempre falla | Revisar logs y corregir endpoint |

### Debugging

```bash
# Verificar conectividad
curl -X POST https://tu-endpoint.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Verificar logs de webhook
curl -X GET https://api.inventario-pymes.com/v1/webhooks/{id}/logs \
  -H "Authorization: Bearer {token}"
```

### Contacto de Soporte

**Webhook Support:** webhooks@inventario-pymes.com  
**Documentation:** https://docs.inventario-pymes.com/webhooks  
**Status Page:** https://status.inventario-pymes.com  

---

**Última actualización:** Enero 2024  
**Versión:** 1.0.0  
**Próxima revisión:** Marzo 2024