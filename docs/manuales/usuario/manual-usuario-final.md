# Manual de Usuario Final - Sistema de Inventario PYMES

## 📖 Guía Completa para Usuarios

**Versión:** 1.0  
**Fecha:** Enero 2024  
**Audiencia:** Usuarios finales del sistema  

---

## 🚀 Introducción

Bienvenido al Sistema de Inventario PYMES, una solución integral diseñada para simplificar la gestión de inventario en pequeñas y medianas empresas. Este manual te guiará paso a paso para aprovechar al máximo todas las funcionalidades del sistema.

### ¿Qué puedes hacer con el sistema?
- ✅ Gestionar productos y categorías
- ✅ Controlar niveles de stock en tiempo real
- ✅ Registrar movimientos de inventario
- ✅ Generar reportes y análisis
- ✅ Configurar alertas automáticas
- ✅ Gestionar múltiples ubicaciones

---

## 🔐 Acceso al Sistema

### Inicio de Sesión Web
1. **Acceder a la plataforma**
   - Visita: `https://inventario-pymes.com`
   - Ingresa tu email y contraseña
   - Haz clic en "Iniciar Sesión"

2. **Primera vez en el sistema**
   - Recibirás un email de bienvenida
   - Haz clic en "Activar Cuenta"
   - Crea tu contraseña segura
   - Completa tu perfil

### Aplicación Móvil
1. **Descarga la app**
   - iOS: App Store → "Inventario PYMES"
   - Android: Google Play → "Inventario PYMES"

2. **Configuración inicial**
   - Abre la aplicación
   - Ingresa la URL de tu empresa
   - Inicia sesión con tus credenciales

---

## 🏠 Dashboard Principal

### Vista General
El dashboard es tu centro de control principal donde puedes:

#### Métricas Clave (KPIs)
- **Total de Productos:** Cantidad total en catálogo
- **Valor del Inventario:** Valor monetario total
- **Productos con Stock Bajo:** Alertas de reabastecimiento
- **Movimientos del Día:** Actividad reciente

#### Gráficos y Análisis
- **Tendencia de Inventario:** Evolución del stock en el tiempo
- **Productos Más Vendidos:** Top 10 productos por movimiento
- **Alertas Activas:** Notificaciones pendientes
- **Actividad Reciente:** Últimos movimientos registrados

### Navegación Rápida
- **Menú Principal:** Acceso a todos los módulos
- **Búsqueda Global:** Encuentra productos rápidamente
- **Notificaciones:** Alertas y mensajes del sistema
- **Perfil de Usuario:** Configuración personal

---

## 📦 Gestión de Productos

### Crear Nuevo Producto

1. **Acceder al módulo**
   - Menú → "Productos" → "Nuevo Producto"

2. **Información Básica**
   ```
   Nombre del Producto: [Nombre descriptivo]
   SKU: [Código único del producto]
   Categoría: [Seleccionar de la lista]
   Descripción: [Descripción detallada]
   ```

3. **Información Comercial**
   ```
   Precio de Venta: $[Precio al público]
   Costo de Compra: $[Costo de adquisición]
   Unidad de Medida: [unidad/kg/litro/etc.]
   Código de Barras: [Opcional]
   ```

4. **Control de Stock**
   ```
   Stock Mínimo: [Cantidad mínima]
   Stock Máximo: [Cantidad máxima]
   Punto de Reorden: [Nivel de reabastecimiento]
   ```

5. **Guardar Producto**
   - Revisar información
   - Hacer clic en "Guardar Producto"

### Editar Producto Existente

1. **Buscar producto**
   - Usar barra de búsqueda
   - O navegar por categorías

2. **Modificar información**
   - Hacer clic en el producto
   - Seleccionar "Editar"
   - Actualizar campos necesarios
   - Guardar cambios

### Gestión de Categorías

1. **Crear nueva categoría**
   - Productos → "Categorías" → "Nueva"
   - Ingresar nombre y descripción
   - Seleccionar categoría padre (opcional)

2. **Organizar productos**
   - Arrastrar y soltar productos
   - O usar función "Cambiar Categoría"

---

## 📊 Control de Inventario

### Consultar Stock Actual

1. **Vista de inventario**
   - Menú → "Inventario" → "Stock Actual"
   - Ver lista completa de productos
   - Filtrar por categoría, ubicación o estado

2. **Información mostrada**
   - Producto y SKU
   - Stock actual por ubicación
   - Estado (Normal/Bajo/Agotado)
   - Última actualización

