# Manual de Administrador - Sistema de Inventario PYMES

## 🛡️ Guía Completa para Administradores del Sistema

**Versión:** 1.0  
**Fecha:** Enero 2024  
**Audiencia:** Administradores del sistema  

---

## 🎯 Introducción

Como administrador del Sistema de Inventario PYMES, tienes acceso completo a todas las funcionalidades y configuraciones. Este manual te guiará en la gestión, configuración y mantenimiento del sistema.

### Responsabilidades del Administrador
- ✅ Gestión de usuarios y permisos
- ✅ Configuración del sistema
- ✅ Monitoreo y mantenimiento
- ✅ Respaldos y seguridad
- ✅ Soporte a usuarios finales

---

## 🔐 Panel de Administración

### Acceso al Panel
1. **Iniciar sesión** con cuenta de administrador
2. **Navegar** a Configuración → Administración
3. **Verificar permisos** de administrador activos

### Vista General del Panel
- **Dashboard Administrativo:** Métricas del sistema
- **Gestión de Usuarios:** Crear, editar, desactivar usuarios
- **Configuración Global:** Parámetros del sistema
- **Monitoreo:** Estado de servicios y rendimiento
- **Logs y Auditoría:** Registro de actividades

---

## 👥 Gestión de Usuarios

### Crear Nuevo Usuario

1. **Acceder a gestión**
   - Panel Admin → Usuarios → Nuevo Usuario

2. **Información básica**
   ```
   Email: [email@empresa.com]
   Nombre: [Nombre completo]
   Teléfono: [Número de contacto]
   Cargo: [Posición en la empresa]
   ```

3. **Configuración de acceso**
   ```
   Rol: [Seleccionar rol apropiado]
   Estado: Activo/Inactivo
   Requiere cambio de contraseña: Sí/No
   Fecha de expiración: [Opcional]
   ```

4. **Permisos específicos**
   - Seleccionar módulos accesibles
   - Definir ubicaciones permitidas
   - Configurar restricciones horarias

### Roles de Usuario Disponibles

#### Administrador (ADMIN)
- **Permisos:** Acceso completo al sistema
- **Funciones:**
  - Gestión de usuarios
  - Configuración del sistema
  - Acceso a todos los módulos
  - Generación de reportes avanzados

#### Gerente (MANAGER)
- **Permisos:** Gestión operativa completa
- **Funciones:**
  - Gestión de inventario
  - Reportes y análisis
  - Configuración de alertas
  - Supervisión de operaciones

#### Almacén (WAREHOUSE)
- **Permisos:** Operaciones de inventario
- **Funciones:**
  - Registro de movimientos
  - Consulta de stock
  - Ajustes de inventario
  - Gestión de ubicaciones

#### Ventas (SALES)
- **Permisos:** Consulta y ventas
- **Funciones:**
  - Consulta de stock
  - Registro de salidas por venta
  - Reportes de ventas
  - Gestión de clientes

#### Visualizador (VIEWER)
- **Permisos:** Solo lectura
- **Funciones:**
  - Consulta de información
  - Visualización de reportes
  - Dashboard básico

### Gestión de Permisos Avanzados

#### Permisos por Módulo
```yaml
Productos:
  - Crear: Admin, Manager
  - Editar: Admin, Manager, Warehouse
  - Eliminar: Admin
  - Consultar: Todos

Inventario:
  - Movimientos: Admin, Manager, Warehouse
  - Ajustes: Admin, Manager
  - Consultas: Todos excepto Viewer limitado

Reportes:
  - Generar: Admin, Manager, Sales
  - Programar: Admin, Manager
  - Exportar: Admin, Manager
```

#### Restricciones por Ubicación
- Asignar usuarios a ubicaciones específicas
- Limitar acceso a almacenes por región
- Configurar permisos de transferencia

### Desactivar/Reactivar Usuarios

1. **Desactivación temporal**
   - Mantiene datos del usuario
   - Bloquea acceso inmediatamente
   - Permite reactivación posterior

