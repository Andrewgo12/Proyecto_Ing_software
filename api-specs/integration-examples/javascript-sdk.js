/**
 * JavaScript SDK para Sistema de Inventario PYMES
 * Versión: 1.0.0
 * 
 * Uso:
 * const InventoryAPI = require('./javascript-sdk');
 * const client = new InventoryAPI({ apiKey: 'your-api-key' });
 */

class InventoryAPI {
  constructor(options = {}) {
    this.baseURL = options.baseURL || 'https://api.inventario-pymes.com/v1';
    this.apiKey = options.apiKey;
    this.accessToken = options.accessToken;
    this.refreshToken = options.refreshToken;
    this.timeout = options.timeout || 30000;
    this.retryAttempts = options.retryAttempts || 3;
    this.retryDelay = options.retryDelay || 1000;
  }

  // ==================== UTILIDADES ====================

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const config = {
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'InventoryAPI-JS-SDK/1.0.0',
        ...options.headers
      },
      ...options
    };

    // Agregar autenticación
    if (this.accessToken) {
      config.headers.Authorization = `Bearer ${this.accessToken}`;
    } else if (this.apiKey) {
      config.headers['X-API-Key'] = this.apiKey;
    }

    // Agregar body si existe
    if (options.body && typeof options.body === 'object') {
      config.body = JSON.stringify(options.body);
    }

    let lastError;
    
    for (let attempt = 1; attempt <= this.retryAttempts; attempt++) {
      try {
        const response = await fetch(url, config);
        
        // Manejar respuestas exitosas
        if (response.ok) {
          const contentType = response.headers.get('content-type');
          if (contentType && contentType.includes('application/json')) {
            return await response.json();
          }
          return await response.text();
        }

        // Manejar errores específicos
        const errorData = await response.json().catch(() => ({}));
        const error = new APIError(
          errorData.code || 'UNKNOWN_ERROR',
          errorData.message || response.statusText,
          response.status,
          errorData.details,
          errorData.requestId
        );

        // Renovar token si es necesario
        if (response.status === 401 && this.refreshToken && attempt === 1) {
          await this.refreshAccessToken();
          config.headers.Authorization = `Bearer ${this.accessToken}`;
          continue;
        }

        // No reintentar errores 4xx (excepto 429)
        if (response.status >= 400 && response.status < 500 && response.status !== 429) {
          throw error;
        }

        lastError = error;
        
        // Esperar antes del siguiente intento
        if (attempt < this.retryAttempts) {
          const delay = this.calculateRetryDelay(attempt, response.status);
          await this.sleep(delay);
        }

      } catch (err) {
        lastError = err;
        
        if (attempt < this.retryAttempts) {
          await this.sleep(this.retryDelay * attempt);
        }
      }
    }

    throw lastError;
  }

  calculateRetryDelay(attempt, statusCode) {
    if (statusCode === 429) {
      return Math.min(60000, this.retryDelay * Math.pow(2, attempt));
    }
    return this.retryDelay * attempt;
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // ==================== AUTENTICACIÓN ====================

  async login(email, password) {
    const response = await this.request('/auth/login', {
      method: 'POST',
      body: { email, password }
    });

    this.accessToken = response.accessToken;
    this.refreshToken = response.refreshToken;

    return response;
  }

  async refreshAccessToken() {
    if (!this.refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await this.request('/auth/refresh', {
      method: 'POST',
      body: { refreshToken: this.refreshToken }
    });

    this.accessToken = response.accessToken;
    return response;
  }

  async logout() {
    const response = await this.request('/auth/logout', {
      method: 'POST',
      body: { refreshToken: this.refreshToken }
    });

    this.accessToken = null;
    this.refreshToken = null;

    return response;
  }

  async getCurrentUser() {
    return await this.request('/auth/me');
  }

  // ==================== PRODUCTOS ====================

  async getProducts(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/products?${queryString}` : '/products';
    return await this.request(endpoint);
  }

  async getProduct(id) {
    return await this.request(`/products/${id}`);
  }

  async createProduct(productData) {
    return await this.request('/products', {
      method: 'POST',
      body: productData
    });
  }

  async updateProduct(id, productData) {
    return await this.request(`/products/${id}`, {
      method: 'PUT',
      body: productData
    });
  }

  async deleteProduct(id) {
    return await this.request(`/products/${id}`, {
      method: 'DELETE'
    });
  }

  async searchProducts(query, filters = {}) {
    const params = { q: query, ...filters };
    const queryString = new URLSearchParams(params).toString();
    return await this.request(`/products/search?${queryString}`);
  }

  async createProductsBatch(products) {
    return await this.request('/products/batch', {
      method: 'POST',
      body: { products }
    });
  }

  // ==================== INVENTARIO ====================

  async getStockLevels(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/inventory/stock?${queryString}` : '/inventory/stock';
    return await this.request(endpoint);
  }

  async getProductStock(productId, locationId = null) {
    const params = { productId };
    if (locationId) params.locationId = locationId;
    
    const queryString = new URLSearchParams(params).toString();
    return await this.request(`/inventory/stock?${queryString}`);
  }

  async createMovement(movementData) {
    return await this.request('/inventory/movements', {
      method: 'POST',
      body: movementData
    });
  }

  async getMovements(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/inventory/movements?${queryString}` : '/inventory/movements';
    return await this.request(endpoint);
  }

  async getProductMovements(productId, params = {}) {
    const allParams = { productId, ...params };
    const queryString = new URLSearchParams(allParams).toString();
    return await this.request(`/inventory/movements?${queryString}`);
  }

  async adjustStock(productId, locationId, quantity, reason = '') {
    return await this.createMovement({
      productId,
      locationId,
      movementType: 'adjustment',
      quantity,
      notes: reason
    });
  }

  async transferStock(productId, fromLocationId, toLocationId, quantity, notes = '') {
    return await this.createMovement({
      productId,
      locationId: fromLocationId,
      movementType: 'transfer',
      quantity: -Math.abs(quantity),
      destinationLocationId: toLocationId,
      notes
    });
  }

  async updateStockBatch(updates, referenceNumber = '', notes = '') {
    return await this.request('/inventory/stock/batch-update', {
      method: 'POST',
      body: {
        updates,
        referenceNumber,
        notes
      }
    });
  }

  // ==================== REPORTES ====================

  async getStockSummary(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/reports/stock-summary?${queryString}` : '/reports/stock-summary';
    return await this.request(endpoint);
  }

  async getMovementSummary(startDate, endDate, params = {}) {
    const allParams = { startDate, endDate, ...params };
    const queryString = new URLSearchParams(allParams).toString();
    return await this.request(`/reports/movement-summary?${queryString}`);
  }

  async getTopProducts(period = '30days', type = 'sold', limit = 10) {
    const params = { period, type, limit };
    const queryString = new URLSearchParams(params).toString();
    return await this.request(`/reports/top-products?${queryString}`);
  }

  async exportReport(reportType, format = 'csv', params = {}) {
    const allParams = { format, ...params };
    const queryString = new URLSearchParams(allParams).toString();
    
    return await this.request(`/reports/${reportType}/export?${queryString}`, {
      headers: {
        'Accept': this.getAcceptHeader(format)
      }
    });
  }

  getAcceptHeader(format) {
    const formats = {
      csv: 'text/csv',
      xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      pdf: 'application/pdf',
      json: 'application/json'
    };
    return formats[format] || 'application/json';
  }

  // ==================== ALERTAS ====================

  async getAlerts(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/alerts?${queryString}` : '/alerts';
    return await this.request(endpoint);
  }

  async createAlert(alertData) {
    return await this.request('/alerts', {
      method: 'POST',
      body: alertData
    });
  }

  async updateAlert(id, alertData) {
    return await this.request(`/alerts/${id}`, {
      method: 'PUT',
      body: alertData
    });
  }

  async deleteAlert(id) {
    return await this.request(`/alerts/${id}`, {
      method: 'DELETE'
    });
  }

  async getActiveAlerts() {
    return await this.getAlerts({ status: 'active' });
  }

  // ==================== WEBHOOKS ====================

  async getWebhooks() {
    return await this.request('/webhooks');
  }

  async createWebhook(webhookData) {
    return await this.request('/webhooks', {
      method: 'POST',
      body: webhookData
    });
  }

  async getWebhook(id) {
    return await this.request(`/webhooks/${id}`);
  }

  async updateWebhook(id, webhookData) {
    return await this.request(`/webhooks/${id}`, {
      method: 'PUT',
      body: webhookData
    });
  }

  async deleteWebhook(id) {
    return await this.request(`/webhooks/${id}`, {
      method: 'DELETE'
    });
  }

  async testWebhook(id, testData = {}) {
    return await this.request(`/webhooks/${id}/test`, {
      method: 'POST',
      body: testData
    });
  }

  async getWebhookStats(id) {
    return await this.request(`/webhooks/${id}/stats`);
  }

  async getWebhookLogs(id, params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/webhooks/${id}/logs?${queryString}` : `/webhooks/${id}/logs`;
    return await this.request(endpoint);
  }

  // ==================== USUARIOS (ADMIN) ====================

  async getUsers(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/users?${queryString}` : '/users';
    return await this.request(endpoint);
  }

  async createUser(userData) {
    return await this.request('/users', {
      method: 'POST',
      body: userData
    });
  }

  async getUser(id) {
    return await this.request(`/users/${id}`);
  }

  async updateUser(id, userData) {
    return await this.request(`/users/${id}`, {
      method: 'PUT',
      body: userData
    });
  }

  async deactivateUser(id) {
    return await this.request(`/users/${id}/deactivate`, {
      method: 'PATCH'
    });
  }

  async activateUser(id) {
    return await this.request(`/users/${id}/activate`, {
      method: 'PATCH'
    });
  }

  // ==================== UTILIDADES DE ALTO NIVEL ====================

  async ensureStock(productId, locationId, minimumQuantity) {
    const stock = await this.getProductStock(productId, locationId);
    const currentStock = stock[0]?.quantity || 0;
    
    if (currentStock < minimumQuantity) {
      const needed = minimumQuantity - currentStock;
      await this.createMovement({
        productId,
        locationId,
        movementType: 'in',
        quantity: needed,
        notes: `Reposición automática - mínimo requerido: ${minimumQuantity}`
      });
      
      return { restocked: true, quantity: needed };
    }
    
    return { restocked: false, currentStock };
  }

  async getLowStockProducts(threshold = null) {
    const params = threshold ? { lowStock: true, threshold } : { lowStock: true };
    return await this.getStockLevels(params);
  }

  async bulkStockUpdate(updates) {
    const batchSize = 100;
    const results = [];
    
    for (let i = 0; i < updates.length; i += batchSize) {
      const batch = updates.slice(i, i + batchSize);
      const result = await this.updateStockBatch(batch, `BULK-${Date.now()}-${i}`);
      results.push(result);
    }
    
    return results;
  }

  async getInventoryValue(locationId = null) {
    const params = locationId ? { locationId } : {};
    const summary = await this.getStockSummary(params);
    return {
      totalValue: summary.totalValue,
      totalProducts: summary.totalProducts,
      averageValue: summary.totalValue / summary.totalProducts
    };
  }

  // ==================== HELPERS PARA EVENTOS ====================

  onStockLow(callback) {
    this.stockLowCallback = callback;
  }

  onProductCreated(callback) {
    this.productCreatedCallback = callback;
  }

  onMovementCreated(callback) {
    this.movementCreatedCallback = callback;
  }

  // Método para procesar webhooks recibidos
  processWebhook(webhookData) {
    switch (webhookData.event) {
      case 'inventory.stock.low':
        if (this.stockLowCallback) {
          this.stockLowCallback(webhookData.data);
        }
        break;
        
      case 'product.created':
        if (this.productCreatedCallback) {
          this.productCreatedCallback(webhookData.data);
        }
        break;
        
      case 'inventory.movement.created':
        if (this.movementCreatedCallback) {
          this.movementCreatedCallback(webhookData.data);
        }
        break;
    }
  }
}

// ==================== CLASE DE ERROR PERSONALIZADA ====================

class APIError extends Error {
  constructor(code, message, status, details, requestId) {
    super(message);
    this.name = 'APIError';
    this.code = code;
    this.status = status;
    this.details = details;
    this.requestId = requestId;
  }

  isRetryable() {
    return this.status >= 500 || this.code === 'RATE_LIMIT_EXCEEDED';
  }

  toString() {
    return `APIError [${this.code}]: ${this.message} (Status: ${this.status})`;
  }
}

// ==================== EJEMPLOS DE USO ====================

async function examples() {
  // Inicializar cliente
  const client = new InventoryAPI({
    baseURL: 'https://api.inventario-pymes.com/v1'
  });

  try {
    // 1. Login
    await client.login('admin@empresa.com', 'password123');
    console.log('✅ Login exitoso');

    // 2. Crear producto
    const product = await client.createProduct({
      sku: 'LAPTOP-001',
      name: 'Laptop Dell Inspiron 15',
      description: 'Laptop para uso empresarial',
      categoryId: '123e4567-e89b-12d3-a456-426614174000',
      unitPrice: 1500000.00,
      unitOfMeasure: 'unidad'
    });
    console.log('✅ Producto creado:', product.name);

    // 3. Agregar stock inicial
    await client.createMovement({
      productId: product.id,
      locationId: '123e4567-e89b-12d3-a456-426614174001',
      movementType: 'in',
      quantity: 50,
      referenceNumber: 'INITIAL-STOCK',
      notes: 'Stock inicial'
    });
    console.log('✅ Stock inicial agregado');

    // 4. Consultar stock
    const stock = await client.getProductStock(product.id);
    console.log('📦 Stock actual:', stock[0].quantity);

    // 5. Crear alerta de stock bajo
    await client.createAlert({
      productId: product.id,
      alertType: 'low_stock',
      threshold: 10,
      enabled: true,
      notificationMethods: ['email']
    });
    console.log('🔔 Alerta creada');

    // 6. Obtener reporte de inventario
    const summary = await client.getStockSummary();
    console.log('📊 Resumen de inventario:', {
      totalProducts: summary.totalProducts,
      totalValue: summary.totalValue
    });

    // 7. Configurar webhook
    const webhook = await client.createWebhook({
      url: 'https://mi-sistema.com/webhooks/inventario',
      events: ['inventory.stock.low', 'product.created'],
      secret: 'mi-secreto-seguro',
      active: true
    });
    console.log('🔗 Webhook configurado:', webhook.id);

  } catch (error) {
    if (error instanceof APIError) {
      console.error('❌ Error de API:', error.toString());
      console.error('Detalles:', error.details);
    } else {
      console.error('❌ Error:', error.message);
    }
  }
}

// ==================== EXPORTAR ====================

// Para Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { InventoryAPI, APIError };
}

// Para navegadores
if (typeof window !== 'undefined') {
  window.InventoryAPI = InventoryAPI;
  window.APIError = APIError;
}

// Ejemplo de uso con eventos
const setupEventHandlers = (client) => {
  client.onStockLow((data) => {
    console.log(`⚠️ Stock bajo para ${data.product.name}: ${data.stock.currentQuantity} unidades`);
    
    // Crear orden de compra automática
    if (data.stock.currentQuantity < 5) {
      console.log('🛒 Creando orden de compra automática...');
      // Lógica para crear orden de compra
    }
  });

  client.onProductCreated((data) => {
    console.log(`📦 Nuevo producto creado: ${data.product.name}`);
    
    // Configurar stock inicial automáticamente
    client.createMovement({
      productId: data.product.id,
      locationId: 'default-location-id',
      movementType: 'in',
      quantity: 10,
      notes: 'Stock inicial automático'
    });
  });
};

// Ejemplo de uso con promesas y async/await
const quickStart = async () => {
  const client = new InventoryAPI();
  
  // Login
  await client.login('user@empresa.com', 'password');
  
  // Obtener productos con stock bajo
  const lowStockProducts = await client.getLowStockProducts();
  console.log(`Productos con stock bajo: ${lowStockProducts.length}`);
  
  // Obtener valor total del inventario
  const inventoryValue = await client.getInventoryValue();
  console.log(`Valor total del inventario: $${inventoryValue.totalValue.toLocaleString()}`);
  
  // Logout
  await client.logout();
};

// Ejecutar ejemplos si se ejecuta directamente
if (require.main === module) {
  examples().catch(console.error);
}