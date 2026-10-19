//
//  MenuBarImageFactory.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit

/// Рисует картинку для меню-бара через Core Text.
enum MenuBarImageFactory {
    /// SF Symbol для стиля «только иконка».
    static let fallbackSymbolName = "gauge.with.dots.needle.33percent"

    /// Высота картинки.
    private static let imageHeight: CGFloat = 22
    /// Отступ между колонками в двухстрочном стиле.
    private static let columnSpacing: CGFloat = 7
    /// Отступ между метриками в стиле «иконки и значения».
    private static let itemSpacing: CGFloat = 8
    /// Отступ между иконкой и значением.
    private static let iconTextSpacing: CGFloat = 2

    /// Шрифт подписи над значением.
    private static let captionAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 8, weight: .medium),
        .foregroundColor: NSColor.black,
    ]
    /// Шрифт значения в двухстрочном стиле.
    private static let twoRowValueAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: NSColor.black,
    ]
    /// Шрифт значения рядом с иконкой.
    private static let iconValueAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.black,
    ]

    /// Подписи метрик, свёрстанные один раз.
    private static let captions = MenuBarMetric.allCases.reduce(into: [MenuBarMetric: NSAttributedString]()) {
        $0[$1] = NSAttributedString(string: $1.caption, attributes: captionAttributes)
    }
    /// Минимальная ширина колонки в двухстрочном стиле — чтобы иконка не дёргалась.
    private static let twoRowColumnWidths = MenuBarMetric.allCases.reduce(into: [MenuBarMetric: CGFloat]()) {
        let widest = NSAttributedString(string: $1.widestSampleValue, attributes: twoRowValueAttributes)
        $0[$1] = ceil(max(captions[$1]?.size().width ?? 0, widest.size().width))
    }
    /// Минимальная ширина значения рядом с иконкой.
    private static let iconValueWidths = MenuBarMetric.allCases.reduce(into: [MenuBarMetric: CGFloat]()) {
        $0[$1] = ceil(NSAttributedString(string: $1.widestSampleValue, attributes: iconValueAttributes).size().width)
    }
    /// Иконки метрик.
    private static let symbolImages = MenuBarMetric.allCases.reduce(into: [MenuBarMetric: NSImage]()) {
        $0[$1] = NSImage(systemSymbolName: $1.symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium))
    }

    /// Шаблонная картинка для стиля; `nil` — показать `fallbackSymbolName`.
    static func makeImage(style: MenuBarStyle, readings: [MenuBarReading]) -> NSImage? {
        guard !readings.isEmpty else { return nil }
        let image: NSImage? = switch style {
        case .compact: makeTwoRowImage(readings)
        case .iconsAndValues: makeIconsAndValuesImage(readings)
        case .iconOnly: nil
        }
        image?.isTemplate = true
        return image
    }

    /// Подпись сверху, значение снизу.
    private static func makeTwoRowImage(_ readings: [MenuBarReading]) -> NSImage {
        let columns = readings.map { reading in
            let value = NSAttributedString(string: reading.value, attributes: twoRowValueAttributes)
            let valueSize = value.size()
            let width = max(twoRowColumnWidths[reading.metric] ?? 0, ceil(valueSize.width))
            return (caption: captions[reading.metric], value: value, valueSize: valueSize, width: width)
        }
        return drawColumns(widths: columns.map(\.width), spacing: columnSpacing) { index, x in
            let column = columns[index]
            if let caption = column.caption {
                caption.draw(at: NSPoint(x: x + (column.width - caption.size().width) / 2, y: 0))
            }
            column.value.draw(at: NSPoint(
                x: x + (column.width - column.valueSize.width) / 2,
                y: imageHeight - column.valueSize.height
            ))
        }
    }

    /// Иконка и значение в одну строку.
    private static func makeIconsAndValuesImage(_ readings: [MenuBarReading]) -> NSImage {
        let items = readings.map { reading in
            let symbol = symbolImages[reading.metric]
            let value = NSAttributedString(string: reading.value, attributes: iconValueAttributes)
            let valueSize = value.size()
            let symbolWidth = symbol.map { ceil($0.size.width) + iconTextSpacing } ?? 0
            let textWidth = max(iconValueWidths[reading.metric] ?? 0, ceil(valueSize.width))
            return (symbol: symbol, value: value, valueSize: valueSize, symbolWidth: symbolWidth, width: symbolWidth + textWidth)
        }
        return drawColumns(widths: items.map(\.width), spacing: itemSpacing) { index, x in
            let item = items[index]
            if let symbol = item.symbol {
                let size = symbol.size
                symbol.draw(in: NSRect(x: x, y: (imageHeight - size.height) / 2, width: size.width, height: size.height))
            }
            item.value.draw(at: NSPoint(x: x + item.symbolWidth, y: (imageHeight - item.valueSize.height) / 2))
        }
    }

    /// Картинка из колонок заданной ширины; `drawColumn` рисует колонку по индексу и X.
    private static func drawColumns(
        widths: [CGFloat],
        spacing: CGFloat,
        drawColumn: @escaping (_ index: Int, _ x: CGFloat) -> Void
    ) -> NSImage {
        let totalWidth = widths.reduce(0, +) + spacing * CGFloat(widths.count - 1)
        return NSImage(size: NSSize(width: totalWidth, height: imageHeight), flipped: true) { _ in
            var x: CGFloat = 0
            for (index, width) in widths.enumerated() {
                drawColumn(index, x)
                x += width + spacing
            }
            return true
        }
    }
}

private extension MenuBarMetric {
    /// Самое широкое возможное значение — по нему резервируется ширина.
    var widestSampleValue: String {
        switch self {
        case .cpuLoad, .memory: MetricFormatter.percent(1)
        case .cpuTemperature, .gpuTemperature: MetricFormatter.shortTemperature(100)
        case .fanSpeed: MetricFormatter.shortFanSpeed(8_800)
        }
    }
}