2. **Eliminación permanente**
   - Solo para casos excepcionales
   - Requiere confirmación adicional
   - Transfiere datos a usuario genérico

---

## ⚙️ Configuración del Sistema

### Configuración General

#### Información de la Empresa
```
Nombre de la Empresa: [Nombre legal]
Nombre Comercial: [Nombre comercial]
NIT/RUT: [Identificación fiscal]
Dirección: [Dirección principal]
Teléfono: [Teléfono principal]
Email: [Email corporativo]
Sitio Web: [URL del sitio web]
```

#### Configuración Regional
```
País: [País de operación]
Zona Horaria: [Zona horaria local]
Idioma: [Idioma principal]
Moneda: [Moneda local]
Formato de Fecha: [DD/MM/YYYY o MM/DD/YYYY]
Separador Decimal: [Punto o coma]
```

### Configuración de Inventario

#### Parámetros Globales
```yaml
Métodos de Valoración:
  - FIFO (First In, First Out)
  - LIFO (Last In, First Out)
  - Promedio Ponderado
  - Costo Específico

Configuración de Stock:
  - Permitir Stock Negativo: Sí/No
  - Redondeo de Cantidades: 0, 2, 4 decimales
  - Unidades de Medida por Defecto: unidad
  - Alertas Automáticas: Activadas

Numeración Automática:
  - SKU: Prefijo + Número secuencial
  - Movimientos: Formato personalizable
  - Reportes: Numeración correlativa
```

#### Configuración de Alertas
```yaml
Stock Bajo:
  - Umbral Global: 10 unidades
  - Porcentaje del Stock Máximo: 20%
  - Frecuencia de Verificación: Cada hora

Stock Agotado:
  - Notificación Inmediata: Activada
  - Escalamiento: Después de 2 horas
  - Destinatarios: Gerentes y Administradores

Productos sin Movimiento:
  - Período de Inactividad: 90 días
  - Verificación: Semanal
  - Incluir en Reportes: Sí
```

### Configuración de Notificaciones

#### Canales de Notificación
1. **Email**
   ```yaml
   Servidor SMTP: smtp.empresa.com
   Puerto: 587
   Seguridad: STARTTLS
   Usuario: notificaciones@empresa.com
   Plantillas: Personalizables
   ```

2. **SMS** (Opcional)
   ```yaml
   Proveedor: [Proveedor SMS]
   API Key: [Clave de API]
   Números Autorizados: Lista de números
   ```

3. **Push Notifications**
   ```yaml
   Aplicación Móvil: Activadas
   Navegador Web: Activadas
   Horario: 24/7 o Horario laboral
   ```

---

## 📊 Monitoreo y Mantenimiento

### Dashboard Administrativo

#### Métricas del Sistema
- **Usuarios Activos:** Conectados en las últimas 24h
- **Transacciones:** Movimientos procesados por hora
- **Rendimiento:** Tiempo de respuesta promedio
- **Almacenamiento:** Uso de base de datos y archivos
- **Errores:** Logs de errores recientes

#### Alertas del Sistema
- **Servicios Caídos:** Notificación inmediata
- **Alto Uso de CPU/Memoria:** Umbral del 80%
- **Espacio en Disco:** Menos del 20% disponible
- **Conexiones de BD:** Más del 80% del pool

### Mantenimiento Preventivo

#### Tareas Diarias
- [ ] Verificar respaldos automáticos
- [ ] Revisar logs de errores
- [ ] Monitorear rendimiento del sistema
- [ ] Verificar alertas pendientes

#### Tareas Semanales
- [ ] Análisis de uso de almacenamiento
- [ ] Revisión de usuarios inactivos
- [ ] Optimización de base de datos
- [ ] Actualización de documentación

#### Tareas Mensuales
- [ ] Auditoría de seguridad
- [ ] Revisión de permisos de usuario
- [ ] Análisis de rendimiento histórico
- [ ] Planificación de capacidad

### Logs y Auditoría

#### Tipos de Logs
1. **Logs de Aplicación**
   - Errores del sistema
   - Transacciones fallidas
   - Tiempos de respuesta lentos

