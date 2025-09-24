# Arquitectura del Sistema - Sistema de Inventario PYMES

## 1. Visión General de la Arquitectura

### 1.1 Patrón Arquitectónico
El sistema utiliza una **arquitectura de microservicios** con los siguientes patrones:
- **API Gateway** como punto de entrada único
- **Microservicios** especializados por dominio
- **Base de datos por servicio** (Database per Service)
- **Event-driven architecture** para comunicación asíncrona

### 1.2 Principios de Diseño
- **Separation of Concerns:** Cada componente tiene una responsabilidad específica
- **Loose Coupling:** Componentes independientes comunicados por APIs
- **High Cohesion:** Funcionalidades relacionadas agrupadas
- **Scalability:** Capacidad de escalar componentes independientemente
- **Fault Tolerance:** Resistencia a fallos de componentes individuales

## 2. Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   Web Client    │   Mobile App    │     Admin Dashboard         │
│   (React.js)    │ (React Native)  │      (React.js)            │
└─────────┬───────┴─────────┬───────┴─────────────┬───────────────┘
          │                 │                     │
          └─────────────────┼─────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│  • Authentication & Authorization                               │
│  • Rate Limiting & Throttling                                  │
│  • Request Routing & Load Balancing                            │
│  • API Versioning & Documentation                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                        │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│ Inventory   │ Product     │ User        │ Notification        │
│ Service     │ Service     │ Service     │ Service             │
├─────────────┼─────────────┼─────────────┼─────────────────────┤
│ Report      │ Alert       │ Audit       │ Integration         │
│ Service     │ Service     │ Service     │ Service             │
└─────────────┴─────────────┴─────────────┴─────────────────────┘
                          │
┌─────────────────────────────────────────────────────────────────┐
│                      DATA ACCESS LAYER                         │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│ PostgreSQL  │ Redis       │ Elasticsearch│ File Storage       │
│ (Primary)   │ (Cache)     │ (Search)     │ (Images/Docs)      │
└─────────────┴─────────────┴─────────────┴─────────────────────┘
```

## 3. Componentes Detallados

### 3.1 Presentation Layer

#### 3.1.1 Web Client (React.js)
**Responsabilidades:**
- Interface de usuario para operaciones de inventario
- Dashboard ejecutivo con métricas y KPIs
- Gestión de productos y categorías
- Generación y visualización de reportes

**Tecnologías:**
- React.js 18+ con TypeScript
- Material-UI (MUI) v5 para componentes
- Redux Toolkit para manejo de estado
- React Query para cache y sincronización
- Chart.js para visualizaciones

**Características:**
- Progressive Web App (PWA)
- Responsive design
- Offline capabilities
- Real-time updates via WebSockets

#### 3.1.2 Mobile App (React Native)
**Responsabilidades:**
- Consultas rápidas de inventario
- Escaneo de códigos de barras
- Operaciones básicas de entrada/salida
- Notificaciones push

**Tecnologías:**
- React Native 0.72+
- React Navigation v6
- Redux Toolkit (compartido con web)
- React Native Camera para códigos de barras
- AsyncStorage para cache local

#### 3.1.3 Admin Dashboard
**Responsabilidades:**
- Configuración del sistema
- Gestión de usuarios y permisos
- Monitoreo de performance
- Logs de auditoría

### 3.2 API Gateway Layer

#### 3.2.1 Kong API Gateway
**Responsabilidades:**
- Punto de entrada único para todas las APIs
- Autenticación y autorización centralizadas
- Rate limiting y throttling
- Load balancing entre servicios
- API versioning y documentación

**Plugins Utilizados:**
- JWT Authentication
- Rate Limiting
- CORS
- Request/Response Transformer
- Prometheus (métricas)

**Configuración:**
```yaml
services:
  - name: inventory-service
    url: http://inventory-service:3001
    routes:
      - name: inventory-routes
        paths: ["/api/v1/inventory"]
    plugins:
      - name: jwt
      - name: rate-limiting
        config:
          minute: 100
