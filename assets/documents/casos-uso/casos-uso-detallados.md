# Casos de Uso Detallados - Sistema de Inventario PYMES

## CU-001: Registrar Entrada de Mercancía

### Información General
- **ID:** CU-001
- **Nombre:** Registrar Entrada de Mercancía
- **Actor Principal:** Auxiliar de Bodega
- **Actores Secundarios:** Sistema de Notificaciones, Gerente
- **Tipo:** Primario, Esencial
- **Complejidad:** Media

### Descripción
Permite al auxiliar de bodega registrar la entrada de productos al inventario, actualizando automáticamente el stock y generando la trazabilidad correspondiente.

### Precondiciones
- El usuario debe estar autenticado en el sistema
- Los productos deben estar previamente registrados en el catálogo
- El usuario debe tener permisos de "Auxiliar de Bodega" o superior

### Postcondiciones
- El stock del producto se actualiza automáticamente
- Se genera un comprobante de entrada con número único
- Se registra la transacción en el historial de movimientos
- Se envía notificación al gerente si es necesario

### Flujo Principal
1. El auxiliar de bodega selecciona la opción "Nueva Entrada" en el menú principal
2. El sistema muestra el formulario de registro de entrada
3. El auxiliar escanea el código de barras del producto o lo busca manualmente
4. El sistema identifica el producto y muestra su información básica
5. El auxiliar ingresa la cantidad recibida y selecciona la ubicación de almacenamiento
6. El auxiliar puede agregar observaciones opcionales (lote, fecha de vencimiento, etc.)
7. El auxiliar confirma la entrada presionando "Registrar Entrada"
8. El sistema valida la información ingresada
9. El sistema actualiza el stock del producto automáticamente
10. El sistema genera un comprobante de entrada con número único
11. El sistema muestra mensaje de confirmación con el número de comprobante
12. El sistema registra la transacción en el log de auditoría

### Flujos Alternativos

#### FA-001: Producto no encontrado
**Punto de activación:** Paso 3 del flujo principal
1. El sistema no encuentra el producto con el código escaneado/ingresado
2. El sistema muestra mensaje "Producto no encontrado"
3. El sistema ofrece la opción de crear un nuevo producto
4. Si el auxiliar acepta, se redirige al caso de uso "Crear Producto"
5. Si el auxiliar cancela, regresa al paso 3 del flujo principal

#### FA-002: Cantidad inválida
**Punto de activación:** Paso 5 del flujo principal
1. El auxiliar ingresa una cantidad negativa o cero
2. El sistema muestra mensaje de error "La cantidad debe ser mayor a cero"
3. El sistema mantiene el foco en el campo cantidad
4. Regresa al paso 5 del flujo principal

#### FA-003: Múltiples productos
**Punto de activación:** Paso 3 del flujo principal
1. El auxiliar selecciona "Entrada Masiva"
2. El sistema permite escanear múltiples códigos de barras
3. Para cada producto escaneado, se repiten los pasos 4-6
4. El auxiliar puede revisar la lista completa antes de confirmar
5. Al confirmar, se procesan todas las entradas como una sola transacción

### Flujos de Excepción

#### FE-001: Error de conexión a base de datos
**Punto de activación:** Paso 9 del flujo principal
1. El sistema no puede conectarse a la base de datos
2. El sistema muestra mensaje "Error temporal del sistema. Intente nuevamente"
3. El sistema guarda la información localmente (si es posible)
4. El sistema permite reintentar la operación
5. Si persiste el error, se registra en el log de errores

#### FE-002: Stock negativo resultante
**Punto de activación:** Paso 9 del flujo principal
1. La operación resultaría en stock negativo (caso de ajuste negativo)
2. El sistema muestra advertencia "Esta operación resultará en stock negativo"
3. El sistema solicita confirmación del supervisor
4. Si se confirma, se procede con la operación
5. Si se cancela, regresa al paso 5 del flujo principal

### Requisitos Especiales
- **Rendimiento:** La operación debe completarse en menos de 3 segundos
- **Seguridad:** Todas las transacciones deben quedar registradas con usuario y timestamp
- **Usabilidad:** El formulario debe ser accesible desde dispositivos móviles
- **Confiabilidad:** El sistema debe manejar interrupciones de red graciosamente