2. **Logs de Seguridad**
   - Intentos de login fallidos
   - Cambios de permisos
   - Accesos no autorizados

3. **Logs de Auditoría**
   - Cambios en datos críticos
   - Operaciones administrativas
   - Exportación de datos

#### Consulta de Logs
```sql
-- Ejemplo de consulta de auditoría
SELECT 
    al.created_at,
    u.email,
    al.table_name,
    al.operation,
    al.old_values,
    al.new_values
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.created_at >= NOW() - INTERVAL '7 days'
ORDER BY al.created_at DESC;
```

---

## 💾 Respaldos y Recuperación

### Configuración de Respaldos

#### Respaldo Automático
```yaml
Frecuencia: Diario a las 2:00 AM
Retención: 30 días
Ubicación: AWS S3 / Servidor local
Encriptación: AES-256
Compresión: Activada
Notificación: Email al completar
```

#### Tipos de Respaldo
1. **Completo**
   - Base de datos completa
   - Archivos de aplicación
   - Configuraciones del sistema
   - Frecuencia: Semanal

2. **Incremental**
   - Solo cambios desde último respaldo
   - Más rápido y eficiente
   - Frecuencia: Diaria

3. **Diferencial**
   - Cambios desde último respaldo completo
   - Balance entre velocidad y completitud
   - Frecuencia: Según necesidad

### Procedimiento de Restauración

#### Restauración Completa
1. **Preparación**
   ```bash
   # Detener servicios
   sudo systemctl stop inventario-pymes
   sudo systemctl stop postgresql
   ```

2. **Restaurar Base de Datos**
   ```bash
   # Restaurar desde respaldo
   pg_restore -h localhost -U postgres -d inventario_pymes backup_file.sql
   ```

3. **Restaurar Archivos**
   ```bash
   # Restaurar archivos de aplicación
   tar -xzf app_backup.tar.gz -C /opt/inventario-pymes/
   ```

4. **Verificación**
   ```bash
   # Iniciar servicios
   sudo systemctl start postgresql
   sudo systemctl start inventario-pymes
   
   # Verificar funcionamiento
   curl http://localhost:3001/health
   ```

#### Restauración Selectiva
- Restaurar solo tablas específicas
- Recuperar datos de fechas particulares
- Restaurar configuraciones específicas

---

## 🔒 Seguridad y Compliance

### Configuración de Seguridad

#### Políticas de Contraseñas
```yaml
Longitud Mínima: 8 caracteres
Complejidad: 
  - Al menos 1 mayúscula
  - Al menos 1 minúscula
  - Al menos 1 número
  - Al menos 1 carácter especial
Expiración: 90 días
Historial: No reutilizar últimas 5
Intentos Fallidos: Bloquear después de 5
```

#### Configuración de Sesiones
```yaml
Duración Máxima: 8 horas
Inactividad: 30 minutos
Sesiones Concurrentes: 3 por usuario
Logout Automático: Activado
```

#### Configuración de Red
```yaml
HTTPS: Obligatorio
TLS Versión: 1.2 mínimo
CORS: Dominios específicos
Rate Limiting: 100 req/min por IP
Firewall: Puertos específicos
```

### Auditoría de Seguridad

#### Revisiones Regulares
- **Usuarios Inactivos:** Revisar mensualmente
- **Permisos Excesivos:** Auditar trimestralmente
- **Accesos Sospechosos:** Monitorear continuamente
- **Vulnerabilidades:** Escanear semanalmente

#### Reportes de Seguridad
1. **Reporte de Accesos**
   - Logins por usuario y fecha
   - Intentos fallidos
   - Accesos fuera de horario

2. **Reporte de Cambios**
   - Modificaciones de datos críticos
   - Cambios de configuración
   - Operaciones administrativas

---

## 📈 Reportes Administrativos

### Reportes del Sistema

#### Reporte de Uso
- Usuarios más activos
- Funciones más utilizadas
- Horarios de mayor actividad
- Dispositivos de acceso

