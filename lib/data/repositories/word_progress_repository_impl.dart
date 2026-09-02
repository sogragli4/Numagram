import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/word_progress_model.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';
import 'package:nonogram_daily/domain/repositories/word_progress_repository.dart';

class WordProgressRepositoryImpl implements WordProgressRepository {
  const WordProgressRepositoryImpl(this._dataSource);

  final IsarLocalDataSource _dataSource;

  @override
  Future<WordProgress> getProgress() async =>
      (await _dataSource.getWordProgress()).toEntity();

  @override
  Future<void> updateProgress(WordProgress progress) =>
      _dataSource.saveWordProgress(WordProgressModel.fromEntity(progress));
}
