//
//  PopoverView.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

import SwiftUI

/// Окно, открывающееся по клику на значок.
struct PopoverView: View {
    /// Модель мониторинга.
    @Environment(MonitorViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PopoverHeader(chipName: viewModel.chipName)
                .padding(.bottom, 10)
            Divider()
            CPUSection()
            Divider()
            GPUSection()
            Divider()
            MemorySection()
            Divider()
            PopoverFooter()
                .padding(.top, 10)
        }
        .padding(14)
        .frame(width: 300)
        .onAppear(perform: viewModel.popoverDidAppear)
        .onDisappear(perform: viewModel.popoverDidDisappear)
    }
}
