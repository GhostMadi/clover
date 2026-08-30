import 'package:clover/feature/currencies/data/models/currency_model.dart';

abstract class CurrenciesRepository {
  Future<List<CurrencyModel>> fetchActiveOrdered();
}
