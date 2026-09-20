/// The file format tiles are exported as. PNG is lossless (no quality
/// setting applies); JPG is lossy and takes a quality value from 1-100,
/// trading file size for image fidelity.
enum ExportFormat { png, jpg }

extension ExportFormatLabel on ExportFormat {
  String get label => this == ExportFormat.png ? 'PNG' : 'JPG';

  String get fileExtension => this == ExportFormat.png ? 'png' : 'jpg';
}
