# ⚡ Guía de Performance - Sistema Inventario PYMES

## 📊 Métricas de Performance

### Objetivos de Performance
- **Time to First Byte (TTFB)**: < 200ms
- **First Contentful Paint (FCP)**: < 1.5s
- **Largest Contentful Paint (LCP)**: < 2.5s
- **Cumulative Layout Shift (CLS)**: < 0.1
- **First Input Delay (FID)**: < 100ms

### Métricas Actuales
- **Lighthouse Score**: 95+
- **API Response Time**: < 150ms promedio
- **Database Query Time**: < 50ms promedio
- **Cache Hit Rate**: > 90%

## 🚀 Optimizaciones Frontend

### React Performance
```javascript
// Lazy loading de componentes
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Products = lazy(() => import('./pages/Products'));

// Memoización de componentes
const ProductCard = memo(({ product }) => {
  return <div>{product.name}</div>;
});

// useMemo para cálculos costosos
const expensiveValue = useMemo(() => {
  return products.reduce((sum, p) => sum + p.price, 0);
}, [products]);
```

### Bundle Optimization
```javascript
// vite.config.js
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          charts: ['recharts'],
          ui: ['lucide-react']
        }
      }
    }
  }
});
```

### Image Optimization
```javascript
// Lazy loading de imágenes
const LazyImage = ({ src, alt }) => (
  <img 
    src={src} 
    alt={alt} 
    loading="lazy"
    decoding="async"
  />
);

// WebP con fallback
<picture>
  <source srcSet="image.webp" type="image/webp" />
  <img src="image.jpg" alt="Product" />
</picture>
```

## 🔧 Optimizaciones Backend

### Database Performance
```sql
-- Índices optimizados
CREATE INDEX CONCURRENTLY idx_products_search 
ON products USING gin(to_tsvector('spanish', name || ' ' || description));

CREATE INDEX idx_movements_date_product 
ON inventory_movements(created_at DESC, product_id);

-- Query optimization
EXPLAIN ANALYZE SELECT p.*, s.quantity 
FROM products p 
LEFT JOIN stock_levels s ON p.id = s.product_id 
WHERE p.is_active = true 
ORDER BY p.name 
LIMIT 20;
```

### Connection Pooling
```javascript
// knex configuration
const knex = require('knex')({
  client: 'postgresql',
  connection: {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
  },
  pool: {
    min: 2,
    max: 20,
    acquireTimeoutMillis: 30000,
    createTimeoutMillis: 30000,
    destroyTimeoutMillis: 5000,
    idleTimeoutMillis: 30000
  }
});
```

### Caching Strategy
```javascript
// Redis caching
const cache = {
  async get(key) {
    const cached = await redis.get(key);
    return cached ? JSON.parse(cached) : null;
  },
  
  async set(key, data, ttl = 3600) {
    await redis.setex(key, ttl, JSON.stringify(data));
  },
  
  async invalidate(pattern) {
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  }
};

// Cache middleware
const cacheMiddleware = (ttl = 300) => {
  return async (req, res, next) => {
    const key = `cache:${req.originalUrl}`;
    const cached = await cache.get(key);
    
    if (cached) {
      return res.json(cached);
    }
    
    res.sendResponse = res.json;
    res.json = (data) => {
      cache.set(key, data, ttl);
      res.sendResponse(data);
    };
    
    next();
  };
};
```

## 📱 Optimizaciones Mobile

### React Native Performance
```javascript
// FlatList optimization
<FlatList
  data={products}
  renderItem={renderProduct}
  keyExtractor={item => item.id}
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index
  })}
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  windowSize={10}
/>

// Image caching
import FastImage from 'react-native-fast-image';

<FastImage
  source={{ uri: imageUrl }}
  style={styles.image}
  resizeMode={FastImage.resizeMode.cover}
/>
```

### Bundle Size Optimization
```javascript
// metro.config.js
module.exports = {
  transformer: {
    minifierConfig: {
      keep_fnames: true,
      mangle: {
        keep_fnames: true
      }
    }
  }
};
```

## 🔍 Monitoring y Profiling

