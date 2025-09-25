# Guía de Contribución

¡Gracias por tu interés en contribuir al Sistema de Inventario PYMES! Esta guía te ayudará a empezar.

## 🚀 Cómo Contribuir

### 1. Fork y Clone
```bash
git clone https://github.com/tu-usuario/Sistema-Inventario-PYMES.git
cd Sistema-Inventario-PYMES
```

### 2. Configurar Entorno
```bash
# Backend
cd src/backend
npm install
cp .env.example .env

# Frontend
cd ../frontend
npm install

# Mobile
cd ../mobile
npm install
```

### 3. Crear Branch
```bash
git checkout -b feature/nueva-funcionalidad
```

## 📝 Estándares de Código

### JavaScript/Node.js
- Usar ES6+ features
- Seguir ESLint configuration
- Documentar funciones complejas
- Tests unitarios obligatorios

### React/React Native
- Componentes funcionales con hooks
- PropTypes para validación
- Nombres descriptivos para componentes
- Tests con React Testing Library

### Base de Datos
- Migraciones para cambios de schema
- Seeds para datos de prueba
- Índices para queries frecuentes

## 🧪 Testing

### Ejecutar Tests
```bash
# Tests unitarios
npm test

# Tests de integración
npm run test:integration

# Tests E2E
npm run test:e2e

# Cobertura
npm run test:coverage
```

### Requisitos de Testing
- Cobertura mínima: 80%
- Tests unitarios para lógica de negocio
- Tests de integración para APIs
- Tests E2E para flujos críticos

## 📋 Pull Request Process

### 1. Checklist Pre-PR
- [ ] Tests pasan
- [ ] Código linted
- [ ] Documentación actualizada
- [ ] Changelog actualizado

### 2. Descripción del PR
```markdown
## Descripción
Breve descripción de los cambios

## Tipo de Cambio
- [ ] Bug fix
- [ ] Nueva funcionalidad
- [ ] Breaking change
- [ ] Documentación

## Testing
- [ ] Tests unitarios
- [ ] Tests de integración
- [ ] Tests manuales

## Screenshots (si aplica)
```

### 3. Review Process
- Al menos 1 reviewer requerido
- Todos los checks deben pasar
- Resolver comentarios antes de merge

## 🐛 Reportar Bugs

### Template de Issue
```markdown
**Descripción del Bug**
Descripción clara del problema

**Pasos para Reproducir**
1. Ir a '...'
2. Hacer click en '....'
3. Ver error

**Comportamiento Esperado**
Lo que debería pasar

**Screenshots**
Si aplica, agregar screenshots

**Entorno**
- OS: [e.g. Windows 10]
- Browser: [e.g. Chrome 91]
- Version: [e.g. 1.0.0]
```

## 💡 Sugerir Funcionalidades

### Template de Feature Request
```markdown
**Problema a Resolver**
Descripción del problema actual

**Solución Propuesta**
Descripción de la funcionalidad

**Alternativas Consideradas**
Otras opciones evaluadas

**Contexto Adicional**
Screenshots, mockups, etc.
```

## 📚 Documentación

### Actualizar Docs
- README.md para cambios generales
- API docs para nuevos endpoints
- Manuales de usuario para nuevas features
- Comentarios en código complejo

## 🏷️ Versionado

Seguimos [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: Nuevas funcionalidades
- **PATCH**: Bug fixes

## 📞 Contacto

- **Email**: dev@inventariopymes.com
- **Discord**: [Servidor del Proyecto]
- **Issues**: GitHub Issues

## 🙏 Reconocimientos

Todos los contribuidores serán reconocidos en:
- README.md
- Changelog
- Página de créditos

¡Gracias por contribuir! 🎉