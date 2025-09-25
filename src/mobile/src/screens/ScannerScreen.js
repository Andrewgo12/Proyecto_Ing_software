import React, { useState, useEffect } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { BarCodeScanner } from 'expo-barcode-scanner';
import { Button, Card, Title, Paragraph } from 'react-native-paper';
import { apiService } from '../services/api';

const ScannerScreen = ({ navigation }) => {
  const [hasPermission, setHasPermission] = useState(null);
  const [scanned, setScanned] = useState(false);
  const [productInfo, setProductInfo] = useState(null);

  useEffect(() => {
    const getBarCodeScannerPermissions = async () => {
      const { status } = await BarCodeScanner.requestPermissionsAsync();
      setHasPermission(status === 'granted');
    };

    getBarCodeScannerPermissions();
  }, []);

  const handleBarCodeScanned = async ({ type, data }) => {
    setScanned(true);
    
    try {
      // Search for product by barcode
      const products = await apiService.getProducts({ barcode: data });
      
      if (products.data && products.data.length > 0) {
        const product = products.data[0];
        setProductInfo(product);
      } else {
        Alert.alert(
          'Producto no encontrado',
          `No se encontró ningún producto con el código: ${data}`,
          [
            { text: 'Escanear otro', onPress: () => setScanned(false) },
            { text: 'Crear producto', onPress: () => navigation.navigate('NewProduct', { barcode: data }) }
          ]
        );
      }
    } catch (error) {
      Alert.alert('Error', 'No se pudo buscar el producto');
      setScanned(false);
    }
  };

  const resetScanner = () => {
    setScanned(false);
    setProductInfo(null);
  };

  const handleMovement = (type) => {
    navigation.navigate('NewMovement', {
      product: productInfo,
      movementType: type
    });
  };

  if (hasPermission === null) {
    return (
      <View style={styles.container}>
        <Title>Solicitando permisos de cámara...</Title>
      </View>
    );
  }

  if (hasPermission === false) {
    return (
      <View style={styles.container}>
        <Title>Sin acceso a la cámara</Title>
        <Paragraph>Necesitas dar permisos de cámara para usar el escáner</Paragraph>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {!scanned ? (
        <BarCodeScanner
          onBarCodeScanned={scanned ? undefined : handleBarCodeScanned}
          style={StyleSheet.absoluteFillObject}
        />
      ) : (
        <View style={styles.resultContainer}>
          {productInfo ? (
            <Card style={styles.productCard}>
              <Card.Content>
                <Title>{productInfo.name}</Title>
                <Paragraph>SKU: {productInfo.sku}</Paragraph>
                <Paragraph>Precio: ${productInfo.unit_price?.toLocaleString()}</Paragraph>
                
                <View style={styles.buttonContainer}>
                  <Button
                    mode="contained"
                    onPress={() => handleMovement('IN')}
                    style={[styles.button, { backgroundColor: '#4CAF50' }]}
                  >
                    Entrada
                  </Button>
                  <Button
                    mode="contained"
                    onPress={() => handleMovement('OUT')}
                    style={[styles.button, { backgroundColor: '#F44336' }]}
                  >
                    Salida
                  </Button>
                </View>
                
                <Button
                  mode="outlined"
                  onPress={resetScanner}
                  style={styles.scanAgainButton}
                >
                  Escanear otro código
                </Button>
              </Card.Content>
            </Card>
          ) : null}
        </View>
      )}
      
      {scanned && (
        <View style={styles.overlay}>
          <Button
            mode="contained"
            onPress={resetScanner}
            style={styles.resetButton}
          >
            Escanear de nuevo
          </Button>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  resultContainer: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  productCard: {
    padding: 20,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 20,
    marginBottom: 10,
  },
  button: {
    flex: 1,
    marginHorizontal: 5,
  },
  scanAgainButton: {
    marginTop: 10,
  },
  overlay: {
    position: 'absolute',
    bottom: 50,
    left: 20,
    right: 20,
  },
  resetButton: {
    backgroundColor: '#2196F3',
  },
});

export default ScannerScreen;