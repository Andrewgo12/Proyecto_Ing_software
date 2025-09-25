# Guía de Configuración de Desarrollo - Sistema de Inventario PYMES

## 🛠️ Configuración del Entorno de Desarrollo

Esta guía te ayudará a configurar tu entorno de desarrollo local para contribuir al proyecto.

---

## 📋 Prerrequisitos

### Software Requerido
- **Node.js** 18.x o superior
- **npm** 9.x o superior
- **Docker** 20.x o superior
- **Docker Compose** 2.x o superior
- **Git** 2.x o superior
- **PostgreSQL** 15.x (opcional, se puede usar Docker)
- **Redis** 7.x (opcional, se puede usar Docker)

### Herramientas Recomendadas
- **VS Code** con extensiones:
  - ES7+ React/Redux/React-Native snippets
  - Prettier - Code formatter
  - ESLint
  - Thunder Client (para testing de APIs)
  - Docker
  - PostgreSQL

---

## 🚀 Configuración Inicial

### 1. Clonar el Repositorio

```bash
# Clonar el repositorio
git clone https://github.com/inventario-pymes/sistema-inventario.git
cd sistema-inventario

# Configurar upstream (si es un fork)
git remote add upstream https://github.com/inventario-pymes/sistema-inventario.git
```

### 2. Configurar Variables de Entorno

```bash
# Copiar archivos de ejemplo
cp src/backend/.env.example src/backend/.env
cp src/frontend/.env.example src/frontend/.env

# Editar archivos .env con tus configuraciones locales
```

#### Backend (.env)
```env
# Base de datos
DATABASE_URL=postgresql://dev_user:dev_password@localhost:5432/inventario_pymes_dev
DB_HOST=localhost
DB_PORT=5432
DB_NAME=inventario_pymes_dev
DB_USER=dev_user
DB_PASSWORD=dev_password

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-super-secret-jwt-key-for-development
JWT_EXPIRES_IN=24h

# Aplicación
NODE_ENV=development
PORT=3001
LOG_LEVEL=debug

# CORS
CORS_ORIGIN=http://localhost:3000

# Email (desarrollo)
EMAIL_HOST=smtp.mailtrap.io
EMAIL_PORT=2525
EMAIL_USER=your-mailtrap-user
EMAIL_PASS=your-mailtrap-password
```

#### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:3001/api
REACT_APP_VERSION=dev
REACT_APP_ENVIRONMENT=development
GENERATE_SOURCEMAP=true
FAST_REFRESH=true
```

---

## 🐳 Configuración con Docker (Recomendado)

### Opción 1: Docker Compose Completo

```bash
# Levantar todos los servicios
docker-compose -f deployment/docker/docker-compose.dev.yml up -d

# Ver logs
docker-compose -f deployment/docker/docker-compose.dev.yml logs -f

# Parar servicios
docker-compose -f deployment/docker/docker-compose.dev.yml down
```

### Opción 2: Solo Base de Datos y Redis

```bash
# Solo servicios de infraestructura
docker-compose -f deployment/docker/docker-compose.dev.yml up -d postgres redis

# Verificar que estén corriendo
docker ps
```

---

## 💻 Configuración Manual (Alternativa)

### 1. Configurar PostgreSQL

```bash
# Instalar PostgreSQL (Ubuntu/Debian)
sudo apt update
sudo apt install postgresql postgresql-contrib

# Crear usuario y base de datos
sudo -u postgres psql
CREATE USER dev_user WITH PASSWORD 'dev_password';
CREATE DATABASE inventario_pymes_dev OWNER dev_user;
GRANT ALL PRIVILEGES ON DATABASE inventario_pymes_dev TO dev_user;
\q
```

### 2. Configurar Redis

```bash
# Instalar Redis (Ubuntu/Debian)
sudo apt install redis-server

# Iniciar Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verificar instalación
redis-cli ping
```

---

## 🗄️ Configuración de Base de Datos

### 1. Ejecutar Migraciones

```bash
cd src/backend

# Instalar dependencias
npm install

# Ejecutar migraciones
npm run migrate:dev

# Cargar datos de prueba
npm run seed:dev
```

### 2. Verificar Base de Datos

```bash
# Conectar a la base de datos
psql -h localhost -U dev_user -d inventario_pymes_dev

# Verificar tablas
\dt

# Verificar datos de prueba
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM users;
```

---

## 🖥️ Configuración del Backend

### 1. Instalar Dependencias

```bash
cd src/backend
npm install
```

### 2. Ejecutar en Modo Desarrollo

```bash
# Desarrollo con hot reload
npm run dev

# Desarrollo con debug
npm run dev:debug

# Ejecutar tests
npm test

# Ejecutar tests con coverage
npm run test:coverage
```

### 3. Verificar Backend

```bash
# Verificar health check
curl http://localhost:3001/health

# Verificar API
curl http://localhost:3001/api/products
```

---

## 🎨 Configuración del Frontend

### 1. Instalar Dependencias

```bash
cd src/frontend
npm install
```

### 2. Ejecutar en Modo Desarrollo

```bash
# Desarrollo con hot reload
npm start

# Ejecutar tests
npm test

# Ejecutar tests E2E
npm run test:e2e

# Build de producción
npm run build
```

### 3. Verificar Frontend

- Abrir navegador en `http://localhost:3000`
- Verificar que carga correctamente
- Probar login con usuario de prueba

---

## 📱 Configuración de la App Móvil

### 1. Prerrequisitos Adicionales