### Información Adicional
- **Frecuencia de uso:** 50-100 veces por día
- **Criticidad:** Alta - operación core del negocio
- **Canales:** Web, Aplicación móvil
- **Reglas de negocio:** 
  - Solo se permiten cantidades positivas
  - Cada entrada debe tener un responsable identificado
  - Las entradas no se pueden eliminar, solo ajustar

---

## CU-002: Consultar Stock Disponible

### Información General
- **ID:** CU-002
- **Nombre:** Consultar Stock Disponible
- **Actor Principal:** Vendedor
- **Actores Secundarios:** Cliente (indirecto)
- **Tipo:** Primario, Esencial
- **Complejidad:** Baja

### Descripción
Permite a los vendedores consultar el stock disponible de productos para confirmar disponibilidad a los clientes y realizar reservas temporales.

### Precondiciones
- El usuario debe estar autenticado en el sistema
- El usuario debe tener permisos de "Vendedor" o superior
- Los productos deben estar registrados en el sistema

### Postcondiciones
- Se muestra la información actualizada del stock
- Se puede generar una reserva temporal del producto
- Se registra la consulta en el log de actividad

### Flujo Principal
1. El vendedor accede al módulo "Consulta de Inventario"
2. El sistema muestra la interfaz de búsqueda de productos
3. El vendedor ingresa criterios de búsqueda (nombre, código, categoría)
4. El sistema busca productos que coincidan con los criterios
5. El sistema muestra lista de productos encontrados con stock actual
6. El vendedor selecciona un producto específico
7. El sistema muestra información detallada del producto:
   - Stock disponible por ubicación
   - Stock reservado
   - Última actualización
   - Movimientos recientes
8. El vendedor puede opcionalmente reservar cantidad para venta
9. El sistema registra la consulta en el log de actividad

### Flujos Alternativos

#### FA-001: Búsqueda por código de barras
**Punto de activación:** Paso 3 del flujo principal
1. El vendedor selecciona "Buscar por código de barras"
2. El vendedor escanea el código usando cámara del dispositivo
3. El sistema identifica el producto automáticamente
4. Continúa en el paso 7 del flujo principal

#### FA-002: Reservar producto
**Punto de activación:** Paso 8 del flujo principal
1. El vendedor selecciona "Reservar para venta"
2. El sistema solicita cantidad a reservar
3. El vendedor ingresa la cantidad deseada
4. El sistema valida que hay stock suficiente
5. El sistema crea reserva temporal por 24 horas
6. El sistema actualiza el stock disponible
7. El sistema muestra confirmación de reserva

#### FA-003: Stock insuficiente
**Punto de activación:** Paso 7 del flujo principal
1. El producto tiene stock cero o insuficiente
2. El sistema muestra alerta "Stock insuficiente"
3. El sistema sugiere productos alternativos si existen
4. El sistema muestra fecha estimada de reposición
5. El vendedor puede suscribirse a notificaciones de restock

### Flujos de Excepción

#### FE-001: Producto no encontrado
**Punto de activación:** Paso 4 del flujo principal
1. No se encuentran productos con los criterios especificados
2. El sistema muestra mensaje "No se encontraron productos"
3. El sistema sugiere ampliar criterios de búsqueda
4. Regresa al paso 3 del flujo principal

#### FE-002: Error en reserva
**Punto de activación:** FA-002, paso 5
1. Otro usuario reservó el producto simultáneamente
2. El sistema muestra "Stock ya reservado por otro usuario"
3. El sistema actualiza la información de stock
4. Regresa al paso 7 del flujo principal

### Requisitos Especiales
- **Rendimiento:** Las consultas deben responder en menos de 2 segundos
- **Concurrencia:** Debe manejar múltiples consultas simultáneas
- **Actualización:** La información debe estar actualizada en tiempo real
- **Movilidad:** Debe funcionar correctamente en dispositivos móviles

---

## CU-003: Generar Reporte de Inventario

### Información General
- **ID:** CU-003
- **Nombre:** Generar Reporte de Inventario
- **Actor Principal:** Gerente
- **Actores Secundarios:** Sistema de Reportes, Sistema de Email
- **Tipo:** Secundario, Importante
- **Complejidad:** Alta

### Descripción
Permite a los gerentes generar reportes detallados del inventario para análisis y toma de decisiones, con opciones de filtrado y exportación.

