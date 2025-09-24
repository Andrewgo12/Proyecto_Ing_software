# ⚡ Rate Limiting - Sistema de Inventario PYMES

## 📊 Políticas de Rate Limiting

### Límites Generales por Rol

| Rol | Requests/Hora | Requests/Minuto | Burst Limit |
|-----|---------------|-----------------|-------------|
| **Admin** | 5,000 | 100 | 200 |
| **Manager** | 3,000 | 60 | 120 |
| **Warehouse** | 2,000 | 40 | 80 |
| **Sales** | 1,500 | 30 | 60 |
| **Viewer** | 1,000 | 20 | 40 |
| **Anonymous** | 100 | 5 | 10 |

### Límites por Endpoint

#### Autenticación
```yaml
/auth/login:
  per_ip: 5/minute
  per_email: 10/hour
  lockout_duration: 15 minutes
  
/auth/refresh:
  per_user: 20/minute
  per_ip: 100/minute
  
/auth/logout:
  per_user: 100/minute
```

#### Productos
```yaml
/products:
  GET: 500/hour per user
  POST: 100/hour per user
  PUT: 200/hour per user
  DELETE: 50/hour per user
  
/products/search:
  per_user: 300/hour
  per_ip: 1000/hour
```

#### Inventario
```yaml
/inventory/stock:
  GET: 1000/hour per user
  
/inventory/movements:
  GET: 500/hour per user
  POST: 200/hour per user
  
/inventory/bulk-update:
  per_user: 10/hour
  max_items: 1000 per request
```

#### Reportes
```yaml
/reports/*:
  per_user: 50/hour
  per_endpoint: 20/hour
  
/reports/export:
  per_user: 10/hour
  file_size_limit: 50MB
```

## 🛠️ Implementación Técnica

### Headers de Rate Limiting

**Request Headers:**
```http
X-RateLimit-Identifier: user-123e4567
X-Client-Version: 1.0.0
X-Request-ID: req-abc123
```

**Response Headers:**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642266000
X-RateLimit-Window: 3600
X-RateLimit-Policy: sliding-window
```

### Algoritmos de Rate Limiting

#### 1. Token Bucket
```javascript
class TokenBucket {
  constructor(capacity, refillRate) {
    this.capacity = capacity;
    this.tokens = capacity;
    this.refillRate = refillRate;
    this.lastRefill = Date.now();
  }
  
  consume(tokens = 1) {
    this.refill();
    
    if (this.tokens >= tokens) {
      this.tokens -= tokens;
      return true;
    }
    
    return false;
  }
  
  refill() {
    const now = Date.now();
    const timePassed = (now - this.lastRefill) / 1000;
    const tokensToAdd = timePassed * this.refillRate;
    
    this.tokens = Math.min(this.capacity, this.tokens + tokensToAdd);
    this.lastRefill = now;
  }
}
```

#### 2. Sliding Window
```javascript
class SlidingWindow {
  constructor(windowSize, limit) {
    this.windowSize = windowSize * 1000; // Convert to ms
    this.limit = limit;
    this.requests = [];
  }
  
  isAllowed() {
    const now = Date.now();
    const windowStart = now - this.windowSize;
    
    // Remove old requests
    this.requests = this.requests.filter(time => time > windowStart);
    
    if (this.requests.length < this.limit) {
      this.requests.push(now);
      return true;
    }
    
    return false;
  }
  
  getRemainingRequests() {
    return Math.max(0, this.limit - this.requests.length);
  }
  
  getResetTime() {
    if (this.requests.length === 0) return 0;
    return this.requests[0] + this.windowSize;
  }
}
```

### Redis Implementation

```javascript
class RedisRateLimiter {
  constructor(redis, options = {}) {
    this.redis = redis;
    this.windowSize = options.windowSize || 3600; // 1 hour
    this.limit = options.limit || 1000;
  }
  
  async checkLimit(identifier) {
    const key = `rate_limit:${identifier}`;
    const now = Date.now();
    const windowStart = now - (this.windowSize * 1000);
    
    // Use Redis pipeline for atomic operations
    const pipeline = this.redis.pipeline();
    
    // Remove old entries
    pipeline.zremrangebyscore(key, 0, windowStart);
    
    // Count current requests
    pipeline.zcard(key);
    
    // Add current request
    pipeline.zadd(key, now, `${now}-${Math.random()}`);
    
    // Set expiration
    pipeline.expire(key, this.windowSize);
    
    const results = await pipeline.exec();
    const currentCount = results[1][1];
    
    return {
      allowed: currentCount < this.limit,
      remaining: Math.max(0, this.limit - currentCount - 1),
      resetTime: now + (this.windowSize * 1000),
      limit: this.limit
    };
  }
}
```

## 🚨 Respuestas de Rate Limiting

### HTTP 429 - Too Many Requests

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "details": {
    "limit": 1000,
    "remaining": 0,
    "resetTime": 1642266000,
    "retryAfter": 3600,
    "policy": "sliding-window"
  },
  "timestamp": "2024-01-15T16:30:00Z"
}
```

