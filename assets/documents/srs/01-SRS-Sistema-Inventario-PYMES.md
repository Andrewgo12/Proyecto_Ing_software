# Software Requirements Specification (SRS)
## Sistema de Inventario para PYMES

**Versión:** 1.0  
**Fecha:** Enero 2024  
**Proyecto:** SIP-2024-001

---

## 1. INTRODUCCIÓN

### 1.1 Propósito
Este documento especifica los requisitos del Sistema de Inventario para PYMES, dirigido a desarrolladores, testers, stakeholders y usuarios finales.

### 1.2 Alcance
**Nombre del Software:** Sistema de Inventario PYMES (SIP)

**Funcionalidades principales:**
- Control de inventario en tiempo real
- Gestión de productos y categorías
- Alertas automáticas de stock
- Reportes y analytics
- Integración con proveedores

**Beneficios:**
- Reducción de pérdidas por descontrol: 80%
- Mejora en eficiencia operacional: 60%
- Exactitud de inventario: ≥98%

### 1.3 Definiciones y Acrónimos

| Término | Definición |
|---------|------------|
| PYME | Pequeña y Mediana Empresa |
| SKU | Stock Keeping Unit - Código único de producto |
| API | Application Programming Interface |
| CRUD | Create, Read, Update, Delete |
| MVP | Minimum Viable Product |
| ROI | Return on Investment |

### 1.4 Referencias
- IEEE Std 830-1998 - Software Requirements Specifications
- ISO/IEC 25010:2011 - Systems and software Quality Requirements
- Metodología Scrum Guide 2020

### 1.5 Visión General
El documento se organiza en:
- Sección 2: Descripción general del sistema
- Sección 3: Requisitos específicos detallados
- Sección 4: Casos de uso principales
- Sección 5: Apéndices y referencias

---

## 2. DESCRIPCIÓN GENERAL

### 2.1 Perspectiva del Producto
El SIP es un sistema web independiente con aplicación móvil complementaria, diseñado para reemplazar métodos manuales de control de inventario.

**Interfaces del sistema:**
- Interface web responsive (React.js)
- API RESTful (Node.js/Express)
- Base de datos PostgreSQL
- App móvil (React Native)
- Integración con códigos de barras

### 2.2 Funciones del Producto

#### Funciones Principales:
1. **Gestión de Inventario**
   - Control de stock en tiempo real
   - Múltiples ubicaciones de almacén
   - Movimientos de entrada y salida

2. **Gestión de Productos**
   - Catálogo maestro de productos
   - Categorización jerárquica
   - Códigos de barras y SKUs

3. **Alertas y Notificaciones**
   - Stock mínimo y máximo
   - Productos próximos a vencer
   - Movimientos inusuales

4. **Reportes y Analytics**
   - Dashboard ejecutivo
   - Reportes de rotación
   - Análisis de tendencias

### 2.3 Características de Usuarios

| Tipo de Usuario | Experiencia | Frecuencia de Uso | Funciones Principales |
|-----------------|-------------|-------------------|----------------------|
| Administrador | Avanzada | Diaria | Configuración, reportes, usuarios |
| Auxiliar Bodega | Básica | Diaria | Entradas, salidas, conteos |
| Gerente | Intermedia | Semanal | Reportes, análisis, decisiones |
| Vendedor | Básica | Diaria | Consulta stock, reservas |

### 2.4 Restricciones

#### Técnicas:
- Debe funcionar en navegadores modernos (Chrome 90+, Firefox 88+)
- Compatible con dispositivos móviles Android 8+ e iOS 12+
- Base de datos PostgreSQL 12+

#### Regulatorias:
- Cumplimiento GDPR para datos personales
- Normativas fiscales colombianas
- Estándares de facturación electrónica DIAN

#### Operacionales:
- Disponibilidad 99.5% en horario comercial
- Backup automático diario
- Tiempo de recuperación < 4 horas

