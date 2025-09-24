# 🔐 Especificación de Autenticación JWT
## Sistema de Inventario PYMES

---

## 📋 Información General

**Método de Autenticación:** JSON Web Tokens (JWT)  
**Algoritmo:** HS256 (HMAC with SHA-256)  
**Duración Access Token:** 1 hora (3600 segundos)  
**Duración Refresh Token:** 30 días (2592000 segundos)  
**Header Name:** `Authorization`  
**Header Format:** `Bearer {token}`  

---

## 🔑 Flujo de Autenticación

### 1. Login Inicial

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as API
    participant D as Database
    
    C->>A: POST /auth/login {email, password}
    A->>D: Validar credenciales
    D-->>A: Usuario válido
    A->>A: Generar JWT tokens
    A-->>C: {accessToken, refreshToken, user}
```

**Request:**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@empresa.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjNlNDU2Ny1lODliLTEyZDMtYTQ1Ni00MjY2MTQxNzQwMDAiLCJlbWFpbCI6ImFkbWluQGVtcHJlc2EuY29tIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNjQyMjYyNDAwLCJleHAiOjE2NDIyNjYwMDB9.signature",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjNlNDU2Ny1lODliLTEyZDMtYTQ1Ni00MjY2MTQxNzQwMDAiLCJ0eXBlIjoicmVmcmVzaCIsImlhdCI6MTY0MjI2MjQwMCwiZXhwIjoxNjQ0ODU0NDAwfQ.signature",
  "expiresIn": 3600,
  "tokenType": "Bearer",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "admin@empresa.com",
    "firstName": "Juan",
    "lastName": "Pérez",
    "role": "admin",
    "permissions": ["inventory:read", "inventory:write", "products:read", "products:write", "reports:read", "users:read", "users:write"],
    "lastLogin": "2024-01-15T10:30:00Z"
  }
}
```

### 2. Uso del Access Token

```http
GET /api/v1/products
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Accept: application/json
```

### 3. Renovación de Token

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as API
    participant R as Redis
    
    C->>A: POST /auth/refresh {refreshToken}
    A->>R: Validar refresh token
    R-->>A: Token válido
    A->>A: Generar nuevo access token
    A-->>C: {accessToken, expiresIn}
```

**Request:**
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "tokenType": "Bearer"
}
```

---

## 🎫 Estructura del JWT Token

### Access Token Payload

```json
{
  "sub": "123e4567-e89b-12d3-a456-426614174000",
  "email": "admin@empresa.com",
  "firstName": "Juan",
  "lastName": "Pérez",
  "role": "admin",
  "permissions": [
    "inventory:read",
    "inventory:write",
    "products:read",
    "products:write",
    "reports:read",
    "users:read",
    "users:write"
  ],
  "iat": 1642262400,
  "exp": 1642266000,
  "iss": "inventario-pymes-api",
  "aud": "inventario-pymes-client"
}
```

### Refresh Token Payload

```json
{
  "sub": "123e4567-e89b-12d3-a456-426614174000",
  "type": "refresh",
  "iat": 1642262400,
  "exp": 1644854400,
  "iss": "inventario-pymes-api",
  "jti": "refresh-token-unique-id"
}
```

### Claims Explicados

| Claim | Descripción | Tipo | Ejemplo |
|-------|-------------|------|---------|
| `sub` | Subject - ID del usuario | string | "123e4567-e89b-12d3-a456-426614174000" |
| `email` | Email del usuario | string | "admin@empresa.com" |
| `role` | Rol principal del usuario | string | "admin" |
| `permissions` | Lista de permisos específicos | array | ["inventory:read", "inventory:write"] |
| `iat` | Issued At - Timestamp de creación | number | 1642262400 |
| `exp` | Expiration - Timestamp de expiración | number | 1642266000 |
| `iss` | Issuer - Emisor del token | string | "inventario-pymes-api" |
| `aud` | Audience - Audiencia del token | string | "inventario-pymes-client" |
| `jti` | JWT ID - Identificador único | string | "refresh-token-unique-id" |

---

## 👥 Roles y Permisos

### Jerarquía de Roles

```
admin
├── manager
│   ├── warehouse
│   └── sales
└── viewer
```

### Definición de Roles

#### 🔴 Admin (Administrador)
**Descripción:** Acceso completo al sistema  
**Permisos:**
- `*` (todos los permisos)
- Gestión de usuarios
- Configuración del sistema
- Acceso a todos los módulos

