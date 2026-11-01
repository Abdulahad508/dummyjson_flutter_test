import 'package:dummyjson_flutter_test/features/auth/domain/entities/user.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';

const sampleUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  image: 'https://dummyjson.com/icon/emilys/128',
);

const sampleProduct = Product(
  id: 1,
  title: 'Essence Mascara',
  description: 'A volumizing mascara.',
  category: 'beauty',
  price: 9.99,
  discountPercentage: 10.48,
  rating: 2.56,
  stock: 99,
  brand: 'Essence',
  thumbnail: '',
  images: [],
  availabilityStatus: 'In Stock',
);

const secondProduct = Product(
  id: 2,
  title: 'Eyeshadow Palette',
  description: 'A neutral palette.',
  category: 'beauty',
  price: 19.99,
  discountPercentage: 5,
  rating: 4.2,
  stock: 12,
  brand: 'Glamour',
  thumbnail: '',
  images: [],
  availabilityStatus: 'Low Stock',
);