#### Reporte de Rendimiento
- Tiempos de respuesta por módulo
- Consultas más lentas
- Uso de recursos del servidor
- Tendencias de crecimiento

#### Reporte de Errores
- Errores más frecuentes
- Módulos con más problemas
- Usuarios afectados
- Resoluciones aplicadas

### Configuración de Reportes

#### Programación Automática
```yaml
Reporte Diario:
  - Resumen de actividad
  - Alertas generadas
  - Errores del sistema

Reporte Semanal:
  - Estadísticas de uso
  - Rendimiento del sistema
  - Usuarios nuevos/inactivos

Reporte Mensual:
  - Análisis de tendencias
  - Métricas de negocio
  - Recomendaciones de optimización
```

---

## 🛠️ Solución de Problemas

### Problemas Comunes

#### Rendimiento Lento
**Síntomas:** Páginas cargan lentamente
**Causas Posibles:**
- Alto uso de CPU/memoria
- Consultas de base de datos lentas
- Muchos usuarios concurrentes

**Soluciones:**
1. Optimizar consultas de BD
2. Aumentar recursos del servidor
3. Implementar caché
4. Revisar índices de BD

#### Errores de Conexión
**Síntomas:** Usuarios no pueden conectarse
**Causas Posibles:**
- Servidor de aplicación caído
- Base de datos no disponible
- Problemas de red

**Soluciones:**
1. Verificar estado de servicios
2. Reiniciar servicios si es necesario
3. Revisar logs de error
4. Verificar conectividad de red

#### Problemas de Sincronización
**Síntomas:** Datos inconsistentes entre usuarios
**Causas Posibles:**
- Transacciones no completadas
- Problemas de concurrencia
- Errores en la lógica de negocio

**Soluciones:**
1. Revisar logs de transacciones
2. Ejecutar scripts de corrección
3. Implementar locks apropiados
4. Notificar a usuarios afectados

---

## 📞 Escalamiento y Soporte

### Contactos de Soporte Técnico

#### Soporte Nivel 1 (Usuarios)
- **Email:** soporte@inventario-pymes.com
- **Teléfono:** +57 (1) 234-5678
- **Horario:** 8:00 AM - 6:00 PM

#### Soporte Nivel 2 (Administradores)
- **Email:** admin-support@inventario-pymes.com
- **Teléfono:** +57 (1) 234-5679
- **Horario:** 24/7 para emergencias

#### Soporte Nivel 3 (Desarrollo)
- **Email:** dev-support@inventario-pymes.com
- **Disponibilidad:** Bajo solicitud

### Procedimiento de Escalamiento

1. **Problema Identificado**
   - Documentar síntomas
   - Recopilar logs relevantes
   - Intentar solución básica

2. **Escalamiento Interno**
   - Consultar documentación
   - Revisar base de conocimientos
   - Contactar equipo técnico interno

3. **Escalamiento Externo**
   - Contactar soporte técnico
   - Proporcionar información detallada
   - Seguir instrucciones del soporte

---

## ✅ Checklist del Administrador

### Configuración Inicial
- [ ] Configurar información de la empresa
- [ ] Crear usuarios iniciales
- [ ] Configurar ubicaciones
- [ ] Establecer categorías de productos
- [ ] Configurar alertas y notificaciones
- [ ] Verificar respaldos automáticos

### Mantenimiento Regular
- [ ] Revisar logs diariamente
- [ ] Monitorear rendimiento
- [ ] Verificar respaldos
- [ ] Auditar usuarios activos
- [ ] Revisar alertas del sistema
- [ ] Actualizar documentación

### Seguridad
- [ ] Revisar permisos de usuario
- [ ] Auditar accesos sospechosos
- [ ] Verificar políticas de contraseñas
- [ ] Revisar logs de seguridad
- [ ] Actualizar certificados SSL
- [ ] Realizar pruebas de penetración

---

**Manual de Administrador v1.0 - Enero 2024**

*Para soporte técnico especializado, contacta: admin-support@inventario-pymes.com*