```bash
# Instalar React Native CLI
npm install -g @react-native-community/cli

# Para iOS (solo macOS)
sudo gem install cocoapods

# Para Android
# Instalar Android Studio y configurar SDK
```

### 2. Configurar Proyecto

```bash
cd src/mobile

# Instalar dependencias
npm install

# Para iOS
cd ios && pod install && cd ..

# Para Android (verificar configuración)
npx react-native doctor
```

### 3. Ejecutar en Desarrollo

```bash
# Iniciar Metro bundler
npx react-native start

# En otra terminal - iOS
npx react-native run-ios

# En otra terminal - Android
npx react-native run-android
```

---

## 🧪 Configuración de Testing

### 1. Tests Unitarios

```bash
# Backend
cd src/backend
npm test

# Frontend
cd src/frontend
npm test

# Con coverage
npm run test:coverage
```

### 2. Tests de Integración

```bash
# Configurar base de datos de test
npm run migrate:test
npm run seed:test

# Ejecutar tests de integración
npm run test:integration
```

### 3. Tests E2E

```bash
cd src/frontend

# Instalar Cypress
npm install cypress --save-dev

# Ejecutar tests E2E
npm run test:e2e
```

---

## 🔧 Herramientas de Desarrollo

### 1. Linting y Formatting

```bash
# Configurar pre-commit hooks
npx husky install

# Ejecutar linting
npm run lint

# Ejecutar formatting
npm run format

# Fix automático
npm run lint:fix
```

### 2. Debugging

#### Backend (VS Code)
```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Backend",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/backend/server.js",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "restart": true,
      "runtimeExecutable": "nodemon"
    }
  ]
}
```

#### Frontend (Chrome DevTools)
- Instalar React Developer Tools
- Usar Redux DevTools Extension

### 3. Base de Datos

```bash
# Herramientas útiles
npm install -g pgcli  # Cliente PostgreSQL mejorado
npm install -g redis-cli  # Cliente Redis

# Conectar con pgcli
pgcli postgresql://dev_user:dev_password@localhost:5432/inventario_pymes_dev
```

---

## 📊 Monitoreo Local

### 1. Logs

```bash
# Backend logs
tail -f src/backend/logs/app.log

# Docker logs
docker-compose -f deployment/docker/docker-compose.dev.yml logs -f backend
```

### 2. Métricas

```bash
# Instalar herramientas de monitoreo local
docker run -d -p 9090:9090 prom/prometheus
docker run -d -p 3001:3000 grafana/grafana
```

---

## 🚀 Flujo de Desarrollo

### 1. Crear Nueva Feature

```bash
# Crear rama desde develop
git checkout develop
git pull upstream develop
git checkout -b feature/nueva-funcionalidad

# Desarrollar y hacer commits
git add .
git commit -m "feat: agregar nueva funcionalidad"

# Push y crear PR
git push origin feature/nueva-funcionalidad
```

### 2. Estándares de Código

#### Commits (Conventional Commits)
```
feat: nueva funcionalidad
fix: corrección de bug
docs: actualización de documentación
style: cambios de formato
refactor: refactorización de código
test: agregar o modificar tests
chore: tareas de mantenimiento
```

#### Estructura de Archivos
```
src/
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── utils/
│   ├── tests/
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── hooks/
│   │   ├── services/
│   │   └── utils/
│   └── package.json
└── shared/
    ├── types/
    ├── constants/
    └── utils/
```

---

## 🆘 Solución de Problemas

### Problemas Comunes

#### Error de Conexión a Base de Datos
```bash
# Verificar que PostgreSQL esté corriendo
sudo systemctl status postgresql

# Verificar conexión
pg_isready -h localhost -p 5432

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

#### Error de Puertos Ocupados
```bash
# Verificar qué proceso usa el puerto
lsof -i :3001
lsof -i :3000

# Matar proceso si es necesario
kill -9 <PID>
```

#### Problemas con Node Modules
```bash
# Limpiar cache de npm
npm cache clean --force

# Eliminar node_modules y reinstalar
rm -rf node_modules package-lock.json
npm install
```

### Logs de Debug

```bash
# Backend con debug completo
DEBUG=* npm run dev

# Solo logs de la aplicación
DEBUG=app:* npm run dev

# Logs de base de datos
DEBUG=sequelize:* npm run dev
```

---

## 📚 Recursos Adicionales

### Documentación
- [Coding Standards](coding-standards.md)
- [API Integration Guide](api-integration-guide.md)
- [Deployment Guide](deployment-guide.md)

### Herramientas Útiles
- [Postman Collection](../../api-specs/postman-collection.json)
- [OpenAPI Spec](../../api-specs/openapi.yaml)
- [Database Schema](../../database/schemas/database-schema.sql)

### Comunidad
- Slack: #desarrollo-inventario-pymes
- Email: dev-team@inventario-pymes.com
- Wiki: https://wiki.inventario-pymes.com

---

## ✅ Checklist de Configuración

- [ ] Repositorio clonado
- [ ] Variables de entorno configuradas
- [ ] Docker funcionando
- [ ] Base de datos configurada y migrada
- [ ] Backend corriendo en puerto 3001
- [ ] Frontend corriendo en puerto 3000
- [ ] Tests pasando
- [ ] Linting configurado
- [ ] Pre-commit hooks instalados
- [ ] Herramientas de debug configuradas

---

**¡Listo para desarrollar!** 🚀

*Para dudas o problemas, contacta al equipo de desarrollo.*