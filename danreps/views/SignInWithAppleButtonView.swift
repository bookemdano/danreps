//
//  SignInWithAppleButtonView.swift
//  danreps
//
//  Created by Daniel Francis on 4/4/25.
//


import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonView: View {
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: configure,
            onCompletion: handle
        )
        .signInWithAppleButtonStyle(.black) // or .white, .whiteOutline
        .frame(height: 45)
        .padding()
    }

    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                print("User ID: \(credential.user)")
                print("Email: \(credential.email ?? "no email")")
                print("Full Name: \(credential.fullName?.givenName ?? "no name")")
                IOPAws.saveUserID(credential.user)
                // Save user ID securely (e.g., to Keychain)
            }
        case .failure(let error):
            print("Authorization failed: \(error)")
        }
    }
}
