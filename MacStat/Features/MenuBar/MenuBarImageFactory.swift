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

    /// Шрифт подписи над значением.
    private static let captionAttributes = textAttributes(NSFont.systemFont(ofSize: 8, weight: .medium))
    /// Шрифт значения в двухстрочном стиле.
    private static let twoRowValueAttributes = textAttributes(NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold))
    /// Шрифт значений в комбинированном столбце.
    private static let stackedValueAttributes = textAttributes(NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold))
    /// Шрифт значения рядом с иконкой.
    private static let iconValueAttributes = textAttributes(NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium))

    /// Подписи метрик, свёрстанные один раз.
    private static let captions = SystemMetric.allCases.reduce(into: [SystemMetric: NSAttributedString]()) {
        $0[$1] = NSAttributedString(string: $1.menuBarCaption, attributes: captionAttributes)
    }
    /// Минимальная ширина колонки в двухстрочном стиле — чтобы значок не дёргался.
    private static let twoRowColumnWidths = SystemMetric.allCases.reduce(into: [SystemMetric: CGFloat]()) {
        $0[$1] = max(captions[$1]?.size().width ?? 0, widestValueWidth(of: $1, attributes: twoRowValueAttributes))
    }
    /// Минимальная ширина значения в комбинированном столбце.
    private static let stackedValueWidths = SystemMetric.allCases.reduce(into: [SystemMetric: CGFloat]()) {
        $0[$1] = widestValueWidth(of: $1, attributes: stackedValueAttributes)
    }
    /// Минимальная ширина значения рядом с иконкой.
    private static let iconValueWidths = SystemMetric.allCases.reduce(into: [SystemMetric: CGFloat]()) {
        $0[$1] = widestValueWidth(of: $1, attributes: iconValueAttributes)
    }
    /// Иконки метрик.
    private static let symbolImages = SystemMetric.allCases.reduce(into: [SystemMetric: NSImage]()) {
        $0[$1] = NSImage(systemSymbolName: $1.symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium))
    }

    /// Шаблонная картинка для стиля; `nil` — показать `fallbackSymbolName`.
    static func makeImage(style: MenuBarStyle, density: MenuBarDensity, readings: [MenuBarReading]) -> NSImage? {
        guard !readings.isEmpty else { return nil }
        let image: NSImage? = switch style {
        case .twoRows: makeTwoRowImage(readings, density: density)
        case .stacked: makeStackedImage(readings)
        case .iconsAndValues: makeIconsAndValuesImage(readings, density: density)
        case .iconOnly: nil
        }
        image?.isTemplate = true
        return image
    }

    /// Колонки «подпись сверху, значение снизу».
    private static func makeTwoRowImage(_ readings: [MenuBarReading], density: MenuBarDensity) -> NSImage {
        let columns = readings.map { reading in
            let value = NSAttributedString(string: reading.value, attributes: twoRowValueAttributes)
            let valueSize = value.size()
            let width = max(twoRowColumnWidths[reading.metric] ?? 0, ceil(valueSize.width))
            return (caption: captions[reading.metric], value: value, valueSize: valueSize, width: width)
        }
        return drawColumns(widths: columns.map(\.width), spacing: density.columnSpacing) { index, x in
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

    /// Один столбец: первое значение сверху, второе снизу, без подписей.
    private static func makeStackedImage(_ readings: [MenuBarReading]) -> NSImage {
        let rows = readings.prefix(2).map { reading in
            let value = NSAttributedString(string: reading.value, attributes: stackedValueAttributes)
            return (value: value, size: value.size(), reservedWidth: stackedValueWidths[reading.metric] ?? 0)
        }
        let width = rows.map { max($0.reservedWidth, ceil($0.size.width)) }.max() ?? 0
        return drawColumns(widths: [width], spacing: 0) { _, x in
            for (index, row) in rows.enumerated() {
                let y = index == 0 ? 0 : imageHeight - row.size.height
                row.value.draw(at: NSPoint(x: x + (width - row.size.width) / 2, y: y))
            }
        }
    }

    /// Иконка и значение в одну строку.
    private static func makeIconsAndValuesImage(_ readings: [MenuBarReading], density: MenuBarDensity) -> NSImage {
        let items = readings.map { reading in
            let symbol = symbolImages[reading.metric]
            let value = NSAttributedString(string: reading.value, attributes: iconValueAttributes)
            let valueSize = value.size()
            let symbolWidth = symbol.map { ceil($0.size.width) + density.iconTextSpacing } ?? 0
            let textWidth = max(iconValueWidths[reading.metric] ?? 0, ceil(valueSize.width))
            return (symbol: symbol, value: value, valueSize: valueSize, symbolWidth: symbolWidth, width: symbolWidth + textWidth)
        }
        return drawColumns(widths: items.map(\.width), spacing: density.itemSpacing) { index, x in
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

    /// Атрибуты текста для шаблонной картинки.
    private static func textAttributes(_ font: NSFont) -> [NSAttributedString.Key: Any] {
        [.font: font, .foregroundColor: NSColor.black]
    }

    /// Ширина самого широкого значения метрики.
    private static func widestValueWidth(of metric: SystemMetric, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        ceil(NSAttributedString(string: metric.widestMenuBarText, attributes: attributes).size().width)
    }
}
