import React from 'react';

const Footer = () => {
  return (
    <footer className="bg-white border-t border-gray-200 py-4 px-6 mt-auto">
      <div className="flex justify-between items-center text-sm text-gray-600">
        <div>
          © 2024 Inventario PYMES. Todos los derechos reservados.
        </div>
        <div className="flex space-x-4">
          <span>v1.0.0</span>
          <a href="#" className="hover:text-blue-600">Soporte</a>
          <a href="#" className="hover:text-blue-600">Documentación</a>
        </div>
      </div>
    </footer>
  );
};

export default Footer;