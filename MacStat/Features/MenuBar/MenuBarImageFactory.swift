//
//  MenuBarImageFactory.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import AppKit

/// Рисует картинку для меню-бара через Core Text.
enum MenuBarImageFactory {
    /// Отмеренный элемент значка.
    private struct Cell {
        /// Ширина элемента.
        let width: CGFloat
        /// Рисует элемент от левого края `x`.
        let draw: (_ x: CGFloat) -> Void
    }

    /// SF Symbol для стиля «только иконка».
    static let fallbackSymbolName = "gauge.with.dots.needle.33percent"

    /// Высота картинки.
    private static let imageHeight: CGFloat = 22

    /// Шрифт подписи над значением.
    private static let captionAttributes = textAttributes(NSFont.systemFont(ofSize: 8, weight: .medium))
    /// Шрифт значения в двухстрочном стиле.
    private static let twoRowValueAttributes = textAttributes(NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold))
    /// Шрифт значений в столбце из двух метрик.
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
    /// Минимальная ширина значения в столбце из двух метрик.
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

    /// Шаблонная картинка из элементов; `nil` — показать `fallbackSymbolName`.
    static func makeImage(style: MenuBarStyle, density: MenuBarDensity, columns: [MenuBarColumn]) -> NSImage? {
        guard !columns.isEmpty else { return nil }
        let spacing: CGFloat
        let makeSingleCell: (MenuBarReading) -> Cell
        switch style {
        case .twoRows:
            spacing = density.columnSpacing
            makeSingleCell = makeTwoRowCell
        case .iconsAndValues:
            spacing = density.itemSpacing
            makeSingleCell = { makeIconAndValueCell($0, density: density) }
        case .iconOnly:
            return nil
        }
        let cells = columns.map { column in
            switch column {
            case .single(let reading): makeSingleCell(reading)
            case .stacked(let top, let bottom): makeStackedCell(top: top, bottom: bottom)
            }
        }
        let image = drawCells(cells, spacing: spacing)
        image.isTemplate = true
        return image
    }

    /// Подпись сверху, значение снизу.
    private static func makeTwoRowCell(_ reading: MenuBarReading) -> Cell {
        let caption = captions[reading.metric]
        let value = NSAttributedString(string: reading.value, attributes: twoRowValueAttributes)
        let valueSize = value.size()
        let width = max(twoRowColumnWidths[reading.metric] ?? 0, ceil(valueSize.width))
        return Cell(width: width) { x in
            if let caption {
                caption.draw(at: NSPoint(x: x + (width - caption.size().width) / 2, y: 0))
            }
            value.draw(at: NSPoint(x: x + (width - valueSize.width) / 2, y: imageHeight - valueSize.height))
        }
    }

    /// Два значения друг над другом без подписей.
    private static func makeStackedCell(top: MenuBarReading, bottom: MenuBarReading) -> Cell {
        let rows = [top, bottom].map { reading in
            let value = NSAttributedString(string: reading.value, attributes: stackedValueAttributes)
            return (value: value, size: value.size(), reservedWidth: stackedValueWidths[reading.metric] ?? 0)
        }
        let width = rows.map { max($0.reservedWidth, ceil($0.size.width)) }.max() ?? 0
        return Cell(width: width) { x in
            for (index, row) in rows.enumerated() {
                let y = index == 0 ? 0 : imageHeight - row.size.height
                row.value.draw(at: NSPoint(x: x + (width - row.size.width) / 2, y: y))
            }
        }
    }

    /// Иконка и значение в одну строку.
    private static func makeIconAndValueCell(_ reading: MenuBarReading, density: MenuBarDensity) -> Cell {
        let symbol = symbolImages[reading.metric]
        let value = NSAttributedString(string: reading.value, attributes: iconValueAttributes)
        let valueSize = value.size()
        let symbolWidth = symbol.map { ceil($0.size.width) + density.iconTextSpacing } ?? 0
        let textWidth = max(iconValueWidths[reading.metric] ?? 0, ceil(valueSize.width))
        return Cell(width: symbolWidth + textWidth) { x in
            if let symbol {
                let size = symbol.size
                symbol.draw(in: NSRect(x: x, y: (imageHeight - size.height) / 2, width: size.width, height: size.height))
            }
            value.draw(at: NSPoint(x: x + symbolWidth, y: (imageHeight - valueSize.height) / 2))
        }
    }

    /// Картинка из элементов, расставленных слева направо.
    private static func drawCells(_ cells: [Cell], spacing: CGFloat) -> NSImage {
        let totalWidth = cells.map(\.width).reduce(0, +) + spacing * CGFloat(cells.count - 1)
        return NSImage(size: NSSize(width: totalWidth, height: imageHeight), flipped: true) { _ in
            var x: CGFloat = 0
            for cell in cells {
                cell.draw(x)
                x += cell.width + spacing
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
