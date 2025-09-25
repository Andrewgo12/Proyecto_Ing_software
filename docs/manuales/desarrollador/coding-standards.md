# Estándares de Codificación - Sistema de Inventario PYMES

## 📝 Guía de Estándares y Mejores Prácticas

**Versión:** 1.0  
**Fecha:** Enero 2024  
**Audiencia:** Equipo de desarrollo  

---

## 🎯 Principios Generales

### Principios SOLID
1. **Single Responsibility:** Una clase debe tener una sola razón para cambiar
2. **Open/Closed:** Abierto para extensión, cerrado para modificación
3. **Liskov Substitution:** Los objetos derivados deben ser sustituibles por sus bases
4. **Interface Segregation:** Muchas interfaces específicas son mejores que una general
5. **Dependency Inversion:** Depender de abstracciones, no de concreciones

### Clean Code
- **Nombres descriptivos:** Variables, funciones y clases con nombres claros
- **Funciones pequeñas:** Máximo 20 líneas por función
- **Comentarios mínimos:** El código debe ser autoexplicativo
- **DRY (Don't Repeat Yourself):** Evitar duplicación de código
- **KISS (Keep It Simple, Stupid):** Mantener simplicidad

---

## 🎨 Frontend (React/TypeScript)

### Estructura de Archivos
```
src/
├── components/
│   ├── common/           # Componentes reutilizables
│   ├── inventory/        # Componentes específicos de inventario
│   └── dashboard/        # Componentes del dashboard
├── pages/               # Páginas principales
├── hooks/               # Custom hooks
├── services/            # Servicios de API
├── utils/               # Utilidades
├── types/               # Definiciones de tipos
└── constants/           # Constantes de la aplicación
```

### Convenciones de Nomenclatura

#### Componentes React
```typescript
// ✅ Correcto - PascalCase
const ProductForm: React.FC<ProductFormProps> = ({ product, onSubmit }) => {
  return <form>...</form>;
};

// ❌ Incorrecto
const productForm = () => { ... };
const product_form = () => { ... };
```

#### Hooks Personalizados
```typescript
// ✅ Correcto - camelCase con prefijo 'use'
const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  return { user, login, logout };
};

// ✅ Correcto - Hook específico
const useInventoryData = (productId: string) => {
  // Lógica del hook
};
```

#### Variables y Funciones
```typescript
// ✅ Correcto - camelCase
const currentUser = getCurrentUser();
const isAuthenticated = checkAuthStatus();

// ✅ Correcto - Funciones descriptivas
const calculateTotalInventoryValue = (products: Product[]): number => {
  return products.reduce((total, product) => total + product.value, 0);
};

// ❌ Incorrecto
const usr = getUsr();
const calc = (prods) => { ... };
```

### Definición de Tipos TypeScript
```typescript
// ✅ Interfaces para objetos
interface Product {
  id: string;
  sku: string;
  name: string;
  price: number;
  category: Category;
  createdAt: Date;
  updatedAt: Date;
}

// ✅ Types para uniones y primitivos
type ProductStatus = 'active' | 'inactive' | 'discontinued';
type SortDirection = 'asc' | 'desc';

// ✅ Enums para constantes relacionadas
enum UserRole {
  ADMIN = 'admin',
  MANAGER = 'manager',
  WAREHOUSE = 'warehouse',
  SALES = 'sales',
  VIEWER = 'viewer'
}
```

### Estructura de Componentes
```typescript
// ✅ Estructura estándar de componente
interface ProductCardProps {
  product: Product;
  onEdit?: (product: Product) => void;
  onDelete?: (productId: string) => void;
  className?: string;
}

const ProductCard: React.FC<ProductCardProps> = ({
  product,
  onEdit,
  onDelete,
  className = ''
}) => {
  // 1. Hooks de estado
  const [isLoading, setIsLoading] = useState(false);
  
  // 2. Hooks personalizados
  const { user } = useAuth();
  
  // 3. Efectos
  useEffect(() => {
    // Lógica de efecto
  }, [product.id]);
  
  // 4. Funciones del componente
  const handleEdit = useCallback(() => {
    if (onEdit) {
      onEdit(product);
    }
  }, [product, onEdit]);
  
  // 5. Renderizado condicional temprano
  if (isLoading) {
    return <LoadingSpinner />;
  }
  
  // 6. Renderizado principal
  return (
    <div className={`product-card ${className}`}>
      <h3>{product.name}</h3>
      <p>SKU: {product.sku}</p>
      <p>Precio: ${product.price}</p>
      
      {user?.role === UserRole.ADMIN && (
        <div className="actions">
          <button onClick={handleEdit}>Editar</button>
          <button onClick={() => onDelete?.(product.id)}>Eliminar</button>
        </div>
      )}
    </div>
  );
};

export default ProductCard;
```

### Manejo de Estado
```typescript
// ✅ useState para estado local simple
const [isOpen, setIsOpen] = useState(false);
const [formData, setFormData] = useState<ProductFormData>({
  name: '',
  sku: '',
  price: 0
});

// ✅ useReducer para estado complejo
interface InventoryState {
  products: Product[];
  loading: boolean;
  error: string | null;
  filters: FilterState;
}

type InventoryAction = 
  | { type: 'FETCH_START' }
  | { type: 'FETCH_SUCCESS'; payload: Product[] }
  | { type: 'FETCH_ERROR'; payload: string }
  | { type: 'SET_FILTER'; payload: Partial<FilterState> };

const inventoryReducer = (state: InventoryState, action: InventoryAction): InventoryState => {
  switch (action.type) {
    case 'FETCH_START':
      return { ...state, loading: true, error: null };
    case 'FETCH_SUCCESS':
      return { ...state, loading: false, products: action.payload };
    case 'FETCH_ERROR':
      return { ...state, loading: false, error: action.payload };
    default:
      return state;
  }
};
```

### Servicios de API
```typescript
// ✅ Estructura de servicio API
class ProductService {
  private static readonly BASE_URL = '/api/products';
  
  static async getAll(params?: ProductQueryParams): Promise<ApiResponse<Product[]>> {
    try {
      const queryString = params ? new URLSearchParams(params).toString() : '';
      const url = queryString ? `${this.BASE_URL}?${queryString}` : this.BASE_URL;
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${getAuthToken()}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new ApiError(response.status, await response.text());
      }
      
      return await response.json();
    } catch (error) {
      console.error('Error fetching products:', error);
      throw error;
    }
  }
  
  static async create(product: CreateProductRequest): Promise<ApiResponse<Product>> {
    const response = await fetch(this.BASE_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${getAuthToken()}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(product)
    });
    
    if (!response.ok) {
      throw new ApiError(response.status, await response.text());
    }
    
    return await response.json();
  }
}
```

---

## 🔧 Backend (Node.js/TypeScript)

### Estructura de Archivos
```
src/
├── controllers/         # Controladores de rutas
├── services/           # Lógica de negocio
├── models/             # Modelos de datos
├── middleware/         # Middleware personalizado
├── routes/             # Definición de rutas
├── utils/              # Utilidades
├── types/              # Definiciones de tipos
└── config/             # Configuraciones
```

### Controladores
```typescript
// ✅ Estructura estándar de controlador
export class ProductController {
  constructor(
    private productService: ProductService,
    private logger: Logger
  ) {}
  
  public getProducts = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { page = 1, limit = 10, category, search } = req.query;
      
      const queryParams: ProductQueryParams = {
        page: Number(page),
        limit: Number(limit),
        category: category as string,
        search: search as string
      };
      
      const result = await this.productService.getProducts(queryParams);
      
      res.status(200).json({
        success: true,
        data: result.products,
        pagination: result.pagination
      });
    } catch (error) {
      this.logger.error('Error in getProducts:', error);
      next(error);
    }
  };
  
  public createProduct = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const productData: CreateProductRequest = req.body;
      const userId = req.user!.id;
      
      const product = await this.productService.createProduct(productData, userId);
      
      res.status(201).json({
        success: true,
        data: product,
        message: 'Producto creado exitosamente'
      });
    } catch (error) {
      this.logger.error('Error in createProduct:', error);
      next(error);
    }
  };
}
```

### Servicios
```typescript
// ✅ Estructura de servicio
export class ProductService {
  constructor(
    private productRepository: ProductRepository,
    private stockService: StockService,
    private auditService: AuditService,
    private logger: Logger
  ) {}
  
  public async createProduct(
    productData: CreateProductRequest,
    userId: string
  ): Promise<Product> {
    // 1. Validación
    await this.validateProductData(productData);
    
    // 2. Verificar SKU único
    const existingProduct = await this.productRepository.findBySku(productData.sku);
    if (existingProduct) {
      throw new ConflictError('SKU ya existe');
    }
    
    // 3. Transacción
    return await this.productRepository.transaction(async (trx) => {
      // Crear producto
      const product = await this.productRepository.create(productData, trx);
      
      // Crear niveles de stock iniciales
      await this.stockService.initializeStockLevels(product.id, trx);
      
      // Auditoría
      await this.auditService.logProductCreation(userId, product.id, trx);
      
      return product;
    });
  }
  
  private async validateProductData(data: CreateProductRequest): Promise<void> {
    const errors: ValidationError[] = [];
    
    if (!data.name?.trim()) {
      errors.push({ field: 'name', message: 'Nombre es requerido' });
    }
    
    if (!data.sku?.trim()) {
      errors.push({ field: 'sku', message: 'SKU es requerido' });
    }
    
    if (data.price <= 0) {
      errors.push({ field: 'price', message: 'Precio debe ser mayor a 0' });
    }
    
    if (errors.length > 0) {
      throw new ValidationError('Datos inválidos', errors);
    }
  }
}
```

### Modelos (Sequelize/TypeORM)
```typescript
// ✅ Modelo con Sequelize
@Table({
  tableName: 'products',
  timestamps: true,
  paranoid: true
})
export class Product extends Model<Product> {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id!: string;
  
  @AllowNull(false)
  @Unique
  @Column(DataType.STRING(50))
  sku!: string;
  
  @AllowNull(false)
  @Column(DataType.STRING(255))
  name!: string;
  
  @Column(DataType.TEXT)
  description?: string;
  
  @AllowNull(false)
  @Column(DataType.DECIMAL(10, 2))
  price!: number;
  
  @AllowNull(false)
  @Column(DataType.DECIMAL(10, 2))
  cost!: number;
  
  @ForeignKey(() => Category)
  @Column(DataType.UUID)
  categoryId!: string;
  
  @BelongsTo(() => Category)
  category!: Category;
  
  @HasMany(() => StockLevel)
  stockLevels!: StockLevel[];
  
  // Métodos de instancia
  public calculateMargin(): number {
    return ((this.price - this.cost) / this.price) * 100;
  }
  
  public isLowStock(locationId: string): boolean {
    const stockLevel = this.stockLevels.find(sl => sl.locationId === locationId);
    return stockLevel ? stockLevel.quantity <= stockLevel.minStock : false;
  }
}
```

### Middleware
```typescript
// ✅ Middleware de autenticación
export const authenticateToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
    
    if (!token) {
      throw new UnauthorizedError('Token de acceso requerido');
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
    const user = await User.findByPk(decoded.userId);
    
    if (!user || !user.isActive) {
      throw new UnauthorizedError('Usuario no válido');
    }
    
    req.user = user;
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      next(new UnauthorizedError('Token inválido'));
    } else {
      next(error);
    }
  }
};

// ✅ Middleware de autorización
export const requireRole = (roles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new UnauthorizedError('Usuario no autenticado');
    }
    
    if (!roles.includes(req.user.role)) {
      throw new ForbiddenError('Permisos insuficientes');
    }
    
    next();
  };
};
```

### Manejo de Errores
```typescript
// ✅ Clases de error personalizadas
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  
  constructor(message: string, statusCode: number, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  public readonly errors: ValidationErrorDetail[];
  
  constructor(message: string, errors: ValidationErrorDetail[]) {
    super(message, 400);
    this.errors = errors;
  }
}

// ✅ Middleware de manejo de errores
export const errorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  let statusCode = 500;
  let message = 'Error interno del servidor';
  let details: any = undefined;
  
  if (error instanceof AppError) {
    statusCode = error.statusCode;
    message = error.message;
    
    if (error instanceof ValidationError) {
      details = error.errors;
    }
  }
  
  // Log del error
  logger.error('Error:', {
    message: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    userId: req.user?.id
  });
  
  res.status(statusCode).json({
    success: false,
    message,
    ...(details && { errors: details }),
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
};
```

---

## 🗄️ Base de Datos

### Convenciones de Nomenclatura
```sql
-- ✅ Tablas en plural, snake_case
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ✅ Índices descriptivos
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category_active ON products(category_id, is_active);

-- ✅ Foreign keys descriptivas
ALTER TABLE products 
ADD CONSTRAINT fk_products_category 
FOREIGN KEY (category_id) REFERENCES categories(id);
```

### Migraciones
```sql
-- ✅ Estructura de migración
-- Migration: 002_create_products_table.sql
-- Description: Create products table with basic inventory fields
-- Author: Development Team
-- Date: 2024-01-15

BEGIN;

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  cost_price DECIMAL(10,2) NOT NULL CHECK (cost_price >= 0),
  category_id UUID NOT NULL,
  unit_of_measure VARCHAR(20) DEFAULT 'unidad',
  barcode VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  is_trackable BOOLEAN DEFAULT true,
  min_stock_level DECIMAL(10,2) DEFAULT 0,
  max_stock_level DECIMAL(10,2),
  reorder_point DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_products_category 
    FOREIGN KEY (category_id) REFERENCES categories(id),
  CONSTRAINT chk_products_stock_levels 
    CHECK (max_stock_level IS NULL OR max_stock_level >= min_stock_level)
);

-- Índices para rendimiento
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;

-- Trigger para updated_at
CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMIT;
```

---

## 🧪 Testing

### Estructura de Tests
```
tests/
├── unit/
│   ├── services/
│   ├── controllers/
│   └── utils/
├── integration/
│   ├── api/
│   └── database/
└── e2e/
    └── scenarios/
```

### Tests Unitarios
```typescript
// ✅ Test de servicio
describe('ProductService', () => {
  let productService: ProductService;
  let mockProductRepository: jest.Mocked<ProductRepository>;
  let mockStockService: jest.Mocked<StockService>;
  
  beforeEach(() => {
    mockProductRepository = createMockProductRepository();
    mockStockService = createMockStockService();
    productService = new ProductService(
      mockProductRepository,
      mockStockService,
      mockAuditService,
      mockLogger
    );
  });
  
  describe('createProduct', () => {
    it('should create product successfully with valid data', async () => {
      // Arrange
      const productData: CreateProductRequest = {
        sku: 'TEST-001',
        name: 'Test Product',
        price: 100,
        cost: 50,
        categoryId: 'category-id'
      };
      
      const expectedProduct: Product = {
        id: 'product-id',
        ...productData,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      mockProductRepository.findBySku.mockResolvedValue(null);
      mockProductRepository.create.mockResolvedValue(expectedProduct);
      
      // Act
      const result = await productService.createProduct(productData, 'user-id');
      
      // Assert
      expect(result).toEqual(expectedProduct);
      expect(mockProductRepository.findBySku).toHaveBeenCalledWith('TEST-001');
      expect(mockProductRepository.create).toHaveBeenCalledWith(productData);
      expect(mockStockService.initializeStockLevels).toHaveBeenCalledWith('product-id');
    });
    
    it('should throw ConflictError when SKU already exists', async () => {
      // Arrange
      const productData: CreateProductRequest = {
        sku: 'EXISTING-001',
        name: 'Test Product',
        price: 100,
        cost: 50,
        categoryId: 'category-id'
      };
      
      mockProductRepository.findBySku.mockResolvedValue({} as Product);
      
      // Act & Assert
      await expect(
        productService.createProduct(productData, 'user-id')
      ).rejects.toThrow(ConflictError);
    });
  });
});
```

### Tests de Integración
```typescript
// ✅ Test de API
describe('Products API', () => {
  let app: Express;
  let testDb: TestDatabase;
  
  beforeAll(async () => {
    testDb = await setupTestDatabase();
    app = createTestApp(testDb);
  });
  
  afterAll(async () => {
    await testDb.cleanup();
  });
  
  beforeEach(async () => {
    await testDb.seed();
  });
  
  describe('POST /api/products', () => {
    it('should create product with valid data', async () => {
      const productData = {
        sku: 'TEST-001',
        name: 'Test Product',
        price: 100,
        cost: 50,
        categoryId: 'valid-category-id'
      };
      
      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${getValidToken()}`)
        .send(productData)
        .expect(201);
      
      expect(response.body).toMatchObject({
        success: true,
        data: expect.objectContaining({
          sku: 'TEST-001',
          name: 'Test Product'
        })
      });
    });
  });
});
```

---

## 📏 Métricas de Calidad

### Cobertura de Código
```yaml
Objetivos de Cobertura:
  - Líneas: > 85%
  - Funciones: > 90%
  - Ramas: > 80%
  - Statements: > 85%

