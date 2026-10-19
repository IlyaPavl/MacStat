//
//  Array+EvenlySpaced.swift
//  MacStat
//
//  Created by Ilya Pavlov on 19.10.2026.
//

nonisolated extension Array {
    /// Не больше `limit` элементов, равномерно взятых по всему массиву.
    func evenlySpaced(upTo limit: Int) -> [Element] {
        guard count > limit, limit > 0 else { return self }
        return (0..<limit).map { self[$0 * count / limit] }
    }
}