### Precondiciones
- El usuario debe estar autenticado con permisos de "Gerente" o superior
- Debe existir información de inventario en el sistema
- Los parámetros de reporte deben estar configurados

### Postcondiciones
- Se genera el reporte según los criterios especificados
- El reporte se puede visualizar en pantalla o exportar
- Se registra la generación del reporte en el log de auditoría

### Flujo Principal
1. El gerente accede al módulo "Reportes de Inventario"
2. El sistema muestra las opciones de tipos de reporte disponibles
3. El gerente selecciona "Reporte de Stock Actual"
4. El sistema muestra formulario de parámetros del reporte
5. El gerente configura filtros (fechas, categorías, ubicaciones)
6. El gerente selecciona formato de salida (pantalla, Excel, PDF)
7. El gerente confirma la generación del reporte
8. El sistema valida los parámetros ingresados
9. El sistema procesa la información según los filtros
10. El sistema genera el reporte en el formato solicitado
11. El sistema muestra el reporte en pantalla o inicia descarga
12. El sistema registra la operación en el log de auditoría

### Flujos Alternativos

#### FA-001: Reporte programado
**Punto de activación:** Paso 2 del flujo principal
1. El gerente selecciona "Programar Reporte"
2. El sistema solicita frecuencia (diario, semanal, mensual)
3. El gerente configura parámetros y destinatarios
4. El sistema programa la generación automática
5. El sistema enviará el reporte por email según programación

#### FA-002: Reporte histórico
**Punto de activación:** Paso 3 del flujo principal
1. El gerente selecciona "Reporte de Movimientos"
2. El sistema solicita rango de fechas específico
3. El gerente define período de análisis
4. Continúa en paso 5 del flujo principal con datos históricos

#### FA-003: Exportación masiva
**Punto de activación:** Paso 6 del flujo principal
1. El gerente selecciona múltiples formatos de exportación
2. El sistema genera el reporte en todos los formatos
3. El sistema comprime los archivos en un ZIP
4. El sistema envía enlace de descarga por email

### Flujos de Excepción

#### FE-001: Volumen de datos excesivo
**Punto de activación:** Paso 9 del flujo principal
1. El reporte contiene más de 10,000 registros
2. El sistema muestra advertencia de tiempo de procesamiento
3. El sistema ofrece opciones de filtrado adicional
4. Si el gerente confirma, se procesa en background
5. Se envía notificación cuando esté listo

#### FE-002: Error en generación
**Punto de activación:** Paso 10 del flujo principal
1. Ocurre error durante la generación del reporte
2. El sistema muestra mensaje de error específico
3. El sistema registra el error en el log
4. El sistema ofrece reintentar o contactar soporte

### Requisitos Especiales
- **Rendimiento:** Reportes simples en <10 segundos, complejos en <2 minutos
- **Escalabilidad:** Debe manejar hasta 100,000 productos
- **Formato:** Soporte para Excel, PDF, CSV
- **Programación:** Capacidad de reportes automáticos

---

## CU-004: Configurar Alertas de Stock

### Información General
- **ID:** CU-004
- **Nombre:** Configurar Alertas de Stock
- **Actor Principal:** Administrador
- **Actores Secundarios:** Sistema de Notificaciones
- **Tipo:** Secundario, Importante
- **Complejidad:** Media

### Descripción
Permite configurar alertas automáticas para notificar cuando los productos alcancen niveles críticos de stock.

### Precondiciones
- Usuario autenticado con permisos de administrador
- Productos registrados en el sistema
- Sistema de notificaciones configurado

### Postcondiciones
- Se configuran las reglas de alerta para productos
- El sistema monitoreará automáticamente los niveles de stock
- Se activarán notificaciones según configuración

### Flujo Principal
1. El administrador accede a "Configuración de Alertas"
2. El sistema muestra lista de productos con configuración actual
3. El administrador selecciona un producto para configurar
4. El sistema muestra formulario de configuración de alertas
5. El administrador define:
   - Stock mínimo para alerta
   - Stock máximo (opcional)
   - Destinatarios de notificaciones
   - Frecuencia de notificaciones
6. El administrador guarda la configuración
7. El sistema valida los parámetros
8. El sistema activa el monitoreo automático
9. El sistema confirma la configuración guardada

### Flujos Alternativos

