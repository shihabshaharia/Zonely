//
//  ContentView.swift
//  Zonely
//
//  Created by Shihab Shaharia on 23/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "clock")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .font(.largeTitle)
                .bold()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
