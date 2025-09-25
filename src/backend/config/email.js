const nodemailer = require('nodemailer');
const logger = require('../src/utils/logger');

class EmailConfig {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
  }

  async initialize() {
    try {
      const config = {
        host: process.env.EMAIL_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.EMAIL_PORT) || 587,
        secure: process.env.EMAIL_SECURE === 'true',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS
        }
      };

      // Skip email config if credentials not provided
      if (!config.auth.user || !config.auth.pass) {
        logger.warn('Email credentials not provided, email functionality disabled');
        return;
      }

      this.transporter = nodemailer.createTransporter(config);

      // Verify connection
      await this.transporter.verify();
      this.isConfigured = true;
      logger.info('Email transporter configured successfully');
    } catch (error) {
      logger.error('Failed to configure email transporter:', error);
      this.isConfigured = false;
    }
  }

  getTransporter() {
    return this.transporter;
  }

  isReady() {
    return this.isConfigured && this.transporter;
  }

  async sendMail(options) {
    if (!this.isReady()) {
      logger.warn('Email transporter not ready, skipping email send');
      return null;
    }

    try {
      const defaultOptions = {
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
      };

      const mailOptions = { ...defaultOptions, ...options };
      const result = await this.transporter.sendMail(mailOptions);
      
      logger.info(`Email sent successfully: ${result.messageId}`);
      return result;
    } catch (error) {
      logger.error('Failed to send email:', error);
      throw error;
    }
  }

  // Email templates
  getTemplates() {
    return {
      lowStock: (data) => ({
        subject: `🚨 Alerta de Stock Bajo - ${data.productName}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #e74c3c;">⚠️ Alerta de Stock Bajo</h2>
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px;">
              <p><strong>Producto:</strong> ${data.productName}</p>
              <p><strong>SKU:</strong> ${data.sku}</p>
              <p><strong>Ubicación:</strong> ${data.locationName}</p>
              <p><strong>Stock Actual:</strong> ${data.currentStock}</p>
              <p><strong>Stock Mínimo:</strong> ${data.minStock}</p>
            </div>
            <p style="color: #e74c3c; font-weight: bold;">Acción requerida: Reabastecer producto</p>
          </div>
        `
      }),

      outOfStock: (data) => ({
        subject: `🔴 URGENTE: Producto Agotado - ${data.productName}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #c0392b;">🔴 PRODUCTO AGOTADO</h2>
            <div style="background: #fadbd8; padding: 20px; border-radius: 8px; border-left: 4px solid #e74c3c;">
              <p><strong>Producto:</strong> ${data.productName}</p>
              <p><strong>SKU:</strong> ${data.sku}</p>
              <p><strong>Ubicación:</strong> ${data.locationName}</p>
              <p><strong>Stock Actual:</strong> 0</p>
            </div>
            <p style="color: #c0392b; font-weight: bold; font-size: 16px;">
              ⚠️ ACCIÓN URGENTE: Reabastecer inmediatamente
            </p>
          </div>
        `
      }),

      movement: (data) => ({
        subject: `📦 Movimiento de Inventario - ${data.productName}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2980b9;">📦 Movimiento de Inventario</h2>
            <div style="background: #ebf3fd; padding: 20px; border-radius: 8px;">
              <p><strong>Producto:</strong> ${data.productName}</p>
              <p><strong>Tipo:</strong> ${data.movementType}</p>
              <p><strong>Cantidad:</strong> ${data.quantity}</p>
              <p><strong>Ubicación:</strong> ${data.locationName}</p>
              <p><strong>Usuario:</strong> ${data.userName}</p>
              <p><strong>Fecha:</strong> ${data.date}</p>
            </div>
          </div>
        `
      })
    };
  }
}

const emailConfig = new EmailConfig();

module.exports = emailConfig;