### Performance Monitoring
```javascript
// Custom performance middleware
const performanceMiddleware = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} - ${duration}ms`);
    
    // Log slow queries
    if (duration > 1000) {
      logger.warn('Slow request', {
        method: req.method,
        path: req.path,
        duration,
        query: req.query
      });
    }
  });
  
  next();
};
```

### Database Monitoring
```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Monitor slow queries
SELECT 
  query,
  calls,
  total_time,
  mean_time,
  rows
FROM pg_stat_statements 
WHERE mean_time > 100
ORDER BY mean_time DESC 
LIMIT 10;
```

### APM Integration
```javascript
// New Relic integration
require('newrelic');

// Custom metrics
const newrelic = require('newrelic');

app.use((req, res, next) => {
  newrelic.addCustomAttribute('userId', req.user?.id);
  newrelic.addCustomAttribute('userRole', req.user?.role);
  next();
});
```

## 📈 Load Testing

### Artillery Configuration
```yaml
# artillery-config.yml
config:
  target: 'http://localhost:3001'
  phases:
    - duration: 60
      arrivalRate: 10
    - duration: 120
      arrivalRate: 50
    - duration: 60
      arrivalRate: 100

scenarios:
  - name: "API Load Test"
    requests:
      - get:
          url: "/api/products"
          headers:
            Authorization: "Bearer {{ token }}"
      - post:
          url: "/api/inventory/movements"
          json:
            product_id: "{{ productId }}"
            quantity: 10
            movement_type: "IN"
```

### K6 Load Testing
```javascript
// k6-test.js
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 }
  ]
};

export default function() {
  let response = http.get('http://localhost:3001/api/products');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500
  });
}
```

## 🎯 Performance Best Practices

### Frontend Best Practices
- **Code Splitting**: Dividir bundles por rutas
- **Lazy Loading**: Cargar componentes bajo demanda
- **Memoization**: Usar React.memo y useMemo
- **Virtual Scrolling**: Para listas grandes
- **Image Optimization**: WebP, lazy loading, responsive images
- **Service Workers**: Para caching offline

### Backend Best Practices
- **Database Indexing**: Índices en columnas frecuentemente consultadas
- **Query Optimization**: Evitar N+1 queries
- **Connection Pooling**: Reutilizar conexiones de DB
- **Caching**: Redis para datos frecuentemente accedidos
- **Compression**: Gzip/Brotli para responses
- **CDN**: Para assets estáticos

### Mobile Best Practices
- **FlatList**: Para listas grandes
- **Image Caching**: Usar librerías optimizadas
- **Bundle Splitting**: Separar código por funcionalidad
- **Memory Management**: Limpiar listeners y timers
- **Network Optimization**: Batch requests, retry logic

## 🔧 Herramientas de Performance

### Análisis Frontend
- **Lighthouse**: Auditoría completa de performance
- **WebPageTest**: Testing detallado de carga
- **Chrome DevTools**: Profiling y debugging
- **Bundle Analyzer**: Análisis de tamaño de bundles

### Análisis Backend
- **New Relic**: APM completo
- **DataDog**: Monitoring de infraestructura
- **pg_stat_statements**: Análisis de queries PostgreSQL
- **Redis Monitor**: Análisis de cache

### Análisis Mobile
- **Flipper**: Debugging y profiling React Native
- **Xcode Instruments**: Profiling iOS
- **Android Profiler**: Profiling Android

## 📊 Benchmarks de Referencia

### Web Performance
- **Google PageSpeed**: 90+ score
- **GTmetrix**: Grade A
- **WebPageTest**: Speed Index < 2000ms

### API Performance
- **Throughput**: 1000+ RPS
- **Latency P95**: < 200ms
- **Error Rate**: < 0.1%

### Database Performance
- **Query Time P95**: < 100ms
- **Connection Pool**: 80%+ utilization
- **Cache Hit Rate**: 95%+

## 🚨 Performance Alerts

### Alerting Rules
```yaml
# Prometheus alerts
groups:
  - name: performance
    rules:
      - alert: HighResponseTime
        expr: http_request_duration_seconds{quantile="0.95"} > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
      
      - alert: LowCacheHitRate
        expr: redis_cache_hit_rate < 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Cache hit rate below 80%"
```

---

*El performance es clave para la experiencia del usuario. Monitorea constantemente y optimiza proactivamente.*