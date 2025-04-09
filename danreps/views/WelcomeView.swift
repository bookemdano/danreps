//
//  ContentView 2.swift
//  danreps
//
//  Created by Daniel Francis on 4/4/25.
//
import SwiftUI
import DanSwiftLib

struct WelcomeView: View {
    @State private var showMainView = (IOPAws.getUserID() != nil)
    var body: some View {
        VStack {
            Text("Welcome!")
            SignInWithAppleButtonView($showMainView)
            Button(action: {
                showMainView = true
            }){
                Text("Just Play. No Save.")
                
            }
                .frame(height: 45)
                .padding()
        }
        .onAppear {
           print("onApear")
        }
        .fullScreenCover(isPresented: $showMainView) {
            ContentView()
        }
        
    }
}
