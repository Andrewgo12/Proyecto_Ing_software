const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

class NotificationService {
  constructor() {
    this.transporter = nodemailer.createTransporter({
      host: process.env.EMAIL_HOST,
      port: process.env.EMAIL_PORT,
      secure: process.env.EMAIL_SECURE === 'true',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
  }

  static async sendLowStockAlert(stockLevel) {
    try {
      const subject = `🚨 Alerta de Stock Bajo - ${stockLevel.product_name}`;
      const html = `
        <h2>Alerta de Stock Bajo</h2>
        <p><strong>Producto:</strong> ${stockLevel.product_name}</p>
        <p><strong>SKU:</strong> ${stockLevel.product_sku}</p>
        <p><strong>Ubicación:</strong> ${stockLevel.location_name}</p>
        <p><strong>Stock Actual:</strong> ${stockLevel.quantity}</p>
        <p><strong>Stock Mínimo:</strong> ${stockLevel.min_stock_level}</p>
        <p style="color: red;"><strong>Acción requerida:</strong> Reabastecer producto</p>
      `;

      await this.sendEmail({
        to: process.env.ALERT_EMAIL || 'admin@empresa.com',
        subject,
        html
      });

      logger.info(`Low stock alert sent for product ${stockLevel.product_id}`);
    } catch (error) {
      logger.error('Failed to send low stock alert:', error);
    }
  }

  static async sendOutOfStockAlert(stockLevel) {
    try {
      const subject = `🔴 URGENTE: Producto Agotado - ${stockLevel.product_name}`;
      const html = `
        <h2 style="color: red;">PRODUCTO AGOTADO</h2>
        <p><strong>Producto:</strong> ${stockLevel.product_name}</p>
        <p><strong>SKU:</strong> ${stockLevel.product_sku}</p>
        <p><strong>Ubicación:</strong> ${stockLevel.location_name}</p>
        <p><strong>Stock Actual:</strong> 0</p>
        <p style="color: red;"><strong>ACCIÓN URGENTE:</strong> Reabastecer inmediatamente</p>
      `;

      await this.sendEmail({
        to: process.env.ALERT_EMAIL || 'admin@empresa.com',
        subject,
        html,
        priority: 'high'
      });

      logger.warn(`Out of stock alert sent for product ${stockLevel.product_id}`);
    } catch (error) {
      logger.error('Failed to send out of stock alert:', error);
    }
  }

  static async sendMovementNotification(movement) {
    try {
      const subject = `📦 Movimiento de Inventario - ${movement.product_name}`;
      const html = `
        <h2>Movimiento de Inventario Registrado</h2>
        <p><strong>Producto:</strong> ${movement.product_name}</p>
        <p><strong>Tipo:</strong> ${movement.movement_type}</p>
        <p><strong>Cantidad:</strong> ${movement.quantity}</p>
        <p><strong>Ubicación:</strong> ${movement.location_name}</p>
        <p><strong>Usuario:</strong> ${movement.user_first_name} ${movement.user_last_name}</p>
        <p><strong>Fecha:</strong> ${new Date(movement.created_at).toLocaleString()}</p>
      `;

      await this.sendEmail({
        to: process.env.MOVEMENT_EMAIL || 'operations@empresa.com',
        subject,
        html
      });

      logger.info(`Movement notification sent for movement ${movement.id}`);
    } catch (error) {
      logger.error('Failed to send movement notification:', error);
    }
  }

  static async sendEmail({ to, subject, html, priority = 'normal' }) {
    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
        to,
        subject,
        html,
        priority
      };

      const result = await this.transporter.sendMail(mailOptions);
      logger.info(`Email sent successfully: ${result.messageId}`);
      return result;
    } catch (error) {
      logger.error('Failed to send email:', error);
      throw error;
    }
  }

  static async sendBulkAlert(alerts) {
    try {
      const subject = `📊 Resumen de Alertas de Inventario - ${alerts.length} alertas`;
      
      let html = '<h2>Resumen de Alertas de Inventario</h2><ul>';
      alerts.forEach(alert => {
        html += `<li><strong>${alert.product_name}</strong> - Stock: ${alert.quantity} (Mín: ${alert.min_stock_level})</li>`;
      });
      html += '</ul>';

      await this.sendEmail({
        to: process.env.ALERT_EMAIL || 'admin@empresa.com',
        subject,
        html
      });

      logger.info(`Bulk alert sent for ${alerts.length} products`);
    } catch (error) {
      logger.error('Failed to send bulk alert:', error);
    }
  }
}

module.exports = NotificationService;