#### FA-001: Configuración masiva
**Punto de activación:** Paso 2 del flujo principal
1. El administrador selecciona "Configuración Masiva"
2. El sistema permite filtrar productos por categoría
3. El administrador aplica configuración a múltiples productos
4. El sistema procesa la configuración en lote

#### FA-002: Alertas por categoría
**Punto de activación:** Paso 3 del flujo principal
1. El administrador selecciona configurar por categoría
2. El sistema aplica reglas a todos los productos de la categoría
3. Los productos individuales pueden tener excepciones

### Requisitos Especiales
- **Tiempo Real:** Las alertas deben activarse inmediatamente
- **Confiabilidad:** No debe haber falsos positivos/negativos
- **Escalabilidad:** Debe manejar miles de productos monitoreados

---

## CU-005: Realizar Ajuste de Inventario

### Información General
- **ID:** CU-005
- **Nombre:** Realizar Ajuste de Inventario
- **Actor Principal:** Supervisor de Inventario
- **Actores Secundarios:** Sistema de Auditoría
- **Tipo:** Primario, Crítico
- **Complejidad:** Alta

### Descripción
Permite realizar ajustes al inventario para corregir diferencias encontradas en conteos físicos o por otras razones justificadas.

### Precondiciones
- Usuario con permisos de supervisor o superior
- Justificación documentada para el ajuste
- Autorización previa para ajustes significativos

### Postcondiciones
- El stock se ajusta según lo especificado
- Se registra la razón del ajuste
- Se genera reporte de ajuste para auditoría
- Se notifica a los responsables correspondientes

### Flujo Principal
1. El supervisor accede a "Ajustes de Inventario"
2. El sistema solicita justificación del ajuste
3. El supervisor selecciona tipo de ajuste (conteo físico, merma, etc.)
4. El supervisor busca y selecciona el producto a ajustar
5. El sistema muestra stock actual del producto
6. El supervisor ingresa la cantidad real encontrada
7. El sistema calcula la diferencia automáticamente
8. El supervisor confirma el ajuste con justificación
9. El sistema requiere autorización adicional si el ajuste es significativo
10. El sistema procesa el ajuste y actualiza el stock
11. El sistema genera comprobante de ajuste
12. El sistema registra la transacción en auditoría

### Flujos Alternativos

#### FA-001: Ajuste masivo por conteo
**Punto de activación:** Paso 1 del flujo principal
1. El supervisor selecciona "Ajuste por Conteo Físico"
2. El sistema permite cargar archivo con resultados de conteo
3. El sistema procesa las diferencias automáticamente
4. Se requiere aprobación para procesar todos los ajustes

### Flujos de Excepción

#### FE-001: Ajuste requiere autorización superior
**Punto de activación:** Paso 9 del flujo principal
1. El ajuste supera el límite autorizado para el supervisor
2. El sistema solicita aprobación del gerente general
3. Se envía notificación con detalles del ajuste solicitado
4. El proceso queda pendiente hasta recibir autorización

### Requisitos Especiales
- **Auditoría:** Todos los ajustes deben quedar completamente trazados
- **Autorización:** Ajustes significativos requieren múltiples aprobaciones
- **Integridad:** Debe mantener consistencia de datos en todo momento

---

## Matriz de Trazabilidad Casos de Uso vs Requisitos

| Caso de Uso | RF-001 | RF-002 | RF-003 | RF-004 | RF-005 | RNF-001 | RNF-002 | RNF-003 |
|-------------|--------|--------|--------|--------|--------|---------|---------|---------|
| CU-001 | ✓ | ✓ | ✓ | - | - | ✓ | ✓ | ✓ |
| CU-002 | ✓ | ✓ | ✓ | - | - | ✓ | ✓ | - |
| CU-003 | ✓ | - | ✓ | - | ✓ | ✓ | ✓ | - |
| CU-004 | ✓ | ✓ | - | ✓ | - | - | ✓ | ✓ |
| CU-005 | ✓ | ✓ | ✓ | - | - | ✓ | ✓ | ✓ |

## Priorización de Casos de Uso

### Alta Prioridad (MVP)
- CU-001: Registrar Entrada de Mercancía
- CU-002: Consultar Stock Disponible

### Media Prioridad (Versión 1.1)
- CU-005: Realizar Ajuste de Inventario
- CU-004: Configurar Alertas de Stock

### Baja Prioridad (Versión 1.2)
- CU-003: Generar Reporte de Inventario