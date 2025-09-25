const db = require('../utils/database');

class User {
  static async findAll(filters = {}) {
    let query = db('users').select('id', 'email', 'first_name', 'last_name', 'role', 'is_active', 'created_at');
    
    if (filters.role) {
      query = query.where('role', filters.role);
    }
    
    if (filters.is_active !== undefined) {
      query = query.where('is_active', filters.is_active);
    }

    return await query.orderBy('created_at', 'desc');
  }

  static async findById(id) {
    return await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'role', 'is_active', 'created_at', 'last_login_at')
      .where('id', id)
      .first();
  }

  static async findByEmail(email) {
    return await db('users')
      .select('*')
      .where('email', email)
      .first();
  }

  static async create(userData) {
    const [user] = await db('users')
      .insert({
        ...userData,
        created_at: new Date(),
        updated_at: new Date()
      })
      .returning(['id', 'email', 'first_name', 'last_name', 'role', 'is_active', 'created_at']);
    
    return user;
  }

  static async update(id, updateData) {
    const [user] = await db('users')
      .where('id', id)
      .update({
        ...updateData,
        updated_at: new Date()
      })
      .returning(['id', 'email', 'first_name', 'last_name', 'role', 'is_active', 'updated_at']);
    
    return user;
  }

  static async updateLastLogin(id) {
    return await db('users')
      .where('id', id)
      .update({
        last_login_at: new Date(),
        updated_at: new Date()
      });
  }

  static async deactivate(id) {
    return await db('users')
      .where('id', id)
      .update({
        is_active: false,
        updated_at: new Date()
      });
  }

  static async activate(id) {
    return await db('users')
      .where('id', id)
      .update({
        is_active: true,
        updated_at: new Date()
      });
  }

  static async changePassword(id, newPasswordHash) {
    return await db('users')
      .where('id', id)
      .update({
        password_hash: newPasswordHash,
        updated_at: new Date()
      });
  }

  static async getUserStats() {
    const stats = await db('users')
      .select(
        db.raw('COUNT(*) as total_users'),
        db.raw('COUNT(CASE WHEN is_active = true THEN 1 END) as active_users'),
        db.raw('COUNT(CASE WHEN last_login_at > NOW() - INTERVAL \'30 days\' THEN 1 END) as recent_logins')
      )
      .first();
    
    return stats;
  }
}

module.exports = User;