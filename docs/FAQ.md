# ❓ Preguntas Frecuentes - Sistema Inventario PYMES

## 🚀 Instalación y Configuración

### ¿Cómo instalo el sistema?
```bash
git clone https://github.com/inventario-pymes/sistema-inventario-pymes.git
cd sistema-inventario-pymes
make setup
make dev
```

### ¿Qué requisitos necesito?
- Node.js 18+
- PostgreSQL 14+
- Redis 7+
- Docker (opcional pero recomendado)

### ¿Cómo configuro la base de datos?
1. Crear base de datos PostgreSQL
2. Configurar variables en `.env`
3. Ejecutar `make migrate`
4. Cargar datos iniciales con `make seed`

## 💼 Funcionalidades

### ¿Puedo gestionar múltiples ubicaciones?
Sí, el sistema soporta múltiples tiendas/almacenes con transferencias entre ubicaciones.

### ¿Funciona con códigos de barras?
Sí, incluye escáner móvil y soporte completo para códigos de barras/QR.

### ¿Genera reportes automáticos?
Sí, incluye dashboard en tiempo real y reportes exportables en PDF/Excel.

### ¿Envía alertas de stock bajo?
Sí, alertas automáticas por email cuando el stock está por debajo del mínimo.

## 📱 App Móvil

### ¿Está disponible en App Store/Play Store?
Actualmente es una PWA. La app nativa está en desarrollo.

### ¿Funciona offline?
Funcionalidad básica offline con sincronización automática.

### ¿Puedo escanear códigos con el móvil?
Sí, incluye escáner nativo de códigos de barras y QR.

## 🔐 Seguridad

### ¿Es seguro el sistema?
Sí, implementa JWT, encriptación, validaciones y sigue estándares OWASP.

### ¿Puedo controlar permisos de usuarios?
Sí, sistema completo de roles: admin, manager, warehouse, sales, viewer.

### ¿Los datos están encriptados?
Sí, encriptación en tránsito (HTTPS) y en reposo para datos sensibles.

## 🔧 Soporte Técnico

### ¿Dónde reporto bugs?
En GitHub Issues o enviando email a support@inventariopymes.com

### ¿Hay documentación técnica?
Sí, documentación completa en `/docs` y API docs en OpenAPI format.

### ¿Puedo contribuir al proyecto?
Sí, ver [CONTRIBUTING.md](../CONTRIBUTING.md) para guías de contribución.

## 💰 Costos

### ¿Es gratuito?
Sí, es open source bajo licencia MIT.

### ¿Hay costos de hosting?
Depende de tu proveedor de cloud. Incluye configuración para AWS, GCP, Azure.

### ¿Ofrecen soporte comercial?
Contactar a business@inventariopymes.com para soporte empresarial.

## 🔄 Actualizaciones

### ¿Cómo actualizo el sistema?
```bash
git pull origin main
make build
make migrate
```

### ¿Con qué frecuencia se actualiza?
Releases mensuales con patches de seguridad inmediatos.

### ¿Hay breaking changes?
Seguimos semantic versioning. Breaking changes solo en major versions.

## 📊 Performance

### ¿Cuántos productos soporta?
Optimizado para 10,000+ productos con performance excelente.

### ¿Cuántos usuarios concurrentes?
Soporta 100+ usuarios concurrentes con configuración estándar.

### ¿Es escalable?
Sí, arquitectura preparada para escalamiento horizontal.

## 🌐 Integración

### ¿Se integra con otros sistemas?
Sí, API REST completa y webhooks para integraciones.

### ¿Soporta importación de datos?
Sí, importación desde CSV/Excel y APIs de otros sistemas.

### ¿Hay SDKs disponibles?
Sí, SDKs para JavaScript, Python y PHP.

## 📞 Contacto

- **Soporte General**: support@inventariopymes.com
- **Soporte Técnico**: tech@inventariopymes.com
- **Ventas**: sales@inventariopymes.com
- **GitHub**: https://github.com/inventario-pymes