// Custom commands for Cypress

Cypress.Commands.add('login', (email, password) => {
  cy.request({
    method: 'POST',
    url: '/api/auth/login',
    body: { email, password }
  }).then((response) => {
    window.localStorage.setItem('accessToken', response.body.data.accessToken);
    window.localStorage.setItem('user', JSON.stringify(response.body.data.user));
  });
});

Cypress.Commands.add('logout', () => {
  window.localStorage.removeItem('accessToken');
  window.localStorage.removeItem('user');
});

Cypress.Commands.add('createProduct', (productData) => {
  cy.request({
    method: 'POST',
    url: '/api/products',
    headers: {
      Authorization: `Bearer ${window.localStorage.getItem('accessToken')}`
    },
    body: productData
  });
});

Cypress.Commands.add('createMovement', (movementData) => {
  cy.request({
    method: 'POST',
    url: '/api/inventory/movements',
    headers: {
      Authorization: `Bearer ${window.localStorage.getItem('accessToken')}`
    },
    body: movementData
  });
});