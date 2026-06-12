import 'package:flutter/foundation.dart';

/// Увеличить после создания/удаления кластера, чтобы [ClusterList] перезагрузил данные.
final ValueNotifier<int> clusterListRefreshTick = ValueNotifier<int>(0);
