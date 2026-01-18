import 'package:flutter_test/flutter_test.dart';
import 'package:crymadx/services/websocket_service.dart';

void main() {
  group('TickerData', () {
    test('fromJson parses ticker correctly', () {
      final json = {
        's': 'BTCUSDT',
        'c': '45000.50',
        'p': '500.00',
        'P': '1.12',
        'h': '46000.00',
        'l': '44000.00',
        'v': '1000.5',
        'q': '45000000.00',
      };

      final ticker = TickerData.fromJson(json);

      expect(ticker.symbol, 'BTCUSDT');
      expect(ticker.lastPrice, 45000.50);
      expect(ticker.priceChange, 500.00);
      expect(ticker.priceChangePercent, 1.12);
      expect(ticker.highPrice, 46000.00);
      expect(ticker.lowPrice, 44000.00);
      expect(ticker.volume, 1000.5);
      expect(ticker.quoteVolume, 45000000.00);
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'symbol': 'ETHUSDT',
        'lastPrice': '3000.00',
        'priceChange': '50.00',
        'priceChangePercent': '1.70',
        'highPrice': '3100.00',
        'lowPrice': '2900.00',
        'volume': '500.0',
        'quoteVolume': '1500000.00',
      };

      final ticker = TickerData.fromJson(json);

      expect(ticker.symbol, 'ETHUSDT');
      expect(ticker.lastPrice, 3000.00);
      expect(ticker.priceChange, 50.00);
      expect(ticker.priceChangePercent, 1.70);
    });

    test('fromJson handles missing fields', () {
      final json = {'s': 'BTCUSDT'};

      final ticker = TickerData.fromJson(json);

      expect(ticker.symbol, 'BTCUSDT');
      expect(ticker.lastPrice, 0);
      expect(ticker.priceChange, 0);
    });

    test('toJson serializes correctly', () {
      final ticker = TickerData(
        symbol: 'BTCUSDT',
        lastPrice: 45000.50,
        priceChange: 500.00,
        priceChangePercent: 1.12,
        highPrice: 46000.00,
        lowPrice: 44000.00,
        volume: 1000.5,
        quoteVolume: 45000000.00,
      );

      final json = ticker.toJson();

      expect(json['symbol'], 'BTCUSDT');
      expect(json['lastPrice'], 45000.50);
      expect(json['priceChange'], 500.00);
    });
  });

  group('TradeData', () {
    test('fromJson parses trade correctly', () {
      final json = {
        's': 'BTCUSDT',
        't': 123456789,
        'p': '45000.50',
        'q': '0.5',
        'm': true,
        'T': 1640000000000,
      };

      final trade = TradeData.fromJson(json);

      expect(trade.symbol, 'BTCUSDT');
      expect(trade.tradeId, 123456789);
      expect(trade.price, 45000.50);
      expect(trade.quantity, 0.5);
      expect(trade.isBuyerMaker, true);
    });
  });

  group('DepthData', () {
    test('fromJson parses depth correctly', () {
      final json = {
        'bids': [
          ['44999.00', '1.5'],
          ['44998.00', '2.0'],
        ],
        'asks': [
          ['45001.00', '1.0'],
          ['45002.00', '0.5'],
        ],
        'lastUpdateId': 1000,
      };

      final depth = DepthData.fromJson(json, 'BTCUSDT');

      expect(depth.symbol, 'BTCUSDT');
      expect(depth.bids.length, 2);
      expect(depth.asks.length, 2);
      expect(depth.lastUpdateId, 1000);
    });
  });

  group('KlineData', () {
    test('fromJson parses kline correctly', () {
      final json = {
        'k': {
          't': 1640000000000,
          'T': 1640003600000,
          'o': '44000.00',
          'h': '46000.00',
          'l': '43500.00',
          'c': '45000.00',
          'v': '1000.5',
          'x': true,
        },
      };

      final kline = KlineData.fromJson(json, 'BTCUSDT');

      expect(kline.symbol, 'BTCUSDT');
      expect(kline.open, 44000.00);
      expect(kline.high, 46000.00);
      expect(kline.low, 43500.00);
      expect(kline.close, 45000.00);
      expect(kline.volume, 1000.5);
      expect(kline.isClosed, true);
    });
  });

  group('WebSocketService', () {
    test('singleton instance works', () {
      final service1 = WebSocketService();
      final service2 = WebSocketService();

      expect(identical(service1, service2), true);
    });

    test('wsService global instance is available', () {
      expect(wsService, isNotNull);
      expect(wsService, isA<WebSocketService>());
    });

    test('latestTickers returns empty map initially', () {
      expect(wsService.latestTickers, isEmpty);
    });

    test('getTicker returns null for unknown symbol', () {
      expect(wsService.getTicker('UNKNOWN'), isNull);
    });
  });
}
