import 'package:flutter_test/flutter_test.dart';
import 'package:bunnycc_perler/services/smart_import_service.dart';
import 'package:bunnycc_perler/models/models.dart';

void main() {
  group('SmartImportService', () {
    final service = SmartImportService.instance;

    group('CSV Parsing', () {
      test('parses standard CSV with Chinese headers', () {
        const csvContent = '''编码,名称,数量,品牌,分类
P01,白色,100,perler,基础色
P02,黑色,50,perler,基础色
P03,红色,75,perler,基础色''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items.length, 3);
        expect(result.items[0].beadColor.code, 'P01');
        expect(result.items[0].beadColor.name, '白色');
        expect(result.items[0].quantity, 100);
      });

      test('parses CSV with English headers', () {
        const csvContent = '''code,name,quantity,brand,hex
W01,White,100,perler,#FFFFFF
B01,Black,50,perler,#000000
R01,Red,75,perler,#FF0000''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items.length, 3);
        expect(result.items[0].beadColor.code, 'W01');
        expect(result.items[0].beadColor.hex, '#FFFFFF');
      });

      test('parses CSV with semicolon separator', () {
        const csvContent = '''编码;名称;数量
P01;白色;100
P02;黑色;50''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items.length, 2);
      });

      test('parses CSV with tab separator', () {
        const csvContent = '编码\t名称\t数量\nP01\t白色\t100\nP02\t黑色\t50';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items.length, 2);
      });

      test('handles CSV with RGB values', () {
        const csvContent = '''编码,名称,数量,R,G,B
P01,白色,100,255,255,255
P02,黑色,50,0,0,0
P03,红色,75,255,0,0''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items[0].beadColor.red, 255);
        expect(result.items[0].beadColor.green, 255);
        expect(result.items[0].beadColor.blue, 255);
      });

      test('handles empty CSV gracefully', () {
        const csvContent = '';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, false);
        expect(result.error, contains('空'));
      });
    });

    group('JSON Parsing', () {
      test('parses standard inventory JSON', () {
        const jsonContent = '''{
          "items": [
            {
              "id": "1",
              "beadColor": {
                "code": "P01",
                "name": "白色",
                "red": 255,
                "green": 255,
                "blue": 255,
                "brand": "perler"
              },
              "quantity": 100,
              "lastUpdated": "2024-01-01T00:00:00.000Z"
            }
          ],
          "lastUpdated": "2024-01-01T00:00:00.000Z"
        }''';

        final result = service.parseFile(jsonContent, 'test.json');

        expect(result.success, true);
        expect(result.items.length, 1);
        expect(result.items[0].beadColor.code, 'P01');
        expect(result.items[0].quantity, 100);
      });

      test('parses JSON array format', () {
        const jsonContent = '''[
          {
            "code": "P01",
            "name": "白色",
            "quantity": 100
          },
          {
            "code": "P02",
            "name": "黑色",
            "quantity": 50
          }
        ]''';

        final result = service.parseFile(jsonContent, 'test.json');

        expect(result.success, true);
        expect(result.items.length, 2);
      });

      test('parses JSON object with color entries', () {
        const jsonContent = '''{
          "P01": {
            "name": "白色",
            "quantity": 100,
            "hex": "#FFFFFF"
          },
          "P02": {
            "name": "黑色",
            "quantity": 50,
            "hex": "#000000"
          }
        }''';

        final result = service.parseFile(jsonContent, 'test.json');

        expect(result.success, true);
        expect(result.items.length, 2);
      });

      test('handles JSON with Chinese field names', () {
        const jsonContent = '''[
          {
            "编码": "P01",
            "名称": "白色",
            "数量": 100,
            "颜色值": "#FFFFFF"
          }
        ]''';

        final result = service.parseFile(jsonContent, 'test.json');

        expect(result.success, true);
        expect(result.items[0].beadColor.code, 'P01');
        expect(result.items[0].beadColor.hex, '#FFFFFF');
      });
    });

    group('Column Detection', () {
      test('detects columns in parsed result', () {
        const csvContent = '''编码,名称,数量
P01,白色,100
P02,黑色,50''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.detectedColumns.isNotEmpty, true);
      });
    });

    group('Manual Mapping', () {
      test('applies manual column mapping', () {
        const csvContent = '''A,B,C
P01,White,100
P02,Black,50''';

        final parseResult = service.parseFile(csvContent, 'test.csv');
        
        final mappings = [
          ColumnMapping(index: 0, type: ColumnType.code, headerName: 'A'),
          ColumnMapping(index: 1, type: ColumnType.name, headerName: 'B'),
          ColumnMapping(index: 2, type: ColumnType.quantity, headerName: 'C'),
        ];

        final result = service.parseWithMapping(parseResult.rawData, mappings);

        expect(result.success, true);
        expect(result.items.length, 3);
        expect(result.items[1].beadColor.code, 'P01');
        expect(result.items[1].quantity, 100);
      });
    });

    group('Edge Cases', () {
      test('handles CSV with extra whitespace', () {
        const csvContent = '''编码, 名称, 数量
  P01  ,  白色  ,  100  
P02,黑色,50''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items[0].beadColor.code, 'P01');
        expect(result.items[0].beadColor.name, '白色');
      });

      test('handles CSV with quoted fields', () {
        const csvContent = '''编码,名称,数量
"P01","白色,特别版",100
P02,黑色,50''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
      });

      test('handles mixed number formats in quantity', () {
        const csvContent = '''编码,名称,数量
P01,白色,1000
P02,黑色,500
P03,红色,200''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items[0].quantity, 1000);
        expect(result.items[1].quantity, 500);
        expect(result.items[2].quantity, 200);
      });

      test('detects header row correctly', () {
        const csvContent = '''编码,名称,数量
P01,白色,100
P02,黑色,50''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.headers, contains('编码'));
        expect(result.items.length, 2);
      });

      test('handles data without header row', () {
        const csvContent = '''P01,白色,100
P02,黑色,50''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.needsManualMapping, true);
      });
    });

    group('Brand Detection', () {
      test('parses brand names correctly', () {
        const csvContent = '''编码,名称,数量,品牌
P01,白色,100,perler
H01,白色,50,hama
A01,白色,75,artkal''';

        final result = service.parseFile(csvContent, 'test.csv');

        expect(result.success, true);
        expect(result.items[0].beadColor.brand, BeadBrand.perler);
        expect(result.items[1].beadColor.brand, BeadBrand.hama);
        expect(result.items[2].beadColor.brand, BeadBrand.artkal);
      });
    });
  });
}