#### 🟡 Manager (Gerente)
**Descripción:** Gestión operacional y reportes  
**Permisos:**
```json
[
  "inventory:read",
  "inventory:write",
  "products:read",
  "products:write",
  "reports:read",
  "alerts:read",
  "suppliers:read",
  "suppliers:write"
]
```

#### 🟢 Warehouse (Auxiliar de Bodega)
**Descripción:** Operaciones de inventario  
**Permisos:**
```json
[
  "inventory:read",
  "inventory:write",
  "products:read",
  "movements:create",
  "stock:read",
  "stock:update"
]
```

#### 🔵 Sales (Vendedor)
**Descripción:** Consultas de inventario y ventas  
**Permisos:**
```json
[
  "inventory:read",
  "products:read",
  "stock:read",
  "reservations:create",
  "customers:read",
  "customers:write"
]
```

#### ⚪ Viewer (Solo Lectura)
**Descripción:** Solo consultas básicas  
**Permisos:**
```json
[
  "inventory:read",
  "products:read",
  "stock:read"
]
```

### Formato de Permisos

**Estructura:** `{resource}:{action}`

**Recursos:**
- `inventory` - Gestión de inventario
- `products` - Catálogo de productos
- `reports` - Reportes y analytics
- `users` - Gestión de usuarios
- `alerts` - Alertas del sistema
- `suppliers` - Gestión de proveedores
- `customers` - Gestión de clientes
- `settings` - Configuración del sistema

**Acciones:**
- `read` - Consultar/Leer
- `write` - Crear/Actualizar
- `delete` - Eliminar
- `admin` - Administrar completamente

---

## 🛡️ Validación de Tokens

### Middleware de Autenticación

```javascript
// Pseudocódigo del middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Token de acceso requerido',
      code: 'MISSING_TOKEN'
    });
  }
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'Token expirado',
          code: 'TOKEN_EXPIRED'
        });
      }
      
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Token inválido',
        code: 'INVALID_TOKEN'
      });
    }
    
    req.user = user;
    next();
  });
}
```

### Validación de Permisos

```javascript
function requirePermission(permission) {
  return (req, res, next) => {
    const userPermissions = req.user.permissions || [];
    
    // Admin tiene todos los permisos
    if (req.user.role === 'admin') {
      return next();
    }
    
    // Verificar permiso específico
    if (!userPermissions.includes(permission)) {
      return res.status(403).json({
        error: 'Forbidden',
        message: `Permiso requerido: ${permission}`,
        code: 'INSUFFICIENT_PERMISSIONS'
      });
    }
    
    next();
  };
}

// Uso en rutas
app.get('/api/v1/products', 
  authenticateToken, 
  requirePermission('products:read'), 
  getProducts
);
```

---

## 🔄 Gestión de Sesiones

### Almacenamiento de Refresh Tokens

**Redis Storage:**
```redis
# Key: refresh_token:{userId}:{tokenId}
# Value: {token_data}
# TTL: 30 días

SET refresh_token:123e4567:abc123 '{"userId":"123e4567","deviceInfo":"Chrome/Windows","createdAt":"2024-01-15T10:30:00Z"}' EX 2592000
```

### Revocación de Tokens

#### Logout Individual
```http
POST /api/v1/auth/logout
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout de Todas las Sesiones
```http
POST /api/v1/auth/logout-all
Authorization: Bearer {accessToken}
```

### Blacklist de Tokens

```redis
# Blacklist para access tokens comprometidos
SET blacklist_token:abc123 "revoked" EX 3600

# Verificación en middleware
if (redis.exists(`blacklist_token:${tokenId}`)) {
  return res.status(401).json({
    error: 'Unauthorized',
    message: 'Token revocado',
    code: 'TOKEN_REVOKED'
  });
}
```

---

## 🚨 Manejo de Errores de Autenticación

### Códigos de Error

| Código | HTTP Status | Descripción |
|--------|-------------|-------------|
| `MISSING_TOKEN` | 401 | Token no proporcionado |
| `INVALID_TOKEN` | 403 | Token malformado o inválido |
| `TOKEN_EXPIRED` | 401 | Token expirado |
| `TOKEN_REVOKED` | 401 | Token revocado |
| `INSUFFICIENT_PERMISSIONS` | 403 | Sin permisos suficientes |
| `INVALID_CREDENTIALS` | 401 | Credenciales incorrectas |
| `ACCOUNT_LOCKED` | 423 | Cuenta bloqueada |
| `ACCOUNT_DISABLED` | 403 | Cuenta deshabilitada |

### Respuestas de Error

```json
{
  "error": "Unauthorized",
  "message": "Token expirado",
  "code": "TOKEN_EXPIRED",
  "timestamp": "2024-01-15T16:30:00Z",
  "path": "/api/v1/products",
  "suggestion": "Renueve su token usando el endpoint /auth/refresh"
}
```

---

## 🔒 Seguridad Adicional

### Rate Limiting por Autenticación

```yaml
# Límites específicos para endpoints de auth
/auth/login:
  - 5 intentos por minuto por IP
  - 10 intentos por hora por email
  
