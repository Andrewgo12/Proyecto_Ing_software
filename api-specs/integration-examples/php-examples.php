<?php
/**
 * PHP SDK para Sistema de Inventario PYMES
 * Versión: 1.0.0
 * 
 * Requisitos:
 * - PHP 7.4+
 * - cURL extension
 * - JSON extension
 * 
 * Uso:
 * require_once 'php-examples.php';
 * $client = new InventoryAPI(['apiKey' => 'your-api-key']);
 */

class APIError extends Exception
{
    public $code;
    public $status;
    public $details;
    public $requestId;

    public function __construct($code, $message, $status, $details = [], $requestId = null)
    {
        parent::__construct($message);
        $this->code = $code;
        $this->status = $status;
        $this->details = $details;
        $this->requestId = $requestId;
    }

    public function isRetryable()
    {
        return $this->status >= 500 || $this->code === 'RATE_LIMIT_EXCEEDED';
    }

    public function __toString()
    {
        return "APIError [{$this->code}]: {$this->getMessage()} (Status: {$this->status})";
    }
}

class InventoryAPI
{
    private $baseUrl;
    private $apiKey;
    private $accessToken;
    private $refreshToken;
    private $timeout;
    private $retryAttempts;
    private $retryDelay;

    public function __construct($options = [])
    {
        $this->baseUrl = $options['baseUrl'] ?? 'https://api.inventario-pymes.com/v1';
        $this->apiKey = $options['apiKey'] ?? null;
        $this->accessToken = $options['accessToken'] ?? null;
        $this->refreshToken = $options['refreshToken'] ?? null;
        $this->timeout = $options['timeout'] ?? 30;
        $this->retryAttempts = $options['retryAttempts'] ?? 3;
        $this->retryDelay = $options['retryDelay'] ?? 1;
    }

    // ==================== UTILIDADES ====================

    private function getAuthHeaders()
    {
        $headers = [];
        if ($this->accessToken) {
            $headers[] = 'Authorization: Bearer ' . $this->accessToken;
        } elseif ($this->apiKey) {
            $headers[] = 'X-API-Key: ' . $this->apiKey;
        }
        return $headers;
    }

    private function calculateRetryDelay($attempt, $statusCode = null)
    {
        if ($statusCode === 429) {
            return min(60, $this->retryDelay * pow(2, $attempt));
        }
        return $this->retryDelay * $attempt;
    }

    public function request($endpoint, $method = 'GET', $data = null, $params = null, $headers = [])
    {
        $url = $this->baseUrl . $endpoint;
        
        if ($params) {
            $url .= '?' . http_build_query($params);
        }

        $defaultHeaders = [
            'Content-Type: application/json',
            'Accept: application/json',
            'User-Agent: InventoryAPI-PHP-SDK/1.0.0'
        ];

        $allHeaders = array_merge($defaultHeaders, $this->getAuthHeaders(), $headers);

        $lastError = null;

        for ($attempt = 1; $attempt <= $this->retryAttempts; $attempt++) {
            $ch = curl_init();
            
            curl_setopt_array($ch, [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => $this->timeout,
                CURLOPT_HTTPHEADER => $allHeaders,
                CURLOPT_CUSTOMREQUEST => $method,
                CURLOPT_SSL_VERIFYPEER => true,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_MAXREDIRS => 3
            ]);

            if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            }

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);

            if ($error) {
                $lastError = new APIError('NETWORK_ERROR', $error, 0);
                if ($attempt < $this->retryAttempts) {
                    sleep($this->retryDelay * $attempt);
                    continue;
                }
                break;
            }

            // Manejar respuestas exitosas
            if ($httpCode >= 200 && $httpCode < 300) {
                $decoded = json_decode($response, true);
                return $decoded !== null ? $decoded : $response;
            }

            // Manejar errores
            $errorData = json_decode($response, true) ?: [];
            $apiError = new APIError(
                $errorData['code'] ?? 'UNKNOWN_ERROR',
                $errorData['message'] ?? 'HTTP Error ' . $httpCode,
                $httpCode,
                $errorData['details'] ?? [],
                $errorData['requestId'] ?? null
            );

