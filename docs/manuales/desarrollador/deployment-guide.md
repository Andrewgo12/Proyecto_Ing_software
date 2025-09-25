# Guía de Despliegue - Sistema de Inventario PYMES

## 🚀 Despliegue del Sistema

### Prerrequisitos
```bash
# Herramientas requeridas
- Docker 20+
- Kubernetes 1.27+
- kubectl configurado
- Helm 3+
- Terraform 1.6+ (opcional)
```

### Despliegue Local (Desarrollo)
```bash
# Clonar repositorio
git clone https://github.com/inventario-pymes/sistema.git
cd sistema

# Variables de entorno
cp .env.example .env
# Editar .env con configuraciones locales

# Levantar servicios
docker-compose -f deployment/docker/docker-compose.dev.yml up -d

# Verificar servicios
curl http://localhost:3001/health
curl http://localhost:3000
```

### Despliegue en Kubernetes
```bash
# Crear namespace
kubectl apply -f deployment/kubernetes/namespace.yaml

# Configurar secrets
kubectl apply -f deployment/kubernetes/secrets.yaml

# Desplegar servicios
kubectl apply -f deployment/kubernetes/deployments/
kubectl apply -f deployment/kubernetes/services/
kubectl apply -f deployment/kubernetes/ingress.yaml

# Verificar despliegue
kubectl get pods -n inventario-pymes
kubectl get services -n inventario-pymes
```

### Despliegue con Script Automatizado
```bash
# Dar permisos
chmod +x deployment/scripts/deploy.sh

# Desplegar a staging
./deployment/scripts/deploy.sh --environment staging

# Desplegar a producción
./deployment/scripts/deploy.sh --environment production --confirm
```

### Variables de Entorno Críticas
```bash
# Base de datos
DATABASE_URL=postgresql://user:pass@host:5432/db
DB_SSL=true

# Redis
REDIS_URL=redis://host:6379
REDIS_PASSWORD=secure-password

# JWT
JWT_SECRET=super-secret-key-change-in-production
JWT_EXPIRES_IN=24h

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=notifications@empresa.com
EMAIL_PASS=app-password
```

### Verificación Post-Despliegue
```bash
# Health checks
curl https://api.inventario-pymes.com/health
curl https://inventario-pymes.com/health

# Smoke tests
./deployment/scripts/health-check.sh --environment production

# Verificar logs
kubectl logs -f deployment/backend -n inventario-pymes
```

### Rollback en Caso de Problemas
```bash
# Rollback automático
./deployment/scripts/rollback.sh --environment production

# Rollback manual
kubectl rollout undo deployment/backend -n inventario-pymes
kubectl rollout undo deployment/frontend -n inventario-pymes
```

### Monitoreo Post-Despliegue
```bash
# Métricas clave a monitorear
- Response time < 500ms
- Error rate < 1%
- CPU usage < 70%
- Memory usage < 80%
- Database connections < 80%
```

### Troubleshooting Común
```bash
# Pods no inician
kubectl describe pod <pod-name> -n inventario-pymes

# Problemas de conectividad
kubectl exec -it <pod-name> -n inventario-pymes -- nslookup postgres-service

# Logs de errores
kubectl logs <pod-name> -n inventario-pymes --previous
```