### Registrar Movimientos

#### Entrada de Mercancía
1. **Acceder a movimientos**
   - Inventario → "Movimientos" → "Nueva Entrada"

2. **Completar formulario**
   ```
   Tipo: Entrada
   Producto: [Seleccionar producto]
   Cantidad: [Cantidad recibida]
   Ubicación: [Almacén de destino]
   Proveedor: [Opcional]
   Referencia: [Número de factura/orden]
   Notas: [Observaciones]
   ```

3. **Confirmar entrada**
   - Revisar información
   - Hacer clic en "Registrar Entrada"

#### Salida de Mercancía
1. **Registrar salida**
   - Inventario → "Movimientos" → "Nueva Salida"

2. **Datos requeridos**
   ```
   Tipo: Salida
   Producto: [Producto a retirar]
   Cantidad: [Cantidad a retirar]
   Ubicación: [Almacén origen]
   Motivo: [Venta/Uso interno/Daño/etc.]
   Cliente: [Opcional]
   ```

#### Transferencias entre Ubicaciones
1. **Crear transferencia**
   - Movimientos → "Transferencia"

2. **Configurar transferencia**
   ```
   Producto: [Seleccionar]
   Cantidad: [Cantidad a transferir]
   Origen: [Ubicación actual]
   Destino: [Ubicación destino]
   Motivo: [Razón de la transferencia]
   ```

### Ajustes de Inventario

1. **Cuándo usar ajustes**
   - Diferencias en conteo físico
   - Productos dañados o vencidos
   - Corrección de errores

2. **Realizar ajuste**
   - Inventario → "Ajustes"
   - Seleccionar producto y ubicación
   - Ingresar cantidad real
   - Especificar motivo del ajuste
   - Confirmar ajuste

---

## 🏢 Gestión de Ubicaciones

### Crear Nueva Ubicación

1. **Acceder a ubicaciones**
   - Configuración → "Ubicaciones" → "Nueva"

2. **Información de ubicación**
   ```
   Nombre: [Nombre del almacén/área]
   Código: [Código único]
   Tipo: [Almacén/Tienda/Tránsito]
   Dirección: [Dirección física]
   Responsable: [Encargado del área]
   ```

### Configurar Ubicaciones

1. **Propiedades avanzadas**
   - Permitir stock negativo: Sí/No
   - Capacidad máxima: [Opcional]
   - Horarios de operación
   - Restricciones de acceso

2. **Asignar productos**
   - Definir qué productos se almacenan
   - Establecer niveles mínimos/máximos por ubicación

---

## 🔔 Sistema de Alertas

### Tipos de Alertas

1. **Stock Bajo**
   - Se activa cuando el stock llega al punto de reorden
   - Aparece en dashboard y notificaciones

2. **Stock Agotado**
   - Producto sin existencias
   - Prioridad alta en alertas

3. **Sobrestock**
   - Cuando se supera el stock máximo
   - Ayuda a optimizar espacio

4. **Productos sin Movimiento**
   - Productos sin actividad en período definido
   - Útil para identificar inventario obsoleto

### Configurar Alertas

1. **Acceder a configuración**
   - Configuración → "Alertas"

2. **Personalizar alertas**
   ```
   Frecuencia: [Inmediata/Diaria/Semanal]
   Canales: [Email/SMS/Push/Dashboard]
   Umbrales: [Personalizar por producto]
   Destinatarios: [Usuarios a notificar]
   ```

---

## 📈 Reportes y Análisis

### Reportes Disponibles

#### Reporte de Inventario
- **Contenido:** Stock actual por producto y ubicación
- **Filtros:** Categoría, ubicación, fecha
- **Formatos:** PDF, Excel, CSV

#### Reporte de Movimientos
- **Contenido:** Historial de entradas y salidas
- **Período:** Personalizable
- **Detalles:** Producto, cantidad, usuario, fecha

#### Análisis de Rotación
- **Contenido:** Velocidad de rotación por producto
- **Métricas:** Días de inventario, frecuencia de movimiento
- **Utilidad:** Optimización de compras

#### Valorización de Inventario
- **Contenido:** Valor monetario del inventario
- **Métodos:** FIFO, LIFO, Promedio ponderado
- **Detalles:** Por categoría y ubicación

### Generar Reportes

1. **Seleccionar reporte**
   - Reportes → [Tipo de reporte]

