//
//  GlassIconButtonStyle.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Круглая стеклянная кнопка-иконка с обводкой при наведении и откликом на нажатие.
struct GlassIconButtonStyle: ButtonStyle {
    /// Оборачивает содержимое кнопки в `GlassIconButton`.
    func makeBody(configuration: Configuration) -> some View {
        GlassIconButton(configuration: configuration)
    }
}

/// Внешний вид кнопки; хранит состояние наведения, которого нет в `ButtonStyle`.
private struct GlassIconButton: View {
    /// Диаметр кнопки.
    private static let diameter: CGFloat = 30

    /// Содержимое и состояние нажатия.
    let configuration: ButtonStyleConfiguration
    /// Находится ли курсор над кнопкой.
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isHovered ? .primary : .secondary)
            .frame(width: Self.diameter, height: Self.diameter)
            .contentShape(.circle)
            .glassEffect(.regular.interactive(), in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(.primary.opacity(isHovered ? 0.3 : 0), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { isHovered = $0 }
    }
}