### 2.5 Suposiciones y Dependencias

#### Suposiciones:
- Los usuarios tendrán acceso a internet estable
- Dispositivos con cámara para códigos de barras
- Personal capacitado en uso básico de computadores

#### Dependencias:
- Servicios de hosting cloud (AWS/Azure)
- Proveedores de códigos de barras
- Integración con sistemas contables existentes

---

## 3. REQUISITOS ESPECÍFICOS

### 3.1 Requisitos Funcionales

#### RF-001: Autenticación de Usuarios
**Descripción:** El sistema debe permitir autenticación segura de usuarios.
**Prioridad:** Alta
**Criterios de Aceptación:**
- Login con email y contraseña
- Validación de credenciales en <2 segundos
- Bloqueo después de 3 intentos fallidos
- Recuperación de contraseña por email

#### RF-002: Gestión de Productos
**Descripción:** El sistema debe permitir CRUD completo de productos.
**Prioridad:** Alta
**Criterios de Aceptación:**
- Crear producto con nombre, SKU, categoría, precio
- Editar información de productos existentes
- Eliminar productos (soft delete)
- Búsqueda por nombre, SKU o categoría

#### RF-003: Control de Stock
**Descripción:** El sistema debe mantener control preciso del inventario.
**Prioridad:** Alta
**Criterios de Aceptación:**
- Actualización en tiempo real de cantidades
- Registro de movimientos con fecha/hora/usuario
- Soporte para múltiples unidades de medida
- Validación de stock negativo

#### RF-004: Alertas Automáticas
**Descripción:** El sistema debe generar alertas de stock bajo.
**Prioridad:** Media
**Criterios de Aceptación:**
- Configuración de stock mínimo por producto
- Notificaciones por email y en sistema
- Dashboard con productos en alerta
- Historial de alertas generadas

#### RF-005: Reportes de Inventario
**Descripción:** El sistema debe generar reportes detallados.
**Prioridad:** Media
**Criterios de Aceptación:**
- Reporte de stock actual por ubicación
- Movimientos por período de tiempo
- Productos más/menos vendidos
- Exportación a Excel/PDF

#### RF-006: Códigos de Barras
**Descripción:** El sistema debe soportar lectura de códigos de barras.
**Prioridad:** Media
**Criterios de Aceptación:**
- Escaneo desde cámara web/móvil
- Búsqueda automática por código
- Generación de códigos para productos nuevos
- Soporte para códigos QR

#### RF-007: Múltiples Ubicaciones
**Descripción:** El sistema debe manejar múltiples bodegas/tiendas.
**Prioridad:** Baja
**Criterios de Aceptación:**
- Configuración de ubicaciones
- Stock independiente por ubicación
- Transferencias entre ubicaciones
- Reportes consolidados y por ubicación

#### RF-008: Gestión de Proveedores
**Descripción:** El sistema debe gestionar información de proveedores.
**Prioridad:** Baja
**Criterios de Aceptación:**
- CRUD de proveedores
- Asociación productos-proveedores
- Historial de compras por proveedor
- Datos de contacto y términos comerciales

### 3.2 Requisitos No Funcionales

#### RNF-001: Rendimiento
**Descripción:** El sistema debe responder rápidamente a las consultas.
**Criterios:**
- Tiempo de respuesta < 2 segundos para consultas
- Carga de página inicial < 3 segundos
- Soporte para 100 usuarios concurrentes
- Procesamiento de 1000 transacciones/hora

#### RNF-002: Disponibilidad
**Descripción:** El sistema debe estar disponible durante horario comercial.
**Criterios:**
- Uptime 99.5% en horario 6AM-10PM
- Mantenimiento programado fuera de horario
- Tiempo de recuperación < 4 horas
- Backup automático cada 24 horas

