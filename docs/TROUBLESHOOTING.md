# 🔧 Guía de Solución de Problemas

## 🚨 Problemas Comunes

### 1. Error de Conexión a Base de Datos

**Síntoma**: `Error: connect ECONNREFUSED 127.0.0.1:5432`

**Soluciones**:
```bash
# Verificar que PostgreSQL esté corriendo
sudo systemctl status postgresql

# Iniciar PostgreSQL si está detenido
sudo systemctl start postgresql

# Verificar configuración en .env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=inventario_pymes
DB_USER=postgres
DB_PASSWORD=your_password
```

### 2. Error de Autenticación JWT

**Síntoma**: `JsonWebTokenError: invalid token`

**Soluciones**:
```bash
# Verificar JWT_SECRET en .env
JWT_SECRET=your_super_secret_jwt_key_here

# Regenerar secret si es necesario
openssl rand -base64 32

# Limpiar tokens en localStorage (frontend)
localStorage.clear()
```

### 3. Puerto en Uso

**Síntoma**: `Error: listen EADDRINUSE :::3001`

**Soluciones**:
```bash
# Encontrar proceso usando el puerto
lsof -i :3001

# Terminar proceso
kill -9 <PID>

# O cambiar puerto en .env
PORT=3002
```

### 4. Problemas de CORS

**Síntoma**: `Access to fetch blocked by CORS policy`

**Soluciones**:
```javascript
// Verificar configuración CORS en backend
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));

// Verificar CORS_ORIGIN en .env
CORS_ORIGIN=http://localhost:3000
```

### 5. Error de Migraciones

**Síntoma**: `Migration failed`

**Soluciones**:
```bash
# Verificar estado de migraciones
npm run migrate:status

# Rollback última migración
npm run migrate:rollback

# Ejecutar migraciones paso a paso
npm run migrate:up
```

## 🐳 Problemas con Docker

### 1. Contenedor No Inicia

**Síntoma**: `Container exits with code 1`

**Soluciones**:
```bash
# Ver logs del contenedor
docker logs <container_name>

# Verificar configuración
docker-compose config

# Reconstruir imagen
docker-compose build --no-cache
```

### 2. Problemas de Red entre Contenedores

**Síntoma**: `getaddrinfo ENOTFOUND database`

**Soluciones**:
```bash
# Verificar red de Docker
docker network ls

# Inspeccionar red
docker network inspect <network_name>

# Usar nombres de servicio en lugar de localhost
DB_HOST=database  # No localhost
```

### 3. Volúmenes No Persisten

**Síntoma**: Datos se pierden al reiniciar

**Soluciones**:
```yaml
# Verificar volúmenes en docker-compose.yml
volumes:
  postgres_data:
    driver: local

services:
  database:
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

## 📱 Problemas Mobile

### 1. Expo No Inicia

**Síntoma**: `Expo CLI not found`

**Soluciones**:
```bash
# Instalar Expo CLI globalmente
npm install -g @expo/cli

# O usar npx
npx expo start

# Verificar versión
expo --version
```

### 2. Error de Metro Bundler

**Síntoma**: `Metro bundler failed to start`

**Soluciones**:
```bash
# Limpiar cache
npx expo start --clear

# Resetear Metro
npx expo start --reset-cache

# Verificar puerto
npx expo start --port 19001
```

### 3. Problemas de Permisos de Cámara

**Síntoma**: `Camera permission denied`

**Soluciones**:
```javascript
// Verificar permisos en app.json
{
  "expo": {
    "plugins": [
      [
        "expo-camera",
        {
          "cameraPermission": "Allow $(PRODUCT_NAME) to access your camera."
        }
      ]
    ]
  }
}
```

## 🔍 Debugging

### 1. Habilitar Logs Detallados

```bash
# Backend
LOG_LEVEL=debug npm run dev

# Frontend
VITE_LOG_LEVEL=debug npm run dev
```

### 2. Debugging con Chrome DevTools

```javascript
// Agregar breakpoints en código
debugger;

// Console logging
console.log('Debug info:', data);

// Network tab para requests
// Application tab para localStorage/sessionStorage
```

### 3. Debugging Base de Datos

```sql
-- Habilitar logging de queries
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

-- Ver queries lentas
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

## 🚀 Performance Issues

### 1. API Lenta

**Diagnóstico**:
```bash
# Verificar tiempo de respuesta
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:3001/api/products"

# Monitorear recursos
htop
```

**Soluciones**:
- Agregar índices a la base de datos
- Implementar cache con Redis
- Optimizar queries N+1
- Usar connection pooling

### 2. Frontend Lento

**Diagnóstico**:
- Usar Chrome DevTools Performance tab
- Lighthouse audit
- Bundle analyzer

**Soluciones**:
```javascript
// Code splitting
const Dashboard = lazy(() => import('./Dashboard'));

// Memoización
const MemoizedComponent = memo(Component);

// Virtual scrolling para listas grandes
```

## 📊 Monitoreo y Alertas

### 1. Health Checks

```bash
# Backend health
curl http://localhost:3001/api/health

# Database health
pg_isready -h localhost -p 5432

# Redis health
redis-cli ping
```

### 2. Logs Importantes

```bash
# Application logs
tail -f logs/app.log

# Database logs
tail -f /var/log/postgresql/postgresql-14-main.log

# Nginx logs
tail -f /var/log/nginx/access.log
```

## 🆘 Contacto de Soporte

### Información a Incluir en Reportes

1. **Versión del sistema**
2. **Sistema operativo**
3. **Pasos para reproducir**
4. **Logs de error**
5. **Screenshots si aplica**

### Canales de Soporte

- **GitHub Issues**: Para bugs y features
- **Email**: support@inventariopymes.com
- **Discord**: [Servidor de la comunidad]
- **Documentación**: https://docs.inventariopymes.com

### Soporte de Emergencia

Para problemas críticos en producción:
- **Email**: emergency@inventariopymes.com
- **Teléfono**: +1-555-PYMES-911
- **Tiempo de respuesta**: < 2 horas

---

*Si no encuentras la solución aquí, no dudes en contactar al equipo de soporte.*