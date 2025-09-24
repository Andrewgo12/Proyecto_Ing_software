# Historias de Usuario - Sistema de Inventario PYMES

## Epic 1: Gestión de Inventario

### US-001: Registrar Entrada de Productos
**Como** auxiliar de bodega  
**Quiero** registrar la entrada de productos al inventario  
**Para** mantener el stock actualizado y tener trazabilidad

**Criterios de Aceptación:**
```gherkin
DADO que soy un auxiliar de bodega autenticado
CUANDO registro una entrada de productos
ENTONCES el sistema debe actualizar el stock automáticamente
Y generar un comprobante con fecha, hora y usuario

DADO que estoy registrando una entrada
CUANDO escaneo un código de barras
ENTONCES el sistema debe identificar el producto automáticamente
Y mostrar su información básica

DADO que he completado el registro de entrada
CUANDO confirmo la transacción
ENTONCES el sistema debe enviar notificación al gerente
Y actualizar los reportes en tiempo real
```
**Story Points:** 8  
**Prioridad:** Alta  
**Sprint:** 1

---

### US-002: Consultar Stock Disponible
**Como** vendedor  
**Quiero** consultar el stock disponible de productos  
**Para** confirmar disponibilidad a los clientes

**Criterios de Aceptación:**
```gherkin
DADO que soy un vendedor autenticado
CUANDO busco un producto por nombre o código
ENTONCES el sistema debe mostrar el stock actual
Y la ubicación donde se encuentra

DADO que consulto el stock de un producto
CUANDO el stock está bajo el mínimo configurado
ENTONCES el sistema debe mostrar una alerta visual
Y sugerir productos alternativos si existen

DADO que necesito reservar productos para una venta
CUANDO selecciono la cantidad a reservar
ENTONCES el sistema debe actualizar el stock disponible
Y mantener la reserva por 24 horas
```
**Story Points:** 5  
**Prioridad:** Alta  
**Sprint:** 1

---

### US-003: Recibir Alertas de Stock Bajo
**Como** gerente de inventario  
**Quiero** recibir alertas automáticas cuando el stock esté bajo  
**Para** realizar pedidos oportunos y evitar quiebres

**Criterios de Aceptación:**
```gherkin
DADO que soy gerente con productos configurados con stock mínimo
CUANDO un producto alcanza el nivel mínimo
ENTONCES el sistema debe enviar notificación por email
Y mostrar alerta en el dashboard

DADO que recibo una alerta de stock bajo
CUANDO accedo al sistema
ENTONCES debo ver un resumen de todos los productos en alerta
Y poder generar orden de compra directamente

DADO que un producto ha estado en alerta por más de 7 días
CUANDO no se ha tomado acción
ENTONCES el sistema debe escalar la alerta al nivel superior
Y registrar el evento en el log de auditoría
```
**Story Points:** 13  
**Prioridad:** Media  
**Sprint:** 2

---

## Epic 2: Gestión de Productos

### US-004: Crear Nuevo Producto
**Como** administrador del sistema  
**Quiero** crear nuevos productos en el catálogo  
**Para** mantener actualizada la información de inventario

**Criterios de Aceptación:**
```gherkin
DADO que soy administrador autenticado
CUANDO creo un nuevo producto
ENTONCES debo ingresar nombre, SKU, categoría y precio mínimo
Y el sistema debe validar que el SKU sea único

DADO que estoy creando un producto
CUANDO subo una imagen del producto
ENTONCES el sistema debe redimensionar automáticamente
Y almacenar en múltiples tamaños (thumbnail, medium, large)

DADO que he creado un producto exitosamente
CUANDO guardo la información
ENTONCES el sistema debe generar código de barras automáticamente
Y estar disponible inmediatamente para transacciones
```
**Story Points:** 8  
**Prioridad:** Alta  
**Sprint:** 1

---

### US-005: Categorizar Productos
**Como** administrador del sistema  
**Quiero** organizar productos en categorías jerárquicas  
**Para** facilitar la búsqueda y organización

**Criterios de Aceptación:**
```gherkin
DADO que soy administrador autenticado
CUANDO creo una nueva categoría
ENTONCES puedo asignarla como subcategoría de otra existente
Y definir hasta 3 niveles de jerarquía

DADO que tengo productos sin categorizar
CUANDO asigno productos a categorías masivamente
ENTONCES el sistema debe procesar la asignación en lotes
Y mostrar progreso de la operación

DADO que elimino una categoría
CUANDO tiene productos asignados
ENTONCES el sistema debe solicitar reasignación
Y no permitir eliminación hasta completar el proceso
```
**Story Points:** 5  
**Prioridad:** Media  
**Sprint:** 2

---

## Epic 3: Reportes y Analytics

### US-006: Generar Reporte de Stock Actual
**Como** gerente  
**Quiero** generar reportes del stock actual  
**Para** tomar decisiones informadas sobre inventario

**Criterios de Aceptación:**
```gherkin
DADO que soy gerente autenticado
CUANDO genero reporte de stock actual
ENTONCES el sistema debe mostrar todos los productos con cantidades
Y permitir filtrar por categoría, ubicación o rango de fechas

DADO que estoy viendo el reporte de stock
CUANDO selecciono exportar
ENTONCES el sistema debe generar archivo Excel
Y enviarlo por email en menos de 30 segundos

DADO que el reporte contiene más de 1000 productos
CUANDO se genera el reporte
ENTONCES el sistema debe paginar los resultados
Y permitir navegación eficiente
```
**Story Points:** 8  
**Prioridad:** Media  
**Sprint:** 3

