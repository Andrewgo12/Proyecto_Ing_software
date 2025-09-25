# 🚀 Guía de Despliegue - Sistema Inventario PYMES

## 📋 Prerrequisitos

### Infraestructura Mínima
- **CPU**: 2 cores (4 recomendado)
- **RAM**: 4GB (8GB recomendado)
- **Storage**: 20GB SSD
- **Network**: 100Mbps

### Software Requerido
- Docker 20.10+
- Docker Compose 2.0+
- Node.js 18+ (para desarrollo)
- PostgreSQL 14+ (si no usa Docker)
- Redis 7+ (si no usa Docker)

## 🐳 Despliegue con Docker (Recomendado)

### 1. Preparación
```bash
# Clonar repositorio
git clone https://github.com/inventario-pymes/sistema-inventario-pymes.git
cd sistema-inventario-pymes

# Configurar variables de entorno
cp .env.example .env
# Editar .env con valores de producción
```

### 2. Variables de Entorno Críticas
```bash
# .env
NODE_ENV=production
DB_HOST=database
DB_NAME=inventario_pymes
DB_USER=postgres
DB_PASSWORD=<secure-password>
JWT_SECRET=<strong-jwt-secret>
REDIS_URL=redis://redis:6379
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=<email>
EMAIL_PASS=<app-password>
```

### 3. Despliegue Completo
```bash
# Construir y ejecutar todos los servicios
docker-compose -f docker-compose.prod.yml up -d

# Verificar estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

### 4. Inicialización de Base de Datos
```bash
# Ejecutar migraciones
docker-compose exec backend npm run migrate

# Cargar datos iniciales
docker-compose exec backend npm run seed:production
```

## ☸️ Despliegue en Kubernetes

### 1. Preparar Cluster
```bash
# Crear namespace
kubectl create namespace inventario-pymes

# Aplicar configuraciones
kubectl apply -f deployment/kubernetes/
```

### 2. Configurar Secrets
```bash
# Crear secrets
kubectl create secret generic app-secrets \
  --from-literal=jwt-secret=<jwt-secret> \
  --from-literal=db-password=<db-password> \
  --namespace=inventario-pymes
```

### 3. Verificar Despliegue
```bash
# Verificar pods
kubectl get pods -n inventario-pymes

# Verificar servicios
kubectl get services -n inventario-pymes

# Ver logs
kubectl logs -f deployment/backend -n inventario-pymes
```

## 🌩️ Despliegue en AWS con Terraform

### 1. Configurar AWS CLI
```bash
aws configure
# Ingresar Access Key, Secret Key, Region
```

### 2. Desplegar Infraestructura
```bash
cd deployment/terraform

# Inicializar Terraform
terraform init

# Planificar despliegue
terraform plan

# Aplicar cambios
terraform apply
```

### 3. Recursos Creados
- **ECS Cluster**: Para contenedores
- **RDS PostgreSQL**: Base de datos gestionada
- **ElastiCache Redis**: Cache gestionado
- **ALB**: Load balancer
- **CloudFront**: CDN
- **S3**: Almacenamiento de archivos
- **Route53**: DNS

## 🔧 Configuración de Nginx (Proxy Reverso)

### nginx.conf
```nginx
upstream backend {
    server backend:3001;
}

server {
    listen 80;
    server_name inventario-pymes.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name inventario-pymes.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    # Frontend
    location / {
        root /var/www/html;
        try_files $uri $uri/ /index.html;
    }

    # API
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 📊 Monitoreo y Health Checks

### Health Check Endpoints
```javascript
// Backend health check
GET /api/health
Response: {
  status: "healthy",
  timestamp: "2024-01-15T10:30:00Z",
  services: {
    database: "connected",
    redis: "connected",
    email: "configured"
  }
}
```

### Docker Health Checks
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/api/health || exit 1
```

### Kubernetes Probes
```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 3001
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /api/ready
    port: 3001
  initialDelaySeconds: 5
  periodSeconds: 5
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Push Docker Images
        run: |
          docker build -t inventario/backend:${{ github.sha }} .
          docker push inventario/backend:${{ github.sha }}
      
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/backend \
            backend=inventario/backend:${{ github.sha }} \
            -n inventario-pymes
```

## 🔐 SSL/TLS Configuration

### Let's Encrypt con Certbot
```bash
# Instalar certbot
sudo apt install certbot python3-certbot-nginx

# Obtener certificado
sudo certbot --nginx -d inventario-pymes.com

# Auto-renovación
sudo crontab -e
# Agregar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📈 Escalamiento

### Horizontal Pod Autoscaler (K8s)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Database Scaling
```bash
# Read replicas para PostgreSQL
# Configurar en RDS o usar streaming replication

# Redis Cluster para cache distribuido
redis-cli --cluster create \
  redis1:6379 redis2:6379 redis3:6379 \
  --cluster-replicas 1
```

## 🔍 Troubleshooting

### Comandos Útiles
```bash
# Ver logs de contenedor específico
docker logs -f inventario-backend

# Conectar a base de datos
docker-compose exec database psql -U postgres -d inventario_pymes

# Verificar conectividad Redis
docker-compose exec redis redis-cli ping

# Reiniciar servicio específico
docker-compose restart backend

# Verificar uso de recursos
docker stats
```

### Problemas Comunes

1. **Error de Conexión a DB**
   ```bash
   # Verificar que la DB esté corriendo
   docker-compose ps database
   
   # Verificar logs de la DB
   docker-compose logs database
   ```

2. **JWT Errors**
   ```bash
   # Verificar JWT_SECRET en .env
   # Regenerar secret si es necesario
   openssl rand -base64 32
   ```

3. **Performance Issues**
   ```bash
   # Verificar uso de CPU/RAM
   docker stats
   
   # Verificar queries lentas en DB
   docker-compose exec database psql -U postgres -c "
   SELECT query, mean_time, calls 
   FROM pg_stat_statements 
   ORDER BY mean_time DESC LIMIT 10;"
   ```

## 📋 Checklist de Despliegue

### Pre-Despliegue
- [ ] Variables de entorno configuradas
- [ ] Certificados SSL válidos
- [ ] Base de datos respaldada
- [ ] Tests pasando
- [ ] Documentación actualizada

### Post-Despliegue
- [ ] Health checks funcionando
- [ ] Logs sin errores críticos
- [ ] Performance dentro de parámetros
- [ ] Backup automático configurado
- [ ] Monitoreo activo
- [ ] Alertas configuradas

## 🆘 Rollback Procedure

### Docker Compose
```bash
# Rollback rápido
docker-compose down
git checkout <previous-commit>
docker-compose up -d
```

### Kubernetes
```bash
# Rollback deployment
kubectl rollout undo deployment/backend -n inventario-pymes

# Verificar rollback
kubectl rollout status deployment/backend -n inventario-pymes
```

## 📞 Soporte

### Contactos de Emergencia
- **DevOps**: devops@inventariopymes.com
- **Backend**: backend@inventariopymes.com
- **Infraestructura**: infra@inventariopymes.com

### Documentación Adicional
- [Arquitectura del Sistema](ARCHITECTURE.md)
- [Guía de Seguridad](SECURITY.md)
- [Manual de Operaciones](../manuales/administrador/manual-administrador.md)

---

*Para soporte 24/7, contactar al equipo de DevOps.*