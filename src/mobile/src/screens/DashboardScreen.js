import React, { useEffect, useState } from 'react';
import { View, StyleSheet, ScrollView, RefreshControl } from 'react-native';
import { Card, Title, Paragraph, Chip } from 'react-native-paper';
import { apiService } from '../services/api';

const DashboardScreen = () => {
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadMetrics = async () => {
    try {
      const data = await apiService.getDashboardMetrics();
      setMetrics(data);
    } catch (error) {
      console.error('Error loading metrics:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadMetrics();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    loadMetrics();
  };

  if (loading) {
    return <View style={styles.container} />;
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      <View style={styles.metricsGrid}>
        <Card style={styles.metricCard}>
          <Card.Content>
            <Title style={styles.metricNumber}>
              {metrics?.inventory?.total_products || 0}
            </Title>
            <Paragraph>Total Productos</Paragraph>
          </Card.Content>
        </Card>

        <Card style={styles.metricCard}>
          <Card.Content>
            <Title style={styles.metricNumber}>
              ${(metrics?.inventory?.total_value || 0).toLocaleString()}
            </Title>
            <Paragraph>Valor Inventario</Paragraph>
          </Card.Content>
        </Card>

        <Card style={styles.metricCard}>
          <Card.Content>
            <Title style={[styles.metricNumber, styles.warningText]}>
              {metrics?.alerts?.low_stock_count || 0}
            </Title>
            <Paragraph>Stock Bajo</Paragraph>
          </Card.Content>
        </Card>

        <Card style={styles.metricCard}>
          <Card.Content>
            <Title style={styles.metricNumber}>
              {metrics?.movements?.total_movements || 0}
            </Title>
            <Paragraph>Movimientos (30d)</Paragraph>
          </Card.Content>
        </Card>
      </View>

      {metrics?.alerts?.low_stock_count > 0 && (
        <Card style={styles.alertCard}>
          <Card.Content>
            <View style={styles.alertHeader}>
              <Title style={styles.alertTitle}>⚠️ Alertas</Title>
              <Chip mode="outlined" textStyle={styles.chipText}>
                {metrics.alerts.low_stock_count} productos
              </Chip>
            </View>
            <Paragraph>
              Hay productos con stock por debajo del mínimo recomendado.
            </Paragraph>
          </Card.Content>
        </Card>
      )}

      <Card style={styles.activityCard}>
        <Card.Content>
          <Title>Actividad Reciente</Title>
          <View style={styles.activityItem}>
            <Paragraph>Entrada de mercancía registrada</Paragraph>
            <Paragraph style={styles.timeText}>Hace 2 horas</Paragraph>
          </View>
          <View style={styles.activityItem}>
            <Paragraph>Ajuste de inventario realizado</Paragraph>
            <Paragraph style={styles.timeText}>Hace 4 horas</Paragraph>
          </View>
          <View style={styles.activityItem}>
            <Paragraph>Producto agregado al catálogo</Paragraph>
            <Paragraph style={styles.timeText}>Hace 6 horas</Paragraph>
          </View>
        </Card.Content>
      </Card>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 16,
  },
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  metricCard: {
    width: '48%',
    marginBottom: 16,
  },
  metricNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2196F3',
  },
  warningText: {
    color: '#FF9800',
  },
  alertCard: {
    backgroundColor: '#FFF3E0',
    marginBottom: 16,
  },
  alertHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  alertTitle: {
    color: '#E65100',
  },
  chipText: {
    fontSize: 12,
  },
  activityCard: {
    marginBottom: 16,
  },
  activityItem: {
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E0E0E0',
  },
  timeText: {
    fontSize: 12,
    color: '#757575',
    marginTop: 4,
  },
});

export default DashboardScreen;