```

### 3.3 Business Logic Layer

#### 3.3.1 Inventory Service
**Responsabilidades:**
- Gestión de stock y movimientos
- Control de entradas y salidas
- Cálculo de disponibilidad
- Reservas temporales

**API Endpoints:**
```
GET    /api/v1/inventory/stock/{productId}
POST   /api/v1/inventory/movements
PUT    /api/v1/inventory/adjust
GET    /api/v1/inventory/locations
POST   /api/v1/inventory/reserve
```

**Base de Datos:**
- Tabla: `inventory_movements`
- Tabla: `stock_levels`
- Tabla: `reservations`
- Tabla: `locations`

#### 3.3.2 Product Service
**Responsabilidades:**
- Catálogo maestro de productos
- Gestión de categorías
- Códigos de barras y SKUs
- Imágenes y documentos

**API Endpoints:**
```
GET    /api/v1/products
POST   /api/v1/products
PUT    /api/v1/products/{id}
DELETE /api/v1/products/{id}
GET    /api/v1/categories
POST   /api/v1/categories
```

#### 3.3.3 User Service
**Responsabilidades:**
- Autenticación y autorización
- Gestión de usuarios y roles
- Perfiles y preferencias
- Sesiones y tokens

**API Endpoints:**
```
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
GET    /api/v1/users/profile
PUT    /api/v1/users/profile
```

#### 3.3.4 Notification Service
**Responsabilidades:**
- Alertas de stock bajo
- Notificaciones push
- Emails automáticos
- Webhooks para integraciones

**Canales Soportados:**
- Email (SMTP)
- SMS (Twilio)
- Push Notifications (Firebase)
- Webhooks (HTTP)

#### 3.3.5 Report Service
**Responsabilidades:**
- Generación de reportes
- Exportación a múltiples formatos
- Reportes programados
- Analytics y métricas

**Tipos de Reportes:**
- Stock actual por ubicación
- Movimientos por período
- Productos más/menos vendidos
- Análisis de rotación
- Reportes de auditoría

#### 3.3.6 Alert Service
**Responsabilidades:**
- Monitoreo continuo de stock
- Evaluación de reglas de alerta
- Escalamiento de alertas
- Historial de alertas

**Reglas de Alerta:**
- Stock mínimo alcanzado
- Stock máximo excedido
- Productos sin movimiento
- Diferencias significativas en conteos

### 3.4 Data Access Layer

#### 3.4.1 PostgreSQL (Base de Datos Principal)
**Esquema de Base de Datos:**

```sql
-- Productos
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id),
    unit_price DECIMAL(10,2),
    unit_of_measure VARCHAR(20),
    barcode VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Categorías
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    parent_id UUID REFERENCES categories(id),
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Ubicaciones
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('warehouse', 'store', 'transit')),
    address TEXT,
    is_active BOOLEAN DEFAULT true
);

-- Niveles de Stock
CREATE TABLE stock_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id),
    location_id UUID REFERENCES locations(id),
    quantity DECIMAL(10,3) NOT NULL DEFAULT 0,
    reserved_quantity DECIMAL(10,3) NOT NULL DEFAULT 0,
    min_stock DECIMAL(10,3),
    max_stock DECIMAL(10,3),
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE(product_id, location_id)
);

-- Movimientos de Inventario
CREATE TABLE inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id),
    location_id UUID REFERENCES locations(id),
    movement_type VARCHAR(20) CHECK (movement_type IN ('in', 'out', 'adjustment', 'transfer')),
    quantity DECIMAL(10,3) NOT NULL,
    reference_number VARCHAR(50),
    notes TEXT,
    user_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Usuarios
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(20) CHECK (role IN ('admin', 'manager', 'warehouse', 'sales')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Alertas
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id),
    alert_type VARCHAR(20) CHECK (alert_type IN ('low_stock', 'high_stock', 'no_movement')),
    threshold_value DECIMAL(10,3),
    current_value DECIMAL(10,3),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);
```

#### 3.4.2 Redis (Cache y Sesiones)
**Uso:**
- Cache de consultas frecuentes
- Sesiones de usuario
- Rate limiting
- Pub/Sub para notificaciones en tiempo real

**Configuración:**
```redis
# Cache de productos más consultados
SET product:12345 '{"id":"12345","name":"Producto A","stock":100}'
EXPIRE product:12345 3600

# Sesiones de usuario
SET session:abc123 '{"userId":"user123","role":"manager"}'
EXPIRE session:abc123 86400

# Rate limiting
INCR rate_limit:user123:api_calls
EXPIRE rate_limit:user123:api_calls 60
```

#### 3.4.3 Elasticsearch (Búsqueda y Analytics)
**Índices:**
- `products`: Búsqueda de productos
- `movements`: Análisis de movimientos
- `logs`: Logs de aplicación y auditoría

**Mapping de Productos:**
```json
{
  "mappings": {
    "properties": {
      "sku": {"type": "keyword"},
      "name": {"type": "text", "analyzer": "spanish"},
      "description": {"type": "text", "analyzer": "spanish"},
      "category": {"type": "keyword"},
      "stock": {"type": "integer"},
      "price": {"type": "float"},
      "created_at": {"type": "date"}
    }
  }
}
```

#### 3.4.4 File Storage (AWS S3 / MinIO)
**Estructura:**
```
inventory-bucket/
├── products/
│   ├── images/
│   │   ├── thumbnails/
│   │   ├── medium/
│   │   └── large/
│   └── documents/
├── reports/
│   ├── daily/
│   ├── weekly/
│   └── monthly/
└── backups/
    ├── database/
    └── configurations/