            // Renovar token si es necesario
            if ($httpCode === 401 && $this->refreshToken && $attempt === 1) {
                $this->refreshAccessToken();
                $allHeaders = array_merge($defaultHeaders, $this->getAuthHeaders(), $headers);
                continue;
            }

            // No reintentar errores 4xx (excepto 429)
            if ($httpCode >= 400 && $httpCode < 500 && $httpCode !== 429) {
                throw $apiError;
            }

            $lastError = $apiError;

            // Esperar antes del siguiente intento
            if ($attempt < $this->retryAttempts) {
                $delay = $this->calculateRetryDelay($attempt, $httpCode);
                sleep($delay);
            }
        }

        throw $lastError;
    }

    // ==================== AUTENTICACIÓN ====================

    public function login($email, $password)
    {
        $response = $this->request('/auth/login', 'POST', [
            'email' => $email,
            'password' => $password
        ]);

        $this->accessToken = $response['accessToken'];
        $this->refreshToken = $response['refreshToken'];

        return $response;
    }

    public function refreshAccessToken()
    {
        if (!$this->refreshToken) {
            throw new Exception('No refresh token available');
        }

        $response = $this->request('/auth/refresh', 'POST', [
            'refreshToken' => $this->refreshToken
        ]);

        $this->accessToken = $response['accessToken'];
        return $response;
    }

    public function logout()
    {
        $response = $this->request('/auth/logout', 'POST', [
            'refreshToken' => $this->refreshToken
        ]);

        $this->accessToken = null;
        $this->refreshToken = null;

        return $response;
    }

    public function getCurrentUser()
    {
        return $this->request('/auth/me');
    }

    // ==================== PRODUCTOS ====================

    public function getProducts($params = [])
    {
        $defaultParams = ['page' => 1, 'limit' => 20];
        $allParams = array_merge($defaultParams, $params);
        
        return $this->request('/products', 'GET', null, $allParams);
    }

    public function getProduct($productId)
    {
        return $this->request("/products/{$productId}");
    }

    public function createProduct($productData)
    {
        return $this->request('/products', 'POST', $productData);
    }

    public function updateProduct($productId, $productData)
    {
        return $this->request("/products/{$productId}", 'PUT', $productData);
    }

    public function deleteProduct($productId)
    {
        return $this->request("/products/{$productId}", 'DELETE');
    }

    public function searchProducts($query, $filters = [])
    {
        $params = array_merge(['q' => $query], $filters);
        return $this->request('/products/search', 'GET', null, $params);
    }

    public function createProductsBatch($products)
    {
        return $this->request('/products/batch', 'POST', ['products' => $products]);
    }

    // ==================== INVENTARIO ====================

    public function getStockLevels($params = [])
    {
        return $this->request('/inventory/stock', 'GET', null, $params);
    }

    public function getProductStock($productId, $locationId = null)
    {
        $params = ['productId' => $productId];
        if ($locationId) {
            $params['locationId'] = $locationId;
        }

        return $this->request('/inventory/stock', 'GET', null, $params);
    }

    public function createMovement($movementData)
    {
        return $this->request('/inventory/movements', 'POST', $movementData);
    }

    public function getMovements($params = [])
    {
        $defaultParams = ['page' => 1, 'limit' => 20];
        $allParams = array_merge($defaultParams, $params);
        
        return $this->request('/inventory/movements', 'GET', null, $allParams);
    }

    public function adjustStock($productId, $locationId, $quantity, $reason = '')
    {
        return $this->createMovement([
            'productId' => $productId,
            'locationId' => $locationId,
            'movementType' => 'adjustment',
            'quantity' => $quantity,
            'notes' => $reason
        ]);
    }

    public function transferStock($productId, $fromLocationId, $toLocationId, $quantity, $notes = '')
    {
        return $this->createMovement([
            'productId' => $productId,
            'locationId' => $fromLocationId,
            'movementType' => 'transfer',
            'quantity' => -abs($quantity),
            'destinationLocationId' => $toLocationId,
            'notes' => $notes
        ]);
    }

    public function updateStockBatch($updates, $referenceNumber = '', $notes = '')
    {
        return $this->request('/inventory/stock/batch-update', 'POST', [
            'updates' => $updates,
            'referenceNumber' => $referenceNumber,
            'notes' => $notes
        ]);
    }

    // ==================== REPORTES ====================

    public function getStockSummary($params = [])
    {
        return $this->request('/reports/stock-summary', 'GET', null, $params);
    }

    public function getMovementSummary($startDate, $endDate, $params = [])
    {
        $allParams = array_merge([
            'startDate' => $startDate,
            'endDate' => $endDate
        ], $params);

        return $this->request('/reports/movement-summary', 'GET', null, $allParams);
    }

    public function getTopProducts($period = '30days', $type = 'sold', $limit = 10)
    {
        $params = [
            'period' => $period,
            'type' => $type,
            'limit' => $limit
        ];

        return $this->request('/reports/top-products', 'GET', null, $params);
    }

    public function exportReport($reportType, $format = 'csv', $params = [])
    {
        $allParams = array_merge(['format' => $format], $params);
        
        $acceptHeaders = [
            'csv' => 'text/csv',
            'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'pdf' => 'application/pdf'
        ];

        $headers = ['Accept: ' . ($acceptHeaders[$format] ?? 'application/json')];

        return $this->request("/reports/{$reportType}/export", 'GET', null, $allParams, $headers);
    }

    // ==================== ALERTAS ====================

    public function getAlerts($params = [])
    {
        return $this->request('/alerts', 'GET', null, $params);
    }

    public function createAlert($alertData)
    {
        return $this->request('/alerts', 'POST', $alertData);
    }

    public function updateAlert($alertId, $alertData)
    {
        return $this->request("/alerts/{$alertId}", 'PUT', $alertData);
    }

    public function deleteAlert($alertId)
    {
        return $this->request("/alerts/{$alertId}", 'DELETE');
    }

    public function getActiveAlerts()
    {
        return $this->getAlerts(['status' => 'active']);
    }

    // ==================== WEBHOOKS ====================

    public function getWebhooks()
    {
        return $this->request('/webhooks');
    }

    public function createWebhook($webhookData)
    {
        return $this->request('/webhooks', 'POST', $webhookData);
    }

    public function getWebhook($webhookId)
    {
        return $this->request("/webhooks/{$webhookId}");
    }

    public function updateWebhook($webhookId, $webhookData)
    {
        return $this->request("/webhooks/{$webhookId}", 'PUT', $webhookData);
    }

    public function deleteWebhook($webhookId)
    {
        return $this->request("/webhooks/{$webhookId}", 'DELETE');
    }

    public function testWebhook($webhookId, $testData = [])
    {
        return $this->request("/webhooks/{$webhookId}/test", 'POST', $testData);
    }

    public function getWebhookStats($webhookId)
    {
        return $this->request("/webhooks/{$webhookId}/stats");
    }

    public function getWebhookLogs($webhookId, $params = [])
    {
        $defaultParams = ['limit' => 50, 'offset' => 0];
        $allParams = array_merge($defaultParams, $params);
        
        return $this->request("/webhooks/{$webhookId}/logs", 'GET', null, $allParams);
    }

    // ==================== USUARIOS (ADMIN) ====================

    public function getUsers($params = [])
    {
        return $this->request('/users', 'GET', null, $params);
    }

    public function createUser($userData)
    {
        return $this->request('/users', 'POST', $userData);
    }

    public function getUser($userId)
    {
        return $this->request("/users/{$userId}");
    }

    public function updateUser($userId, $userData)
    {
        return $this->request("/users/{$userId}", 'PUT', $userData);
    }

    public function deactivateUser($userId)
    {
        return $this->request("/users/{$userId}/deactivate", 'PATCH');
    }

    public function activateUser($userId)
    {
        return $this->request("/users/{$userId}/activate", 'PATCH');
    }

    // ==================== UTILIDADES DE ALTO NIVEL ====================

    public function ensureStock($productId, $locationId, $minimumQuantity)
    {
        $stock = $this->getProductStock($productId, $locationId);
        $currentStock = isset($stock[0]) ? $stock[0]['quantity'] : 0;

        if ($currentStock < $minimumQuantity) {
            $needed = $minimumQuantity - $currentStock;
            $this->createMovement([
                'productId' => $productId,
                'locationId' => $locationId,
                'movementType' => 'in',
                'quantity' => $needed,
                'notes' => "Reposición automática - mínimo requerido: {$minimumQuantity}"
            ]);

            return ['restocked' => true, 'quantity' => $needed];
        }

        return ['restocked' => false, 'currentStock' => $currentStock];
    }

    public function getLowStockProducts($threshold = null)
    {
        $params = ['lowStock' => 'true'];
        if ($threshold !== null) {
            $params['threshold'] = $threshold;
        }

        return $this->getStockLevels($params);
    }

    public function bulkStockUpdate($updates, $batchSize = 100)
    {
        $results = [];
        $batches = array_chunk($updates, $batchSize);

        foreach ($batches as $index => $batch) {
            $referenceNumber = 'BULK-' . time() . '-' . $index;
            $result = $this->updateStockBatch($batch, $referenceNumber);
            $results[] = $result;
        }

        return $results;
    }

    public function getInventoryValue($locationId = null)
    {
        $params = [];
        if ($locationId) {
            $params['locationId'] = $locationId;
        }

        $summary = $this->getStockSummary($params);
        
        return [
            'totalValue' => $summary['totalValue'],
            'totalProducts' => $summary['totalProducts'],
            'averageValue' => $summary['totalProducts'] > 0 ? 
                $summary['totalValue'] / $summary['totalProducts'] : 0
        ];
    }
}

