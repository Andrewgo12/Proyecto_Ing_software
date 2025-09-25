import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, RefreshControl } from 'react-native';
import { Card, Title, Paragraph, Chip, Searchbar, FAB } from 'react-native-paper';
import { apiService } from '../services/api';

const InventoryScreen = ({ navigation }) => {
  const [stock, setStock] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const loadStock = async () => {
    try {
      const data = await apiService.getStock();
      setStock(data);
    } catch (error) {
      console.error('Error loading stock:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadStock();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    loadStock();
  };

  const getStatusColor = (item) => {
    if (item.quantity === 0) return '#F44336';
    if (item.quantity <= item.min_stock_level) return '#FF9800';
    return '#4CAF50';
  };

  const getStatusText = (item) => {
    if (item.quantity === 0) return 'Agotado';
    if (item.quantity <= item.min_stock_level) return 'Stock Bajo';
    return 'Normal';
  };

  const filteredStock = stock.filter(item =>
    item.product_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.product_sku.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) {
    return <View style={styles.container} />;
  }

  return (
    <View style={styles.container}>
      <Searchbar
        placeholder="Buscar productos..."
        onChangeText={setSearchQuery}
        value={searchQuery}
        style={styles.searchbar}
      />

      <ScrollView
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {filteredStock.map((item) => (
          <Card key={`${item.product_id}-${item.location_id}`} style={styles.card}>
            <Card.Content>
              <View style={styles.cardHeader}>
                <View style={styles.productInfo}>
                  <Title style={styles.productName}>{item.product_name}</Title>
                  <Paragraph style={styles.sku}>{item.product_sku}</Paragraph>
                  <Paragraph style={styles.location}>{item.location_name}</Paragraph>
                </View>
                <Chip
                  mode="outlined"
                  textStyle={{ color: getStatusColor(item) }}
                  style={{ borderColor: getStatusColor(item) }}
                >
                  {getStatusText(item)}
                </Chip>
              </View>

              <View style={styles.stockInfo}>
                <View style={styles.stockItem}>
                  <Paragraph style={styles.stockLabel}>Stock Actual</Paragraph>
                  <Title style={[styles.stockValue, { color: getStatusColor(item) }]}>
                    {item.quantity}
                  </Title>
                </View>
                <View style={styles.stockItem}>
                  <Paragraph style={styles.stockLabel}>Stock Mínimo</Paragraph>
                  <Title style={styles.stockValue}>{item.min_stock_level}</Title>
                </View>
              </View>
            </Card.Content>
          </Card>
        ))}
      </ScrollView>

      <FAB
        style={styles.fab}
        icon="plus"
        onPress={() => navigation.navigate('NewMovement')}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  searchbar: {
    margin: 16,
  },
  card: {
    margin: 8,
    marginHorizontal: 16,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  productInfo: {
    flex: 1,
  },
  productName: {
    fontSize: 16,
    marginBottom: 4,
  },
  sku: {
    fontSize: 12,
    color: '#666',
    marginBottom: 2,
  },
  location: {
    fontSize: 12,
    color: '#666',
  },
  stockInfo: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  stockItem: {
    alignItems: 'center',
  },
  stockLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  stockValue: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
  },
});

export default InventoryScreen;