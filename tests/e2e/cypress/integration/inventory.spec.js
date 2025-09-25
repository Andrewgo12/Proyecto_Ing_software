describe('Inventory Management', () => {
  beforeEach(() => {
    cy.login('admin@test.com', 'password123');
    cy.visit('/inventory');
  });

  it('should display inventory list', () => {
    cy.get('[data-testid="inventory-table"]').should('be.visible');
    cy.get('[data-testid="product-row"]').should('have.length.greaterThan', 0);
  });

  it('should filter inventory by location', () => {
    cy.get('[data-testid="location-filter"]').select('Almacén Principal');
    cy.get('[data-testid="product-row"]').should('be.visible');
  });

  it('should create new movement', () => {
    cy.get('[data-testid="new-movement-button"]').click();
    
    cy.get('[data-testid="product-select"]').select('Camisa Polo Azul');
    cy.get('[data-testid="movement-type-select"]').select('IN');
    cy.get('[data-testid="quantity-input"]').type('10');
    cy.get('[data-testid="notes-input"]').type('Test movement');
    
    cy.get('[data-testid="save-movement-button"]').click();
    
    cy.get('[data-testid="success-message"]').should('contain', 'Movimiento registrado');
  });

  it('should show low stock alerts', () => {
    cy.get('[data-testid="low-stock-filter"]').check();
    cy.get('[data-testid="product-row"]').each(($row) => {
      cy.wrap($row).find('[data-testid="stock-status"]').should('contain', 'Stock Bajo');
    });
  });
});