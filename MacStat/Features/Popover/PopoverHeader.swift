//
//  PopoverHeader.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Заголовок поповера с названием чипа.
struct PopoverHeader: View {
    /// Название чипа.
    let chipName: String

    var body: some View {
        HStack {
            Text(verbatim: "MacStat")
                .font(.headline)
            Spacer()
            Text(chipName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary, in: .rect(cornerRadius: 6))
        }
    }
}