/auth/refresh:
  - 20 intentos por minuto por usuario
  
/auth/logout:
  - 100 intentos por minuto por usuario
```

### Detección de Anomalías

**Indicadores de Riesgo:**
- Login desde nueva ubicación geográfica
- Múltiples intentos de login fallidos
- Uso simultáneo de tokens desde diferentes IPs
- Patrones de uso inusuales

**Respuesta Automática:**
```json
{
  "error": "Security Alert",
  "message": "Actividad sospechosa detectada",
  "code": "SUSPICIOUS_ACTIVITY",
  "actions": [
    "Token revocado automáticamente",
    "Notificación enviada al usuario",
    "Requiere verificación adicional"
  ]
}
```

### Headers de Seguridad

```http
# Request headers recomendados
Authorization: Bearer {token}
X-Client-Version: 1.0.0
X-Device-ID: unique-device-identifier
User-Agent: InventoryApp/1.0.0

# Response headers de seguridad
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

---

## 📱 Implementación en Cliente

### JavaScript/TypeScript

```typescript
class AuthService {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  
  async login(email: string, password: string): Promise<AuthResponse> {
    const response = await fetch('/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });
    
    if (!response.ok) {
      throw new Error('Login failed');
    }
    
    const data = await response.json();
    this.setTokens(data.accessToken, data.refreshToken);
    return data;
  }
  
  async refreshAccessToken(): Promise<string> {
    if (!this.refreshToken) {
      throw new Error('No refresh token available');
    }
    
    const response = await fetch('/api/v1/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ refreshToken: this.refreshToken }),
    });
    
    if (!response.ok) {
      this.clearTokens();
      throw new Error('Token refresh failed');
    }
    
    const data = await response.json();
    this.accessToken = data.accessToken;
    return data.accessToken;
  }
  
  getAuthHeaders(): Record<string, string> {
    if (!this.accessToken) {
      throw new Error('No access token available');
    }
    
    return {
      'Authorization': `Bearer ${this.accessToken}`,
    };
  }
  
  private setTokens(accessToken: string, refreshToken: string): void {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    
    // Almacenar en localStorage/sessionStorage según necesidad
    localStorage.setItem('accessToken', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
  }
  
  private clearTokens(): void {
    this.accessToken = null;
    this.refreshToken = null;
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
  }
}
```

### Interceptor para Renovación Automática

```typescript
// Axios interceptor example
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const newToken = await authService.refreshAccessToken();
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return axios(originalRequest);
      } catch (refreshError) {
        // Redirect to login
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);
```

---

## 🧪 Testing de Autenticación

### Test Cases

```javascript
describe('Authentication', () => {
  test('should login with valid credentials', async () => {
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@empresa.com',
        password: 'password123'
      })
      .expect(200);
      
    expect(response.body).toHaveProperty('accessToken');
    expect(response.body).toHaveProperty('refreshToken');
    expect(response.body.user.email).toBe('admin@empresa.com');
  });
  
  test('should reject invalid credentials', async () => {
    await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@empresa.com',
        password: 'wrongpassword'
      })
      .expect(401);
  });
  
  test('should refresh token successfully', async () => {
    const loginResponse = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@empresa.com',
        password: 'password123'
      });
      
    const refreshResponse = await request(app)
      .post('/api/v1/auth/refresh')
      .send({
        refreshToken: loginResponse.body.refreshToken
      })
      .expect(200);
      
    expect(refreshResponse.body).toHaveProperty('accessToken');
  });
  
  test('should protect endpoints with authentication', async () => {
    await request(app)
      .get('/api/v1/products')
      .expect(401);
  });
  
  test('should allow access with valid token', async () => {
    const loginResponse = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@empresa.com',
        password: 'password123'
      });
      
    await request(app)
      .get('/api/v1/products')
      .set('Authorization', `Bearer ${loginResponse.body.accessToken}`)
      .expect(200);
  });
});
```

---

**Última actualización:** Enero 2024  
**Versión:** 1.0.0  
**Próxima revisión:** Marzo 2024