// ==================== CLASE PARA MANEJO DE WEBHOOKS ====================

class WebhookHandler
{
    private $client;
    private $secret;

    public function __construct(InventoryAPI $client, $secret)
    {
        $this->client = $client;
        $this->secret = $secret;
    }

    public function verifySignature($payload, $signature)
    {
        $expectedSignature = 'sha256=' . hash_hmac('sha256', $payload, $this->secret);
        return hash_equals($signature, $expectedSignature);
    }

    public function processWebhook($webhookData)
    {
        $event = $webhookData['event'] ?? '';
        $data = $webhookData['data'] ?? [];

        switch ($event) {
            case 'inventory.stock.low':
                $this->handleLowStock($data);
                break;
            case 'product.created':
                $this->handleProductCreated($data);
                break;
            case 'inventory.movement.created':
                $this->handleMovementCreated($data);
                break;
            default:
                error_log("Evento no manejado: {$event}");
        }
    }

    private function handleLowStock($data)
    {
        $product = $data['product'];
        $stock = $data['stock'];

        error_log("⚠️ Stock bajo para {$product['name']}: {$stock['currentQuantity']} unidades");

        // Crear orden de compra automática si es crítico
        if ($stock['currentQuantity'] < 5) {
            error_log('🛒 Creando orden de compra automática...');
            // Lógica para crear orden de compra
        }
    }