```

## 4. Patrones de Comunicación

### 4.1 Comunicación Síncrona
**REST APIs:**
- Operaciones CRUD básicas
- Consultas en tiempo real
- Validaciones inmediatas

**GraphQL (Futuro):**
- Consultas complejas con múltiples entidades
- Optimización de transferencia de datos
- Schema unificado

### 4.2 Comunicación Asíncrona
**Message Queues (RabbitMQ):**
- Procesamiento de reportes pesados
- Notificaciones por email
- Sincronización entre servicios

**Event Streaming (Apache Kafka - Futuro):**
- Eventos de cambio de stock
- Auditoría en tiempo real
- Analytics de comportamiento

### 4.3 Eventos del Sistema
```json
{
  "eventType": "inventory.stock.updated",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "productId": "12345",
    "locationId": "warehouse-01",
    "previousStock": 50,
    "newStock": 45,
    "movementType": "sale",
    "userId": "user123"
  }
}
```

## 5. Seguridad

### 5.1 Autenticación
- **JWT Tokens** con refresh tokens
- **Multi-factor Authentication** (opcional)
- **OAuth 2.0** para integraciones
- **LDAP/Active Directory** para empresas

### 5.2 Autorización
**Roles y Permisos:**
```json
{
  "roles": {
    "admin": ["*"],
    "manager": ["inventory:read", "inventory:write", "reports:read", "users:read"],
    "warehouse": ["inventory:read", "inventory:write", "products:read"],
    "sales": ["inventory:read", "products:read"]
  }
}
```

### 5.3 Seguridad de Datos
- **Encriptación en tránsito** (TLS 1.3)
- **Encriptación en reposo** (AES-256)
- **Hashing de contraseñas** (bcrypt)
- **Sanitización de inputs**
- **SQL Injection prevention**

## 6. Monitoreo y Observabilidad

### 6.1 Métricas (Prometheus)
```yaml
# Métricas de aplicación
inventory_stock_level{product_id, location_id}
inventory_movements_total{type, location}
api_requests_total{method, endpoint, status}
api_request_duration_seconds{method, endpoint}

# Métricas de infraestructura
cpu_usage_percent{service}
memory_usage_bytes{service}
disk_usage_percent{service}
```

### 6.2 Logs (ELK Stack)
**Estructura de Logs:**
```json
{
  "@timestamp": "2024-01-15T10:30:00.000Z",
  "level": "INFO",
  "service": "inventory-service",
  "traceId": "abc123",
  "userId": "user123",
  "action": "stock_update",
  "productId": "12345",
  "message": "Stock updated successfully"
}
```

### 6.3 Trazabilidad (Jaeger)
- **Distributed tracing** entre microservicios
- **Performance monitoring**
- **Error tracking**
- **Dependency mapping**

## 7. Despliegue y DevOps

### 7.1 Containerización (Docker)
```dockerfile
# Dockerfile para Inventory Service
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

### 7.2 Orquestación (Kubernetes)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: inventory-service
  template:
    metadata:
      labels:
        app: inventory-service
    spec:
      containers:
      - name: inventory-service
        image: inventory-service:latest
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
```

### 7.3 CI/CD Pipeline (GitHub Actions)
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: npm test
  
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker image
        run: docker build -t inventory-service .
      - name: Push to registry
        run: docker push inventory-service
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Kubernetes
        run: kubectl apply -f k8s/
```

## 8. Escalabilidad y Performance

### 8.1 Estrategias de Escalado
- **Horizontal scaling** de microservicios
- **Database sharding** por ubicación geográfica
- **CDN** para assets estáticos
- **Load balancing** con health checks

### 8.2 Optimizaciones
- **Database indexing** en campos frecuentemente consultados
- **Query optimization** con EXPLAIN ANALYZE
- **Connection pooling** para base de datos
- **Caching strategies** multi-nivel

### 8.3 Límites de Performance
- **Throughput:** 1,000 requests/second
- **Latency:** <200ms percentil 95
- **Concurrent users:** 500 usuarios simultáneos
- **Data volume:** 1M productos, 10M movimientos/año

## 9. Disaster Recovery

### 9.1 Backup Strategy
- **Database backups:** Diarios con retención de 30 días
- **File backups:** Semanal para imágenes y documentos
- **Configuration backups:** Con cada deployment

### 9.2 High Availability
- **Multi-AZ deployment** en cloud
- **Database replication** master-slave
- **Service redundancy** mínimo 2 instancias
- **Health checks** y auto-recovery

### 9.3 Recovery Procedures
- **RTO (Recovery Time Objective):** 4 horas
- **RPO (Recovery Point Objective):** 1 hora
- **Automated failover** para servicios críticos
- **Manual procedures** documentados

---

**Documento de Arquitectura v1.0**  
**Última actualización:** Enero 2024  
**Próxima revisión:** Marzo 2024