---

### US-007: Dashboard Ejecutivo
**Como** gerente general  
**Quiero** ver un dashboard con métricas clave  
**Para** monitorear el desempeño del inventario

**Criterios de Aceptación:**
```gherkin
DADO que soy gerente general autenticado
CUANDO accedo al dashboard
ENTONCES debo ver KPIs principales: valor total inventario, productos en alerta, rotación
Y gráficos de tendencias de los últimos 30 días

DADO que estoy viendo el dashboard
CUANDO selecciono un período específico
ENTONCES los gráficos deben actualizarse automáticamente
Y mostrar comparación con período anterior

DADO que hay cambios significativos en métricas
CUANDO accedo al dashboard
ENTONCES el sistema debe resaltar los cambios
Y proporcionar drill-down para análisis detallado
```
**Story Points:** 13  
**Prioridad:** Baja  
**Sprint:** 4

---

## Epic 4: Movilidad y Accesibilidad

### US-008: App Móvil para Consultas
**Como** vendedor de campo  
**Quiero** consultar inventario desde mi móvil  
**Para** atender clientes sin estar en la oficina

**Criterios de Aceptación:**
```gherkin
DADO que soy vendedor con app móvil instalada
CUANDO consulto stock de un producto
ENTONCES la información debe sincronizarse en tiempo real
Y funcionar con conexión intermitente

DADO que estoy usando la app móvil
CUANDO escaneo código de barras con la cámara
ENTONCES el sistema debe reconocer el producto
Y mostrar información completa en menos de 3 segundos

DADO que pierdo conexión a internet
CUANDO consulto productos previamente cargados
ENTONCES la app debe funcionar offline
Y sincronizar cambios cuando recupere conexión
```
**Story Points:** 21  
**Prioridad:** Baja  
**Sprint:** 5

---

### US-009: Escaneo de Códigos de Barras
**Como** auxiliar de bodega  
**Quiero** usar códigos de barras para agilizar procesos  
**Para** reducir errores y tiempo de captura

**Criterios de Aceptación:**
```gherkin
DADO que tengo acceso a cámara web o móvil
CUANDO escaneo código de barras de un producto
ENTONCES el sistema debe identificarlo automáticamente
Y cargar su información en el formulario activo

DADO que escaneo un código no registrado
CUANDO el producto no existe en el sistema
ENTONCES debo poder crear el producto usando el código
Y el sistema debe sugerir información basada en bases de datos públicas

DADO que estoy procesando múltiples productos
CUANDO escaneo códigos consecutivamente
ENTONCES el sistema debe procesar cada uno
Y mantener lista de productos escaneados para revisión
```
**Story Points:** 13  
**Prioridad:** Media  
**Sprint:** 3

---

## Epic 5: Integración y Configuración

### US-010: Configurar Parámetros del Sistema
**Como** administrador  
**Quiero** configurar parámetros operacionales  
**Para** adaptar el sistema a las necesidades específicas

**Criterios de Aceptación:**
```gherkin
DADO que soy administrador del sistema
CUANDO configuro parámetros generales
ENTONCES puedo definir moneda, zona horaria, idioma
Y unidades de medida predeterminadas

DADO que configuro alertas de stock
CUANDO defino umbrales por categoría
ENTONCES el sistema debe aplicar reglas automáticamente
Y permitir excepciones por producto específico

DADO que modifico configuraciones críticas
CUANDO guardo los cambios
ENTONCES el sistema debe solicitar confirmación
Y registrar el cambio en log de auditoría
```
**Story Points:** 8  
**Prioridad:** Media  
**Sprint:** 2

---

## Resumen de Épicas y Story Points

| Épica | Historias | Story Points | Prioridad |
|-------|-----------|--------------|-----------|
| Gestión de Inventario | 3 | 26 | Alta |
| Gestión de Productos | 2 | 13 | Alta/Media |
| Reportes y Analytics | 2 | 21 | Media/Baja |
| Movilidad y Accesibilidad | 2 | 34 | Media/Baja |
| Integración y Configuración | 1 | 8 | Media |
| **TOTAL** | **10** | **102** | - |

## Criterios de Priorización (MoSCoW)

### Must Have (Sprint 1-2)
- US-001: Registrar Entrada de Productos
- US-002: Consultar Stock Disponible  
- US-004: Crear Nuevo Producto

### Should Have (Sprint 2-3)
- US-003: Recibir Alertas de Stock Bajo
- US-005: Categorizar Productos
- US-009: Escaneo de Códigos de Barras
- US-010: Configurar Parámetros

### Could Have (Sprint 3-4)
- US-006: Generar Reporte de Stock Actual

### Won't Have (Futuras versiones)
- US-007: Dashboard Ejecutivo
- US-008: App Móvil para Consultas

## Definition of Done

Para que una historia de usuario se considere completada debe cumplir:

✅ **Desarrollo:**
- Código implementado según criterios de aceptación
- Unit tests con cobertura mínima 80%
- Code review aprobado por tech lead

✅ **Testing:**
- Pruebas funcionales ejecutadas exitosamente
- Pruebas de integración pasando
- Testing manual por QA completado

✅ **Documentación:**
- API documentada en Swagger
- Manual de usuario actualizado
- Casos de prueba documentados

✅ **Despliegue:**
- Deployado en ambiente de staging
- Validado por Product Owner
- Listo para producción