    private function handleProductCreated($data)
    {
        $product = $data['product'];
        error_log("📦 Nuevo producto creado: {$product['name']}");

        // Configurar stock inicial automáticamente
        try {
            $this->client->createMovement([
                'productId' => $product['id'],
                'locationId' => 'default-location-id',
                'movementType' => 'in',
                'quantity' => 10,
                'notes' => 'Stock inicial automático'
            ]);
            error_log('✅ Stock inicial configurado automáticamente');
        } catch (APIError $e) {
            error_log("❌ Error configurando stock inicial: {$e}");
        }
    }

    private function handleMovementCreated($data)
    {
        $movement = $data['movement'];
        $product = $data['product'];

        error_log("📋 Nuevo movimiento: {$movement['movementType']} {$movement['quantity']} de {$product['name']}");
    }
}

// ==================== EJEMPLOS DE USO ====================

function examples()
{
    // Inicializar cliente
    $client = new InventoryAPI();

    try {
        // 1. Login
        $client->login('admin@empresa.com', 'password123');
        echo "✅ Login exitoso\n";

        // 2. Crear producto
        $product = $client->createProduct([
            'sku' => 'LAPTOP-001',
            'name' => 'Laptop Dell Inspiron 15',
            'description' => 'Laptop para uso empresarial',
            'categoryId' => '123e4567-e89b-12d3-a456-426614174000',
            'unitPrice' => 1500000.00,
            'unitOfMeasure' => 'unidad'
        ]);
        echo "✅ Producto creado: {$product['name']}\n";

        // 3. Agregar stock inicial
        $client->createMovement([
            'productId' => $product['id'],
            'locationId' => '123e4567-e89b-12d3-a456-426614174001',
            'movementType' => 'in',
            'quantity' => 50,
            'referenceNumber' => 'INITIAL-STOCK',
            'notes' => 'Stock inicial'
        ]);
        echo "✅ Stock inicial agregado\n";

        // 4. Consultar stock
        $stock = $client->getProductStock($product['id']);
        echo "📦 Stock actual: {$stock[0]['quantity']}\n";

        // 5. Crear alerta de stock bajo
        $client->createAlert([
            'productId' => $product['id'],
            'alertType' => 'low_stock',
            'threshold' => 10,
            'enabled' => true,
            'notificationMethods' => ['email']
        ]);
        echo "🔔 Alerta creada\n";

        // 6. Obtener reporte de inventario
        $summary = $client->getStockSummary();
        echo "📊 Resumen de inventario: {$summary['totalProducts']} productos, valor total: $" . number_format($summary['totalValue'], 2) . "\n";

        // 7. Configurar webhook
        $webhook = $client->createWebhook([
            'url' => 'https://mi-sistema.com/webhooks/inventario',
            'events' => ['inventory.stock.low', 'product.created'],
            'secret' => 'mi-secreto-seguro',
            'active' => true
        ]);
        echo "🔗 Webhook configurado: {$webhook['id']}\n";

        // 8. Obtener productos con stock bajo
        $lowStockProducts = $client->getLowStockProducts();
        echo "⚠️ Productos con stock bajo: " . count($lowStockProducts) . "\n";

        // 9. Obtener valor del inventario
        $inventoryValue = $client->getInventoryValue();
        echo "💰 Valor total del inventario: $" . number_format($inventoryValue['totalValue'], 2) . "\n";

    } catch (APIError $e) {
        echo "❌ Error de API: {$e}\n";
        echo "Detalles: " . json_encode($e->details) . "\n";
    } catch (Exception $e) {
        echo "❌ Error: {$e->getMessage()}\n";
    } finally {
        // Logout automático
        try {
            $client->logout();
            echo "👋 Logout exitoso\n";
        } catch (Exception $e) {
            // Ignorar errores al cerrar sesión
        }
    }
}