### Códigos de Error Específicos

| Código | Descripción | Acción Recomendada |
|--------|-------------|-------------------|
| `RATE_LIMIT_EXCEEDED` | Límite general excedido | Esperar hasta reset |
| `LOGIN_RATE_LIMIT` | Demasiados intentos de login | Esperar 15 minutos |
| `BULK_OPERATION_LIMIT` | Límite de operaciones masivas | Reducir tamaño del lote |
| `EXPORT_RATE_LIMIT` | Límite de exportaciones | Esperar 1 hora |
| `API_QUOTA_EXCEEDED` | Cuota diaria excedida | Contactar soporte |

## 📈 Monitoreo y Alertas

### Métricas de Rate Limiting

```yaml
# Prometheus metrics
rate_limit_requests_total{endpoint, status, user_role}
rate_limit_blocked_requests_total{endpoint, reason}
rate_limit_current_usage{user_id, endpoint}
rate_limit_reset_time{user_id}
```

### Alertas Automáticas

```yaml
# Alert rules
- alert: HighRateLimitUsage
  expr: rate_limit_current_usage / rate_limit_limit > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Usuario cerca del límite de rate limiting"
    
- alert: RateLimitAbuse
  expr: rate(rate_limit_blocked_requests_total[5m]) > 10
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Posible abuso de API detectado"
```

## 🔧 Configuración Dinámica

### Ajuste de Límites por Usuario

```javascript
// Configuración personalizada por usuario
const customLimits = {
  "premium-user-123": {
    requests_per_hour: 10000,
    burst_limit: 500,
    endpoints: {
      "/reports/export": { limit: 50, window: 3600 }
    }
  },
  "enterprise-user-456": {
    requests_per_hour: 50000,
    burst_limit: 1000,
    unlimited_endpoints: ["/inventory/stock"]
  }
};

async function getRateLimit(userId, endpoint) {
  const userConfig = customLimits[userId];
  if (userConfig) {
    // Apply custom limits
    return userConfig.endpoints?.[endpoint] || userConfig;
  }
  
  // Apply default limits based on role
  return getDefaultLimits(await getUserRole(userId));
}
```

### API de Configuración

```http
# Obtener límites actuales
GET /api/v1/admin/rate-limits/user/{userId}
Authorization: Bearer {admin_token}

# Actualizar límites
PUT /api/v1/admin/rate-limits/user/{userId}
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "requests_per_hour": 5000,
  "burst_limit": 200,
  "endpoints": {
    "/reports/export": {
      "limit": 20,
      "window": 3600
    }
  }
}
```

## 🛡️ Protección contra Abuso

### Detección de Patrones Sospechosos

```javascript
class AbuseDetector {
  constructor(redis) {
    this.redis = redis;
    this.patterns = {
      // Múltiples IPs para mismo usuario
      ip_switching: {
        threshold: 5, // diferentes IPs en 1 hora
        window: 3600,
        action: 'flag'
      },
      
      // Requests muy rápidos
      burst_requests: {
        threshold: 100, // requests en 1 minuto
        window: 60,
        action: 'temporary_block'
      },
      
      // Patrones de scraping
      scraping_pattern: {
        sequential_requests: 50,
        time_window: 300,
        action: 'captcha_challenge'
      }
    };
  }
  
  async detectAbuse(userId, ip, endpoint) {
    const checks = await Promise.all([
      this.checkIPSwitching(userId),
      this.checkBurstRequests(userId),
      this.checkScrapingPattern(userId, endpoint)
    ]);
    
    return checks.find(check => check.detected) || { detected: false };
  }
  
  async checkIPSwitching(userId) {
    const key = `ip_tracking:${userId}`;
    const ips = await this.redis.smembers(key);
    
    if (ips.length > this.patterns.ip_switching.threshold) {
      return {
        detected: true,
        pattern: 'ip_switching',
        action: 'flag',
        details: { unique_ips: ips.length }
      };
    }
    
    return { detected: false };
  }
}
```

### Acciones Automáticas

```javascript
const abuseActions = {
  flag: async (userId, details) => {
    await logSecurityEvent('SUSPICIOUS_ACTIVITY', userId, details);
    await notifySecurityTeam(userId, details);
  },
  
  temporary_block: async (userId, duration = 3600) => {
    await redis.setex(`blocked_user:${userId}`, duration, 'abuse_detected');
    await notifyUser(userId, 'account_temporarily_blocked');
  },
  
  captcha_challenge: async (userId) => {
    await redis.setex(`captcha_required:${userId}`, 1800, 'true');
    return { requiresCaptcha: true };
  },
  
  permanent_block: async (userId) => {
    await database.users.update(userId, { status: 'blocked' });
    await notifyAdmins('USER_BLOCKED', userId);
  }
};
```