2. **Configurar parámetros**
   ```
   Período: [Fecha inicio - Fecha fin]
   Filtros: [Categoría/Ubicación/Producto]
   Formato: [PDF/Excel/CSV]
   Envío: [Descargar/Email]
   ```

3. **Generar y descargar**
   - Hacer clic en "Generar Reporte"
   - Esperar procesamiento
   - Descargar archivo

---

## 📱 Uso de la Aplicación Móvil

### Funcionalidades Principales

#### Consulta de Stock
- Buscar productos por nombre o código
- Escanear código de barras
- Ver stock en tiempo real
- Consultar ubicaciones

#### Registro Rápido
- Entradas y salidas rápidas
- Transferencias entre ubicaciones
- Ajustes de inventario
- Toma de fotos para evidencia

#### Alertas Móviles
- Notificaciones push
- Alertas de stock bajo
- Recordatorios de tareas

### Funciones Offline

1. **Sincronización automática**
   - Los datos se sincronizan al recuperar conexión
   - Indicador de estado de sincronización

2. **Funciones disponibles offline**
   - Consulta de productos descargados
   - Registro de movimientos (se envían al conectar)
   - Visualización de reportes guardados

---

## ⚙️ Configuración Personal

### Perfil de Usuario

1. **Actualizar información**
   - Perfil → "Editar Información"
   - Cambiar nombre, email, teléfono
   - Actualizar foto de perfil

2. **Cambiar contraseña**
   - Perfil → "Seguridad"
   - Ingresar contraseña actual
   - Crear nueva contraseña segura

### Preferencias del Sistema

1. **Configuración de pantalla**
   ```
   Idioma: [Español/Inglés]
   Zona horaria: [Seleccionar]
   Formato de fecha: [DD/MM/YYYY]
   Moneda: [COP/USD/EUR]
   ```

2. **Notificaciones**
   ```
   Email: [Activar/Desactivar]
   Push móvil: [Activar/Desactivar]
   Frecuencia: [Inmediata/Resumen diario]
   ```

---

## 🆘 Solución de Problemas Comunes

### Problemas de Acceso

**No puedo iniciar sesión**
1. Verificar email y contraseña
2. Usar "Recuperar contraseña"
3. Contactar al administrador

**La página no carga**
1. Verificar conexión a internet
2. Limpiar caché del navegador
3. Probar en navegador diferente

### Problemas con Productos

**No encuentro un producto**
1. Verificar ortografía en búsqueda
2. Buscar por SKU o código de barras
3. Revisar si está en la categoría correcta

**Error al guardar producto**
1. Verificar campos obligatorios
2. Comprobar que el SKU sea único
3. Revisar formato de precios

### Problemas con Movimientos

**No puedo registrar una salida**
1. Verificar stock disponible
2. Comprobar permisos de usuario
3. Revisar que la ubicación esté activa

**Los números no coinciden**
1. Revisar movimientos recientes
2. Verificar ajustes de inventario
3. Contactar soporte para auditoría

---

## 📞 Soporte y Contacto

### Canales de Soporte

**Soporte Técnico**
- Email: soporte@inventario-pymes.com
- Teléfono: +57 (1) 234-5678
- Horario: Lunes a Viernes, 8:00 AM - 6:00 PM

**Chat en Línea**
- Disponible en la plataforma web
- Horario: Lunes a Viernes, 9:00 AM - 5:00 PM

**Centro de Ayuda**
- Base de conocimientos: help.inventario-pymes.com
- Videos tutoriales
- Preguntas frecuentes

### Información para Soporte

Cuando contactes soporte, ten a mano:
- Tu email de usuario
- Descripción del problema
- Pasos que realizaste
- Capturas de pantalla (si aplica)
- Navegador y versión utilizada

---

## 📚 Recursos Adicionales

### Documentación
- [Guía de Inicio Rápido](guia-inicio-rapido.md)
- [Preguntas Frecuentes](faq.md)
- [Solución de Problemas](troubleshooting.md)

### Videos Tutoriales
- Configuración inicial del sistema
- Gestión básica de productos
- Registro de movimientos
- Generación de reportes

### Actualizaciones
- Las nuevas funcionalidades se anuncian por email
- Revisa regularmente las notas de versión
- Participa en webinars de capacitación

---

**¡Gracias por usar el Sistema de Inventario PYMES!**

*Este manual se actualiza regularmente. Versión actual: 1.0 - Enero 2024*