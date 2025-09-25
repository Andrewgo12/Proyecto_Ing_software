# Gestión de Usuarios - Sistema de Inventario PYMES

## 👥 Administración de Usuarios

### Roles Disponibles
- **ADMIN:** Acceso completo
- **MANAGER:** Gestión operativa
- **WAREHOUSE:** Movimientos de inventario
- **SALES:** Consultas y ventas
- **VIEWER:** Solo lectura

### Crear Usuario
```
Panel Admin → Usuarios → Nuevo
1. Email (único)
2. Nombre completo
3. Rol asignado
4. Ubicaciones permitidas
5. Estado: Activo
6. Enviar invitación
```

### Gestionar Permisos
```
Por Módulo:
- Productos: Crear/Editar/Eliminar/Ver
- Inventario: Movimientos/Ajustes/Consultas
- Reportes: Generar/Exportar/Programar
- Configuración: Solo Admin

Por Ubicación:
- Asignar ubicaciones específicas
- Restringir transferencias
- Limitar consultas de stock
```

### Desactivar Usuario
```
1. Ir a lista de usuarios
2. Seleccionar usuario
3. Cambiar estado a "Inactivo"
4. Confirmar acción
5. Usuario pierde acceso inmediatamente
```

### Resetear Contraseña
```
1. Seleccionar usuario
2. Clic en "Resetear Contraseña"
3. Se envía email con nueva contraseña temporal
4. Usuario debe cambiarla en primer login
```

### Auditoría de Usuarios
```
Configuración → Auditoría
- Últimos logins
- Acciones realizadas
- Intentos fallidos
- Cambios de permisos
- Exportar logs
```

### Políticas de Seguridad
```
Configuración → Seguridad
- Contraseñas: 8 caracteres mínimo
- Expiración: 90 días
- Intentos fallidos: 5 máximo
- Sesión: 8 horas máximo
- MFA: Obligatorio para Admin
```