#### RNF-003: Seguridad
**Descripción:** El sistema debe proteger la información empresarial.
**Criterios:**
- Encriptación HTTPS para todas las comunicaciones
- Hashing de contraseñas con bcrypt
- Tokens JWT con expiración
- Logs de auditoría para acciones críticas

#### RNF-004: Usabilidad
**Descripción:** El sistema debe ser fácil de usar para usuarios no técnicos.
**Criterios:**
- Interface intuitiva con máximo 3 clics para funciones principales
- Responsive design para móviles y tablets
- Mensajes de error claros y accionables
- Tutorial integrado para nuevos usuarios

#### RNF-005: Escalabilidad
**Descripción:** El sistema debe crecer con las necesidades del negocio.
**Criterios:**
- Arquitectura modular para agregar funcionalidades
- Base de datos optimizada para 100,000+ productos
- API RESTful para integraciones futuras
- Caching para mejorar rendimiento

### 3.3 Requisitos de Dominio

#### RD-001: Normativas Fiscales
**Descripción:** El sistema debe cumplir regulaciones fiscales colombianas.
**Criterios:**
- Integración con facturación electrónica DIAN
- Retención de registros por 10 años
- Reportes para declaraciones tributarias
- Trazabilidad completa de movimientos

#### RD-002: Estándares de Inventario
**Descripción:** El sistema debe seguir mejores prácticas de inventario.
**Criterios:**
- Método FIFO (First In, First Out) por defecto
- Soporte para códigos de barras estándar (EAN-13, UPC)
- Unidades de medida estándar (kg, lt, unidades)
- Categorización según clasificación industrial

#### RD-003: Integración Contable
**Descripción:** El sistema debe integrarse con software contable existente.
**Criterios:**
- Exportación en formato estándar (CSV, XML)
- API para sincronización automática
- Mapeo de cuentas contables
- Conciliación de diferencias

---

## 4. CASOS DE USO PRINCIPALES

### CU-001: Registrar Entrada de Mercancía
**Actor:** Auxiliar de Bodega
**Precondición:** Usuario autenticado, productos registrados
**Flujo Principal:**
1. Usuario selecciona "Nueva Entrada"
2. Sistema muestra formulario de entrada
3. Usuario escanea código de barras o busca producto
4. Usuario ingresa cantidad recibida
5. Sistema actualiza stock automáticamente
6. Sistema genera comprobante de entrada

### CU-002: Consultar Stock Disponible
**Actor:** Vendedor
**Precondición:** Usuario autenticado
**Flujo Principal:**
1. Usuario accede a consulta de inventario
2. Usuario busca producto por nombre o código
3. Sistema muestra stock actual por ubicación
4. Usuario puede reservar cantidad para venta
5. Sistema actualiza stock reservado

### CU-003: Generar Reporte de Inventario
**Actor:** Gerente
**Precondición:** Usuario con permisos de reportes
**Flujo Principal:**
1. Usuario accede a módulo de reportes
2. Usuario selecciona tipo de reporte y filtros
3. Sistema procesa información
4. Sistema presenta reporte en pantalla
5. Usuario puede exportar a Excel/PDF

---

## 5. APÉNDICES

### A. Matriz de Trazabilidad
| Requisito | Caso de Uso | Prioridad | Estado |
|-----------|-------------|-----------|---------|
| RF-001 | CU-001, CU-002, CU-003 | Alta | Pendiente |
| RF-002 | CU-001, CU-002 | Alta | Pendiente |
| RF-003 | CU-001, CU-002 | Alta | Pendiente |

### B. Glosario de Términos
- **Stock:** Cantidad disponible de un producto
- **SKU:** Código único identificador de producto
- **Movimiento:** Transacción que afecta el inventario
- **Ubicación:** Lugar físico donde se almacena inventario

---

**Documento aprobado por:**
- Product Owner: [Nombre]
- Tech Lead: [Nombre]
- Stakeholder Principal: [Nombre]

**Fecha de aprobación:** [Fecha]
**Próxima revisión:** [Fecha + 30 días]