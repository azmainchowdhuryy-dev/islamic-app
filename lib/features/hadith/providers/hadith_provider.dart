import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hadith.dart';
import '../repositories/hadith_repository.dart';

final hadithRepositoryProvider = Provider((ref) => HadithRepository());

final hadithListProvider = FutureProvider<List<Hadith>>(
    (ref) => ref.read(hadithRepositoryProvider).loadVerified());