// Ejemplo de endpoint para recibir webhooks
function webhookEndpoint()
{
    // Verificar método HTTP
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        exit('Method not allowed');
    }

    // Obtener payload
    $payload = file_get_contents('php://input');
    $signature = $_SERVER['HTTP_X_WEBHOOK_SIGNATURE'] ?? '';

    // Inicializar cliente y handler
    $client = new InventoryAPI();
    $webhookHandler = new WebhookHandler($client, 'mi-secreto-seguro');

    // Verificar firma
    if (!$webhookHandler->verifySignature($payload, $signature)) {
        http_response_code(401);
        exit('Invalid signature');
    }

    // Procesar webhook
    try {
        $webhookData = json_decode($payload, true);
        $webhookHandler->processWebhook($webhookData);
        
        http_response_code(200);
        echo json_encode(['received' => true]);
    } catch (Exception $e) {
        error_log("Error procesando webhook: {$e->getMessage()}");
        http_response_code(500);
        echo json_encode(['error' => 'Internal server error']);
    }
}

// Ejemplo de script para monitoreo automático
function monitoringScript()
{
    $client = new InventoryAPI();
    
    try {
        $client->login('monitor@empresa.com', 'password123');
        
        // Verificar productos con stock bajo
        $lowStockProducts = $client->getLowStockProducts();
        
        if (count($lowStockProducts) > 0) {
            echo "⚠️ ALERTA: " . count($lowStockProducts) . " productos con stock bajo:\n";
            
            foreach ($lowStockProducts as $item) {
                $product = $item['product'];
                $quantity = $item['quantity'];
                $minStock = $item['minStock'];
                
                echo "- {$product['name']}: {$quantity} unidades (mínimo: {$minStock})\n";
                
                // Enviar email de alerta si es crítico
                if ($quantity < 5) {
                    // Lógica para enviar email
                    echo "  📧 Email de alerta enviado\n";
                }
            }
        } else {
            echo "✅ Todos los productos tienen stock adecuado\n";
        }
        
        // Obtener resumen del día
        $today = date('Y-m-d');
        $movements = $client->getMovements([
            'startDate' => $today,
            'endDate' => $today
        ]);
        
        echo "\n📊 Movimientos del día: " . count($movements) . "\n";
        
        $client->logout();
        
    } catch (APIError $e) {
        echo "❌ Error: {$e}\n";
    }
}

