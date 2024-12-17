import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';

class CartItem {
  final Game game;
  int quantity;

  CartItem(this.game, this.quantity);
}

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function onOrderCompleted;

  const CartScreen({Key? key, required this.cartItems, required this.onOrderCompleted}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final String baseUrl = "http://192.168.1.6:8080";

  Future<void> _removeItem(CartItem item) async {
    try {
      setState(() {
        widget.cartItems.remove(item);
      });

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/${item.game.productId}'),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при удалении товара');
      }
    } catch (error) {
      print('Ошибка при удалении товара из корзины: $error');
    }
  }

  Future<void> _incrementQuantity(CartItem item) async {
    setState(() {
      item.quantity++;
    });

    await _updateCart(item.game.productId, item.quantity);
  }

  Future<void> _decrementQuantity(CartItem item) async {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        widget.cartItems.remove(item);
      }
    });

    await _updateCart(item.game.productId, item.quantity);
  }


  Future<void> _updateCart(int productId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при обновлении корзины');
      }
    } catch (error) {
      print('Ошибка при обновлении корзины: $error');
    }
  }

  double _calculateTotal() {
    return widget.cartItems.fold(
      0,
      (total, item) => total + item.game.price * item.quantity,
    );
  }

  void _completeOrder() {
    widget.onOrderCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: widget.cartItems.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Slidable(
                  key: ValueKey(item.game.productId),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _removeItem(item),
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Удалить',
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            item.game.imagePath,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        ListTile(
                          title: Text(item.game.name),
                          subtitle: Text('${item.game.price} \$'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _decrementQuantity(item),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _incrementQuantity(item),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Итог: ${_calculateTotal().toStringAsFixed(2)} \$',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _completeOrder,
              child: const Text('Оформить заказ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