Exclusiones:
  - Archivos de configuración
  - Tipos y interfaces
  - Archivos de test
  - Scripts de migración
```

### Complejidad Ciclomática
```yaml
Límites:
  - Funciones: < 10
  - Clases: < 15
  - Archivos: < 20

Herramientas:
  - ESLint: complexity rule
  - SonarQube: cognitive complexity
  - CodeClimate: maintainability
```

---

## 🔧 Herramientas de Desarrollo

### Configuración ESLint
```json
{
  "extends": [
    "@typescript-eslint/recommended",
    "prettier"
  ],
  "rules": {
    "complexity": ["error", 10],
    "max-lines-per-function": ["error", 50],
    "max-params": ["error", 4],
    "no-console": "warn",
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn"
  }
}
```

### Configuración Prettier
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false
}
```

### Pre-commit Hooks
```json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  },
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "git add"
    ]
  }
}
```

---

## ✅ Checklist de Revisión de Código

### Funcionalidad
- [ ] El código cumple con los requisitos
- [ ] Los casos edge están manejados
- [ ] No hay lógica duplicada
- [ ] Las validaciones son apropiadas

### Legibilidad
- [ ] Nombres descriptivos y consistentes
- [ ] Funciones pequeñas y enfocadas
- [ ] Comentarios solo donde es necesario
- [ ] Estructura clara y lógica

### Rendimiento
- [ ] No hay operaciones innecesarias
- [ ] Consultas de BD optimizadas
- [ ] Manejo eficiente de memoria
- [ ] Lazy loading donde aplique

### Seguridad
- [ ] Input validation implementada
- [ ] No hay datos sensibles expuestos
- [ ] Autenticación y autorización correctas
- [ ] Sanitización de datos

### Testing
- [ ] Tests unitarios incluidos
- [ ] Cobertura de código adecuada
- [ ] Tests de casos edge
- [ ] Mocks apropiados

---

**Estándares de Codificación v1.0 - Enero 2024**

*Estos estándares deben ser seguidos por todo el equipo de desarrollo y revisados regularmente.*