// Ejemplo de clase para integración con sistema existente
class InventoryIntegration
{
    private $client;
    private $localDb;

    public function __construct($apiConfig, $dbConfig)
    {
        $this->client = new InventoryAPI($apiConfig);
        // Inicializar conexión a base de datos local
        $this->localDb = new PDO($dbConfig['dsn'], $dbConfig['user'], $dbConfig['pass']);
    }

    public function syncProducts()
    {
        try {
            // Obtener productos de la API
            $apiProducts = $this->client->getProducts(['limit' => 1000]);
            
            foreach ($apiProducts['data'] as $product) {
                // Verificar si existe en base local
                $stmt = $this->localDb->prepare("SELECT id FROM products WHERE api_id = ?");
                $stmt->execute([$product['id']]);
                
                if ($stmt->fetch()) {
                    // Actualizar producto existente
                    $this->updateLocalProduct($product);
                } else {
                    // Crear nuevo producto
                    $this->createLocalProduct($product);
                }
            }
            
            echo "✅ Sincronización de productos completada\n";
            
        } catch (Exception $e) {
            echo "❌ Error en sincronización: {$e->getMessage()}\n";
        }
    }

    private function updateLocalProduct($product)
    {
        $stmt = $this->localDb->prepare("
            UPDATE products 
            SET name = ?, price = ?, updated_at = NOW() 
            WHERE api_id = ?
        ");
        $stmt->execute([$product['name'], $product['unitPrice'], $product['id']]);
    }

    private function createLocalProduct($product)
    {
        $stmt = $this->localDb->prepare("
            INSERT INTO products (api_id, name, sku, price, created_at) 
            VALUES (?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $product['id'], 
            $product['name'], 
            $product['sku'], 
            $product['unitPrice']
        ]);
    }

    public function syncStock()
    {
        try {
            $stockLevels = $this->client->getStockLevels();
            
            foreach ($stockLevels as $stock) {
                $stmt = $this->localDb->prepare("
                    UPDATE products 
                    SET stock_quantity = ?, last_stock_update = NOW() 
                    WHERE api_id = ?
                ");
                $stmt->execute([$stock['quantity'], $stock['productId']]);
            }
            
            echo "✅ Sincronización de stock completada\n";
            
        } catch (Exception $e) {
            echo "❌ Error en sincronización de stock: {$e->getMessage()}\n";
        }
    }
}

// Ejecutar ejemplos si se ejecuta directamente
if (php_sapi_name() === 'cli' && basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    examples();
}

?>