## 📊 Dashboard de Rate Limiting

### Métricas en Tiempo Real

```javascript
// WebSocket endpoint para métricas en vivo
app.ws('/admin/rate-limits/live', (ws, req) => {
  const interval = setInterval(async () => {
    const metrics = await getRateLimitMetrics();
    ws.send(JSON.stringify({
      timestamp: Date.now(),
      metrics: {
        total_requests: metrics.totalRequests,
        blocked_requests: metrics.blockedRequests,
        top_users: metrics.topUsers,
        endpoint_usage: metrics.endpointUsage,
        abuse_alerts: metrics.abuseAlerts
      }
    }));
  }, 5000);
  
  ws.on('close', () => clearInterval(interval));
});
```

### Reportes de Uso

```sql
-- Query para reporte diario de rate limiting
SELECT 
  DATE(created_at) as date,
  user_role,
  endpoint,
  COUNT(*) as total_requests,
  SUM(CASE WHEN blocked = true THEN 1 ELSE 0 END) as blocked_requests,
  AVG(response_time) as avg_response_time
FROM rate_limit_logs 
WHERE created_at >= NOW() - INTERVAL 30 DAY
GROUP BY DATE(created_at), user_role, endpoint
ORDER BY date DESC, total_requests DESC;
```

## 🧪 Testing de Rate Limiting

### Test Cases

```javascript
describe('Rate Limiting', () => {
  test('should allow requests within limit', async () => {
    const user = await createTestUser({ role: 'manager' });
    const token = await generateToken(user);
    
    // Should allow first 60 requests in a minute
    for (let i = 0; i < 60; i++) {
      const response = await request(app)
        .get('/api/v1/products')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
        
      expect(response.headers['x-ratelimit-remaining']).toBe(String(59 - i));
    }
  });
  
  test('should block requests exceeding limit', async () => {
    const user = await createTestUser({ role: 'sales' });
    const token = await generateToken(user);
    
    // Exhaust rate limit (30 requests/minute for sales)
    for (let i = 0; i < 30; i++) {
      await request(app)
        .get('/api/v1/products')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
    }
    
    // 31st request should be blocked
    const response = await request(app)
      .get('/api/v1/products')
      .set('Authorization', `Bearer ${token}`)
      .expect(429);
      
    expect(response.body.code).toBe('RATE_LIMIT_EXCEEDED');
  });
  
  test('should reset limits after window expires', async () => {
    // Mock time to test window reset
    jest.useFakeTimers();
    
    const user = await createTestUser({ role: 'viewer' });
    const token = await generateToken(user);
    
    // Exhaust limit
    for (let i = 0; i < 20; i++) {
      await request(app)
        .get('/api/v1/products')
        .set('Authorization', `Bearer ${token}`);
    }
    
    // Should be blocked
    await request(app)
      .get('/api/v1/products')
      .set('Authorization', `Bearer ${token}`)
      .expect(429);
    
    // Fast forward 1 hour
    jest.advanceTimersByTime(3600 * 1000);
    
    // Should be allowed again
    await request(app)
      .get('/api/v1/products')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
      
    jest.useRealTimers();
  });
});
```

## 🔄 Mejores Prácticas

### Para Desarrolladores de API

1. **Implementar Graceful Degradation**
```javascript
// Reducir funcionalidad en lugar de bloquear completamente
if (rateLimitExceeded && !criticalEndpoint) {
  return cachedResponse || simplifiedResponse;
}
```

2. **Usar Headers Informativos**
```javascript
res.set({
  'X-RateLimit-Limit': limit,
  'X-RateLimit-Remaining': remaining,
  'X-RateLimit-Reset': resetTime,
  'Retry-After': retryAfter
});
```

3. **Logging Detallado**
```javascript
logger.info('Rate limit check', {
  userId,
  endpoint,
  currentUsage,
  limit,
  remaining,
  blocked: !allowed
});
```

### Para Clientes de API

1. **Respetar Headers de Rate Limiting**
```javascript
const remaining = response.headers['x-ratelimit-remaining'];
const resetTime = response.headers['x-ratelimit-reset'];

if (remaining < 10) {
  // Slow down requests
  await delay(1000);
}
```

2. **Implementar Exponential Backoff**
```javascript
async function apiCallWithBackoff(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      
      if (response.status === 429) {
        const retryAfter = response.headers.get('retry-after');
        await delay(Math.pow(2, i) * 1000 + (retryAfter * 1000));
        continue;
      }
      
      return response;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await delay(Math.pow(2, i) * 1000);
    }
  }
}
```

3. **Batch Operations**
```javascript
// En lugar de múltiples requests individuales
const products = await Promise.all(
  productIds.map(id => fetchProduct(id))
);

// Usar endpoints de batch
const products = await fetchProductsBatch(productIds);
```

---

**Última actualización:** Enero 2024  
**Versión:** 1.0.0  
**Próxima revisión:** Marzo 2024