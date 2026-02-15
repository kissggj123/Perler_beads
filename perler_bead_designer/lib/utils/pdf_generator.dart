import 'dart:io';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/bead_design.dart';
import '../models/bead_color.dart';

enum PdfPageSize {
  a4,
  a3,
  letter,
  legal,
}

enum PdfOrientation {
  portrait,
  landscape,
}

class PdfGenerator {
  static const double _gridLineWidth = 0.5;
  static const double _margin = 20.0;

  static PdfPageFormat _getPageFormat(PdfPageSize pageSize, PdfOrientation orientation) {
    PdfPageFormat format;
    switch (pageSize) {
      case PdfPageSize.a4:
        format = PdfPageFormat.a4;
        break;
      case PdfPageSize.a3:
        format = PdfPageFormat.a3;
        break;
      case PdfPageSize.letter:
        format = PdfPageFormat.letter;
        break;
      case PdfPageSize.legal:
        format = PdfPageFormat.legal;
        break;
    }

    if (orientation == PdfOrientation.landscape) {
      format = format.landscape;
    }

    return format;
  }

  static Future<File> generateDesignPdf(
    BeadDesign design, {
    PdfPageSize pageSize = PdfPageSize.a4,
    PdfOrientation orientation = PdfOrientation.portrait,
    bool showGrid = true,
    bool showCoordinates = true,
    String? customPath,
  }) async {
    final pdf = pw.Document();

    final pageFormat = _getPageFormat(pageSize, orientation);
    final availableWidth = pageFormat.availableWidth - _margin * 2;
    final availableHeight = pageFormat.availableHeight - _margin * 2;

    final beadSize = _calculateBeadSize(
      design.width,
      design.height,
      availableWidth,
      availableHeight,
      showCoordinates,
    );

    final pages = _splitDesignIntoPages(
      design,
      availableWidth,
      availableHeight,
      beadSize,
      showCoordinates,
    );

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageData = pages[pageIndex];
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(_margin),
          header: (context) => _buildHeader(design, pageIndex + 1, pages.length),
          build: (context) => [
            pw.SizedBox(height: 10),
            _buildDesignGrid(
              pageData,
              beadSize,
              showGrid,
              showCoordinates,
            ),
            pw.SizedBox(height: 20),
            _buildLegend(pageData.usedColors),
          ],
          footer: (context) => _buildFooter(context, design),
        ),
      );
    }

    final file = await _savePdf(pdf, design.name, customPath);
    return file;
  }

  static Future<File> generateMaterialListPdf(
    BeadDesign design, {
    PdfPageSize pageSize = PdfPageSize.a4,
    PdfOrientation orientation = PdfOrientation.portrait,
    String? customPath,
  }) async {
    final pdf = pw.Document();
    final pageFormat = _getPageFormat(pageSize, orientation);

    final beadCounts = design.getBeadCountsWithColors();
    final sortedColors = beadCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(_margin),
        header: (context) => _buildMaterialListHeader(design),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummaryTable(design, beadCounts),
          pw.SizedBox(height: 20),
          _buildMaterialTable(sortedColors),
        ],
        footer: (context) => _buildFooter(context, design),
      ),
    );

    final file = await _savePdf(pdf, '${design.name}_材料清单', customPath);
    return file;
  }

  static double _calculateBeadSize(
    int gridWidth,
    int gridHeight,
    double availableWidth,
    double availableHeight,
    bool showCoordinates,
  ) {
    final coordinateOffset = showCoordinates ? 30.0 : 0.0;
    final effectiveWidth = availableWidth - coordinateOffset;
    final effectiveHeight = availableHeight - coordinateOffset - 100;

    final beadSizeByWidth = effectiveWidth / gridWidth;
    final beadSizeByHeight = effectiveHeight / gridHeight;

    return math.min(beadSizeByWidth, beadSizeByHeight).clamp(5.0, 15.0);
  }

  static List<_PageData> _splitDesignIntoPages(
    BeadDesign design,
    double availableWidth,
    double availableHeight,
    double beadSize,
    bool showCoordinates,
  ) {
    final coordinateOffset = showCoordinates ? 30.0 : 0.0;
    final effectiveWidth = availableWidth - coordinateOffset;
    final effectiveHeight = availableHeight - coordinateOffset - 100;

    final beadsPerRow = (effectiveWidth / beadSize).floor();
    final beadsPerColumn = (effectiveHeight / beadSize).floor();

    if (design.width <= beadsPerRow && design.height <= beadsPerColumn) {
      return [_PageData(
        grid: design.grid,
        startRow: 0,
        startCol: 0,
        usedColors: design.getUsedColors(),
      )];
    }

    final pages = <_PageData>[];

    for (int rowStart = 0; rowStart < design.height; rowStart += beadsPerColumn) {
      for (int colStart = 0; colStart < design.width; colStart += beadsPerRow) {
        final rowEnd = math.min(rowStart + beadsPerColumn, design.height);
        final colEnd = math.min(colStart + beadsPerRow, design.width);

        final pageGrid = <List<BeadColor?>>[];
        final usedColors = <String, BeadColor>{};

        for (int y = rowStart; y < rowEnd; y++) {
          final row = <BeadColor?>[];
          for (int x = colStart; x < colEnd; x++) {
            final bead = design.grid[y][x];
            row.add(bead);
            if (bead != null) {
              usedColors[bead.code] = bead;
            }
          }
          pageGrid.add(row);
        }

        pages.add(_PageData(
          grid: pageGrid,
          startRow: rowStart,
          startCol: colStart,
          usedColors: usedColors.values.toList(),
        ));
      }
    }

    return pages;
  }

  static pw.Widget _buildHeader(BeadDesign design, int currentPage, int totalPages) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            design.name,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '第 $currentPage / $totalPages 页',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMaterialListHeader(BeadDesign design) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${design.name} - 材料清单',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '生成日期: ${DateTime.now().toString().split('.')[0]}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDesignGrid(
    _PageData pageData,
    double beadSize,
    bool showGrid,
    bool showCoordinates,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (showCoordinates)
          pw.Container(
            width: 25,
            child: pw.Column(
              children: [
                pw.SizedBox(height: 25),
                ...List.generate(pageData.grid.length, (index) {
                  return pw.Container(
                    height: beadSize,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '${pageData.startRow + index}',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  );
                }),
              ],
            ),
          ),
        pw.Expanded(
          child: pw.Column(
            children: [
              if (showCoordinates)
                pw.Container(
                  height: 25,
                  child: pw.Row(
                    children: List.generate(
                      pageData.grid.isEmpty ? 0 : pageData.grid.first.length,
                      (index) => pw.Container(
                        width: beadSize,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '${pageData.startCol + index}',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                  ),
                ),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Column(
                  children: pageData.grid.map((row) {
                    return pw.Row(
                      children: row.map((bead) {
                        return pw.Container(
                          width: beadSize,
                          height: beadSize,
                          decoration: pw.BoxDecoration(
                            color: bead != null
                                ? PdfColor(
                                    bead.red / 255,
                                    bead.green / 255,
                                    bead.blue / 255,
                                  )
                                : PdfColors.white,
                            border: showGrid
                                ? pw.Border.all(
                                    color: PdfColors.grey400,
                                    width: _gridLineWidth,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegend(List<BeadColor> colors) {
    if (colors.isEmpty) {
      return pw.SizedBox();
    }

    final sortedColors = List<BeadColor>.from(colors)
      ..sort((a, b) => a.name.compareTo(b.name));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '颜色图例',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 5,
          children: sortedColors.map((color) {
            return pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 15,
                  height: 15,
                  decoration: pw.BoxDecoration(
                    color: PdfColor(
                      color.red / 255,
                      color.green / 255,
                      color.blue / 255,
                    ),
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  '${color.code} - ${color.name}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryTable(
    BeadDesign design,
    Map<BeadColor, int> beadCounts,
  ) {
    final totalBeads = beadCounts.values.fold(0, (sum, count) => sum + count);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('设计名称', isHeader: true),
            _buildTableCell(design.name),
            _buildTableCell('尺寸', isHeader: true),
            _buildTableCell('${design.width} × ${design.height}'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('总拼豆数', isHeader: true),
            _buildTableCell('$totalBeads'),
            _buildTableCell('颜色种类', isHeader: true),
            _buildTableCell('${beadCounts.length}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMaterialTable(List<MapEntry<BeadColor, int>> sortedColors) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('颜色代码', isHeader: true, width: 80),
            _buildTableCell('颜色名称', isHeader: true, width: 120),
            _buildTableCell('颜色', isHeader: true, width: 50),
            _buildTableCell('数量', isHeader: true, width: 60),
            _buildTableCell('占比', isHeader: true, width: 60),
          ],
        ),
        ...sortedColors.map((entry) {
          final color = entry.key;
          final count = entry.value;
          final total = sortedColors.fold(0, (sum, e) => sum + e.value);
          final percentage = (count / total * 100).toStringAsFixed(1);

          return pw.TableRow(
            children: [
              _buildTableCell(color.code, width: 80),
              _buildTableCell(color.name, width: 120),
              pw.Container(
                width: 50,
                height: 25,
                alignment: pw.Alignment.center,
                child: pw.Container(
                  width: 20,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColor(
                      color.red / 255,
                      color.green / 255,
                      color.blue / 255,
                    ),
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                ),
              ),
              _buildTableCell('$count', width: 60),
              _buildTableCell('$percentage%', width: 60),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, double? width}) {
    return pw.Container(
      width: width,
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, BeadDesign design) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Perler Bead Designer',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            '创建于: ${design.createdAt.toString().split('.')[0]}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> _savePdf(pw.Document pdf, String name, String? customPath) async {
    final bytes = await pdf.save();

    String filePath;
    if (customPath != null) {
      filePath = customPath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '_');
      filePath = '${directory.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
}

class _PageData {
  final List<List<BeadColor?>> grid;
  final int startRow;
  final int startCol;
  final List<BeadColor> usedColors;

  _PageData({
    required this.grid,
    required this.startRow,
    required this.startCol,
    required this.usedColors,
  });
}
