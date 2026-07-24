import 'dart:convert';
import 'dart:io';

import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service responsible for generating a PDF file from document blocks.
///
/// Supports the most common block types (header, paragraph, blockquote,
/// code, list, image, divider, math, table, checkbox, chat, box).
/// Unsupported or complex block types are silently skipped.
class PdfExportService {
  /// Generates a PDF from a Barruu document.
  ///
  /// [docDir] – directory of the document (used to resolve local image paths).
  /// [documentTitle] – title shown in the PDF header.
  /// [pages] – ordered list of document pages.
  /// [getPageBlocks] – callback that returns blocks for a given page ID.
  ///
  /// Returns the generated [File] on success, or `null` on failure.
  Future<File?> exportDocumentAsPdf(
    Directory docDir,
    String documentTitle,
    List<DocumentPage> pages,
    Future<List<Block>> Function(String pageId) getPageBlocks,
  ) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();
      final fontMono = await PdfGoogleFonts.jetBrainsMonoRegular();

      bool hasAddedPages = false;
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final blocks = await getPageBlocks(page.id);

        // Build PDF widgets for each block.
        final List<pw.Widget> widgets = [];

        // Page title (for multi-page documents).
        if (pages.length > 1) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                page.displayTitle,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 18,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ),
          );
        }

        for (final block in blocks) {
          final widget = await _buildBlockWidget(
            block,
            docDir,
            font,
            fontBold,
            fontMono,
          );
          if (widget != null) {
            widgets.add(widget);
            widgets.add(pw.SizedBox(height: 8));
          }
        }

        if (widgets.isEmpty) continue;

        hasAddedPages = true;
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            header: (ctx) => _buildHeader(ctx, documentTitle, fontBold),
            footer: (ctx) => _buildFooter(ctx, font),
            build: (ctx) => widgets,
          ),
        );
      }

      // Ensure at least one page exists.
      if (!hasAddedPages) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (ctx) => pw.Center(
              child: pw.Text(
                documentTitle,
                style: pw.TextStyle(font: fontBold, fontSize: 24),
              ),
            ),
          ),
        );
      }

      final tempDir = await getTemporaryDirectory();
      final sanitized = documentTitle
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .trim();
      final fileName =
          '${sanitized.isEmpty ? 'document' : sanitized}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(await pdf.save());
      logger.i('PDF exported to ${pdfFile.path}');
      return pdfFile;
    } catch (e, stackTrace) {
      logger.e('PDF export failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Page header / footer
  // ---------------------------------------------------------------------------

  pw.Widget _buildHeader(
    pw.Context ctx,
    String title,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 10,
            color: PdfColors.blueGrey600,
          ),
        ),
        pw.Divider(color: PdfColors.blueGrey200, thickness: 0.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context ctx, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.blueGrey200, thickness: 0.5),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.blueGrey400,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Block dispatcher
  // ---------------------------------------------------------------------------

  Future<pw.Widget?> _buildBlockWidget(
    Block block,
    Directory docDir,
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontMono,
  ) async {
    Map<String, dynamic> content = {};
    try {
      if (block.content.trim().isNotEmpty) {
        content = jsonDecode(block.content) as Map<String, dynamic>;
      }
    } catch (_) {
      // If content is plain text, wrap it.
      content = {'content': block.content};
    }

    switch (block.type) {
      case BlockType.header:
        return _buildHeaderBlock(content, block.style, fontBold);
      case BlockType.paragraph:
        return _buildParagraphBlock(content, block.style, font);
      case BlockType.blockquote:
        return _buildBlockquoteBlock(content, font);
      case BlockType.code:
        return _buildCodeBlock(content, block.style, fontMono);
      case BlockType.list:
        return _buildListBlock(content, block.style, font);
      case BlockType.image:
        return await _buildImageBlock(content, docDir, font);
      case BlockType.divider:
        return _buildDividerBlock();
      case BlockType.math:
        return _buildMathBlock(content, font, fontMono);
      case BlockType.table:
        return _buildTableBlock(content, font, fontBold);
      case BlockType.checkbox:
        return _buildCheckboxBlock(content, font);
      case BlockType.chat:
        return _buildChatBlock(content, font);
      case BlockType.box:
        return _buildBoxBlock(content, font, fontBold);
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Individual block builders
  // ---------------------------------------------------------------------------

  pw.Widget _buildHeaderBlock(
    Map<String, dynamic> content,
    BlockStyle style,
    pw.Font fontBold,
  ) {
    final text = (content['content'] as String? ?? '').trim();
    if (text.isEmpty) return pw.SizedBox();

    final headerStyle = style.headerStyle ?? 'h1';
    final double fontSize;
    switch (headerStyle) {
      case 'h1':
        fontSize = 26;
        break;
      case 'h2':
        fontSize = 22;
        break;
      case 'h3':
        fontSize = 18;
        break;
      default:
        fontSize = 22;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: fontSize,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  pw.Widget _buildParagraphBlock(
    Map<String, dynamic> content,
    BlockStyle style,
    pw.Font font,
  ) {
    final text = (content['content'] as String? ?? '').trim();
    if (text.isEmpty) return pw.SizedBox();

    return pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 2),
    );
  }

  pw.Widget _buildBlockquoteBlock(
    Map<String, dynamic> content,
    pw.Font font,
  ) {
    final text = (content['content'] as String? ?? '').trim();
    final author = (content['author'] as String? ?? '').trim();

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blueGrey400, width: 3),
        ),
        color: PdfColors.blueGrey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (text.isNotEmpty)
            pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.blueGrey700,
              ),
            ),
          if (author.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '— $author',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.blueGrey500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCodeBlock(
    Map<String, dynamic> content,
    BlockStyle style,
    pw.Font fontMono,
  ) {
    final text = (content['content'] as String? ?? '').trim();
    if (text.isEmpty) return pw.SizedBox();
    final language = style.language ?? '';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey900,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                language,
                style: pw.TextStyle(
                  font: fontMono,
                  fontSize: 8,
                  color: PdfColors.grey400,
                ),
              ),
            ),
          pw.Text(
            text,
            style: pw.TextStyle(
              font: fontMono,
              fontSize: 10,
              color: PdfColors.green200,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildListBlock(
    Map<String, dynamic> content,
    BlockStyle style,
    pw.Font font,
  ) {
    final header = (content['header'] as String? ?? '').trim();
    final rawItems = content['items'];
    final items = rawItems is List
        ? rawItems.map((e) => e.toString()).toList()
        : <String>[];

    if (items.isEmpty && header.isEmpty) return pw.SizedBox();

    final isOrdered = style.listType == 'ordered';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ...items.asMap().entries.map((entry) {
          final bullet = isOrdered ? '${entry.key + 1}.' : '•';
          return pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(
                    bullet,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    entry.value,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<pw.Widget?> _buildImageBlock(
    Map<String, dynamic> content,
    Directory docDir,
    pw.Font font,
  ) async {
    final caption = (content['caption'] as String? ?? '').trim();
    final rawImages = content['images'];
    final images =
        rawImages is List ? List<dynamic>.from(rawImages) : <dynamic>[];

    if (images.isEmpty) {
      return caption.isNotEmpty
          ? pw.Text(caption,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey500))
          : null;
    }

    final firstImage = images.first;
    final imagePath = firstImage is Map
        ? (firstImage['path'] as String? ?? '')
        : firstImage.toString();

    pw.ImageProvider? imageProvider;
    try {
      if (imagePath.startsWith('http://') ||
          imagePath.startsWith('https://')) {
        imageProvider = await networkImage(imagePath);
      } else {
        // Resolve relative path against the document directory.
        final resolvedPath = imagePath.startsWith('/')
            ? imagePath
            : '${docDir.path}/$imagePath';
        final file = File(resolvedPath);
        if (await file.exists()) {
          imageProvider = pw.MemoryImage(await file.readAsBytes());
        }
      }
    } catch (_) {
      imageProvider = null;
    }

    if (imageProvider == null) return null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 4,
          verticalRadius: 4,
          child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
        ),
        if (caption.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              caption,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildDividerBlock() {
    return pw.Divider(color: PdfColors.blueGrey300, thickness: 0.8);
  }

  pw.Widget _buildMathBlock(
    Map<String, dynamic> content,
    pw.Font font,
    pw.Font fontMono,
  ) {
    final latex = (content['latex'] as String? ?? '').trim();
    final caption = (content['caption'] as String? ?? '').trim();
    if (latex.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.blueGrey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            latex,
            style: pw.TextStyle(font: fontMono, fontSize: 11),
            textAlign: pw.TextAlign.center,
          ),
          if (caption.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                caption,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.blueGrey500),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildTableBlock(
    Map<String, dynamic> content,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final header = (content['header'] as String? ?? '').trim();
    final rawRows = content['rows'];
    final rows = rawRows is List
        ? rawRows
            .map((r) =>
                r is List ? r.map((c) => c.toString()).toList() : <String>[])
            .toList()
        : <List<String>>[];

    if (rows.isEmpty) return pw.SizedBox();

    // Determine column count.
    final colCount =
        rows.fold<int>(0, (max, r) => r.length > max ? r.length : max);
    if (colCount == 0) return pw.SizedBox();

    final tableRows = rows.asMap().entries.map((entry) {
      final isFirstRow = entry.key == 0;
      final cells = entry.value;
      return pw.TableRow(
        decoration: isFirstRow
            ? const pw.BoxDecoration(color: PdfColors.blueGrey100)
            : null,
        children: List.generate(colCount, (ci) {
          final cellText =
              ci < cells.length ? cells[ci] : '';
          return pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              cellText,
              style: pw.TextStyle(
                font: isFirstRow ? fontBold : font,
                fontSize: 10,
              ),
            ),
          );
        }),
      );
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 12),
            ),
          ),
        pw.Table(
          border: pw.TableBorder.all(
              color: PdfColors.blueGrey200, width: 0.5),
          children: tableRows,
        ),
      ],
    );
  }

  pw.Widget _buildCheckboxBlock(
    Map<String, dynamic> content,
    pw.Font font,
  ) {
    final header = (content['header'] as String? ?? '').trim();
    final rawItems = content['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList()
        : <Map<String, dynamic>>[];

    if (items.isEmpty && header.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold),
            ),
          ),
        ...items.map((item) {
          final checked = item['checked'] as bool? ?? false;
          final label = (item['label'] as String? ??
                  item['text'] as String? ??
                  '')
              .trim();
          return pw.Padding(
            padding:
                const pw.EdgeInsets.only(left: 8, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  margin:
                      const pw.EdgeInsets.only(right: 6),
                  decoration: pw.BoxDecoration(
                    border:
                        pw.Border.all(color: PdfColors.blueGrey400),
                    color: checked
                        ? PdfColors.blue600
                        : PdfColors.white,
                  ),
                  child: checked
                      ? pw.Center(
                          child: pw.Text(
                            '✓',
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                color: PdfColors.white),
                          ),
                        )
                      : null,
                ),
                pw.Expanded(
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(font: font, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildChatBlock(
    Map<String, dynamic> content,
    pw.Font font,
  ) {
    final message = (content['message'] as String? ?? '').trim();
    final profile = (content['profileName'] as String? ?? '').trim();
    if (message.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.lightBlue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (profile.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                profile,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800),
              ),
            ),
          pw.Text(message,
              style: pw.TextStyle(font: font, fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _buildBoxBlock(
    Map<String, dynamic> content,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final text = (content['text'] as String? ?? '').trim();
    if (text.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.blueGrey50,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    );
  }
}
