# 🏢 Sistema Empresarial de Inventario PYMES

**Plataforma de gestión de inventario de nivel empresarial** con inteligencia artificial, análisis predictivo y arquitectura escalable para PYMES en crecimiento.

## 🎯 **Características Avanzadas**

### 💼 **Funcionalidades Empresariales**
- ✅ **Gestión Avanzada de Productos** con taxonomía inteligente, variantes, bundles y kits
- ✅ **Control de Inventario Predictivo** con ML para forecasting y optimización automática
- ✅ **Sistema de Alertas IA** con análisis de patrones y anomalías en tiempo real
- ✅ **Dashboard Ejecutivo** con KPIs dinámicos, drill-down y análisis comparativo
- ✅ **Business Intelligence** integrado con reportes OLAP y data mining
- ✅ **Escáner Inteligente** con OCR, reconocimiento de imágenes y validación automática
- ✅ **Predicción de Demanda** con algoritmos ARIMA, Prophet y redes neuronales
- ✅ **Integración Empresarial** con SAP, Oracle ERP, Microsoft Dynamics, Salesforce

### 🔍 **Capacidades de IA y Analytics**
- ✅ **Machine Learning** para optimización de stock y predicción de demanda
- ✅ **Computer Vision** para reconocimiento automático de productos
- ✅ **NLP** para procesamiento de órdenes y documentos
- ✅ **Anomaly Detection** para detección de fraudes y errores
- ✅ **Recommendation Engine** para sugerencias de reposición
- ✅ **Real-time Analytics** con Apache Kafka y Elasticsearch

## 🏗️ Arquitectura

### Frontend (React + Vite)
- **Framework**: React 18 con Vite
- **Styling**: Tailwind CSS
- **State Management**: React Query
- **Routing**: React Router DOM
- **Icons**: Lucide React

### Backend (Node.js + Express)
- **Runtime**: Node.js con Express
- **Database**: PostgreSQL con Knex.js
- **Authentication**: JWT con refresh tokens
- **Cache**: Redis
- **Email**: Nodemailer
- **Validation**: Joi

### Mobile (React Native + Expo)
- **Framework**: React Native con Expo
- **Navigation**: React Navigation
- **UI**: React Native Paper
- **Storage**: AsyncStorage
- **Camera**: Expo Camera + Barcode Scanner

### Database
- **Primary**: PostgreSQL
- **Cache**: Redis
- **Migrations**: Knex.js migrations
- **Seeds**: Data seeding para desarrollo

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Node.js 18+
- PostgreSQL 14+
- Redis 6+
- Git

### Configuración del Backend
```bash
cd src/backend
npm install
cp .env.example .env
# Configurar variables de entorno
npm run migrate
npm run seed
npm run dev
```

### Configuración del Frontend
```bash
cd src/frontend
npm install
npm run dev
```

### Configuración de la App Móvil
```bash
cd src/mobile
npm install
npx expo start
```

## 📱 Aplicaciones

### Web Application
- **URL**: http://localhost:3000
- **Admin**: admin@test.com / password123

### Mobile App
- **Platform**: iOS/Android via Expo
- **Features**: Escáner QR, Gestión offline

### API
- **Base URL**: http://localhost:3001/api
- **Documentation**: OpenAPI 3.0 disponible

## 🧪 Testing

### Tests Unitarios
```bash
# Backend
cd src/backend && npm test

# Frontend
cd src/frontend && npm test
```

### Tests de Integración
```bash
npm run test:integration
```

### Tests E2E
```bash
npm run test:e2e
```

## 🚀 Despliegue

### Docker
```bash
docker-compose up -d
```

### Kubernetes
```bash
kubectl apply -f deployment/kubernetes/
```

### Terraform (AWS)
```bash
cd deployment/terraform
terraform init
terraform plan
terraform apply
```

## 📊 Métricas del Proyecto

- **Cobertura de Tests**: 85%+
- **Performance**: Lighthouse 90+
- **Seguridad**: OWASP compliant
- **Escalabilidad**: Horizontal scaling ready

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 👥 Equipo

- **Desarrollo**: Inventario PYMES Team
- **Soporte**: soporte@inventariopymes.com
- **Documentación**: docs.inventariopymes.com

## 🔗 Enlaces Útiles

- [Documentación API](api-specs/api-documentation.md)
- [Manual de Usuario](docs/manuales/usuario/manual-usuario-final.md)
- [Guía de Desarrollo](docs/manuales/desarrollador/setup-desarrollo.md)
- [Roadmap del Proyecto](docs/project-charter.md)