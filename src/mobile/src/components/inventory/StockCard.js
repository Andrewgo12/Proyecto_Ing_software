import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Card, Title, Paragraph, Chip } from 'react-native-paper';

const StockCard = ({ item, onPress }) => {
  const getStatusColor = () => {
    if (item.quantity === 0) return '#F44336';
    if (item.quantity <= item.min_stock_level) return '#FF9800';
    return '#4CAF50';
  };

  const getStatusText = () => {
    if (item.quantity === 0) return 'Agotado';
    if (item.quantity <= item.min_stock_level) return 'Stock Bajo';
    return 'Normal';
  };

  return (
    <Card style={styles.card} onPress={onPress}>
      <Card.Content>
        <View style={styles.header}>
          <View style={styles.productInfo}>
            <Title style={styles.productName}>{item.product_name}</Title>
            <Paragraph style={styles.sku}>{item.product_sku}</Paragraph>
            <Paragraph style={styles.location}>{item.location_name}</Paragraph>
          </View>
          <Chip
            mode="outlined"
            textStyle={{ color: getStatusColor() }}
            style={{ borderColor: getStatusColor() }}
          >
            {getStatusText()}
          </Chip>
        </View>

        <View style={styles.stockInfo}>
          <View style={styles.stockItem}>
            <Paragraph style={styles.stockLabel}>Stock Actual</Paragraph>
            <Title style={[styles.stockValue, { color: getStatusColor() }]}>
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
  );
};

const styles = StyleSheet.create({
  card: {
    margin: 8,
    marginHorizontal: 16,
  },
  header: {
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
});

export default StockCard;