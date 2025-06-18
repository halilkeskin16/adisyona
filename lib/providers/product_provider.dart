import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart'; // CategoryModel'inizin yolu
import '../models/product_model.dart';   // ProductModel'inizin yolu

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Özel durum değişkenleri
  List<Category> _categories = [];
  List<Product> _products = [];
  String? _selectedCategoryId;
  String _searchText = '';

  bool _isLoading = false;
  String? _error; // Hata mesajı için

  // Getters: Widget'ların bu verilere erişmesini sağlar
  List<Category> get categories => _categories;
  List<Product> get allProducts => _products; // Tüm ürünleri verir
  bool get isLoading => _isLoading;
  String? get message => _error; // Hata mesajını 'message' olarak sunuyoruz

  String? get selectedCategoryId => _selectedCategoryId;
  String get searchText => _searchText;

  // Filtrelenmiş ürün listesini döndüren getter
  // Kategoriye ve arama metnine göre ürünleri filtreler
  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategoryId == null || product.categoryId == _selectedCategoryId;
      final matchesSearch = _searchText.isEmpty ||
          product.name.toLowerCase().contains(_searchText.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchText.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // SETTER: Seçili kategori ID'sini günceller ve dinleyicileri bilgilendirir
  void setSelectedCategory(String? categoryId) {
    if (_selectedCategoryId != categoryId) { // Sadece değişiklik varsa güncelle
      _selectedCategoryId = categoryId;
      notifyListeners();
    }
  }

  // SETTER: Arama metnini günceller ve dinleyicileri bilgilendirir
  void setSearchText(String text) {
    if (_searchText != text) { // Sadece değişiklik varsa güncelle
      _searchText = text;
      notifyListeners();
    }
  }

  // Tüm kategorileri ve ürünleri Firestore'dan çeker
  // Bu metod uygulama başlatıldığında veya ihtiyaç duyulduğunda çağrılır
  Future<void> fetchData(String companyId) async {
    if (_isLoading) return; // Zaten yükleniyorsa tekrar başlatma

    try {
      _isLoading = true;
      _error = null; // Önceki hataları temizle
      notifyListeners(); // Yüklenme durumunu bildir

      // Kategorileri çek
      final catSnap = await _firestore
          .collection('categories')
          .where('companyId', isEqualTo: companyId)
          .get();

      // Tüm ürünleri çek
      final prodSnap = await _firestore
          .collection('products')
          .where('companyId', isEqualTo: companyId)
          .get();

      _categories = catSnap.docs.map((e) => Category.fromMap(e.id, e.data())).toList();
      _products = prodSnap.docs.map((e) => Product.fromMap(e.id, e.data())).toList();

      // Eğer seçili kategori yoksa ve kategoriler varsa ilkini seç
      if (_categories.isNotEmpty && _selectedCategoryId == null) {
        _selectedCategoryId = _categories.first.id;
      }

      _error = null; // Başarılıysa hata mesajını temizle
    } catch (e) {
      _error = 'Veri yüklenemedi: $e'; // Hata durumunda mesajı kaydet
    } finally {
      _isLoading = false;
      notifyListeners(); // Yükleme bittiğini bildir
    }
  }

  // Provider'ın durumunu temizler (örneğin kullanıcı çıkışı yapıldığında)
  void clear() {
    _categories = [];
    _products = [];
    _selectedCategoryId = null;
    _searchText = '';
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
