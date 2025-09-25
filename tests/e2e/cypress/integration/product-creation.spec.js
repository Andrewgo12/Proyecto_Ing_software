describe('Product Creation Flow', () => {
  beforeEach(() => {
    cy.login('admin@test.com', 'password123');
    cy.visit('/products');
  });

  it('should create a new product successfully', () => {
    cy.get('[data-testid="new-product-button"]').click();
    
    cy.get('[data-testid="sku-input"]').type('TEST-001');
    cy.get('[data-testid="name-input"]').type('Test Product');
    cy.get('[data-testid="category-select"]').select('Electronics');
    cy.get('[data-testid="price-input"]').type('99.99');
    cy.get('[data-testid="cost-input"]').type('59.99');
    
    cy.get('[data-testid="save-button"]').click();
    
    cy.get('[data-testid="success-message"]').should('contain', 'Product created successfully');
    cy.url().should('include', '/products');
    cy.get('[data-testid="product-table"]').should('contain', 'TEST-001');
  });

  it('should validate required fields', () => {
    cy.get('[data-testid="new-product-button"]').click();
    cy.get('[data-testid="save-button"]').click();
    
    cy.get('[data-testid="sku-error"]').should('be.visible');
    cy.get('[data-testid="name-error"]').should('be.visible');
  });

  it('should prevent duplicate SKU', () => {
    cy.createProduct({ sku: 'DUP-001', name: 'Duplicate Test' });
    
    cy.get('[data-testid="new-product-button"]').click();
    cy.get('[data-testid="sku-input"]').type('DUP-001');
    cy.get('[data-testid="name-input"]').type('Another Product');
    cy.get('[data-testid="save-button"]').click();
    
    cy.get('[data-testid="error-message"]').should('contain', 'SKU already exists');
  });
});