//
//  AuthenticationView.swift
//  MoodMapper
//
//  Created by Ethan on 5/10/2025.
//

import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoginMode = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    let onAuthenticationSuccess: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image("applogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                    
                    Text("MoodMapper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isLoginMode ? "Welcome back!" : "Create your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                
                Picker("", selection: $isLoginMode) {
                    Text("Sign In").tag(true)
                    Text("Sign Up").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .shadow(radius: 10)

                
                // Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Confirm Password Field (only for register)
                    if !isLoginMode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isLoginMode)
                .padding(16)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                .padding()
                .shadow(radius: 10)
                
                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 32)
                }
                
                // Action Button
                Button(action: handleAuthentication) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isLoginMode ? "Sign In" : "Create Account")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isValidInput || isLoading)
                .padding(.horizontal, 32)
                .shadow(radius: 10)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") {
                showError = false
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && 
                   email.contains("@") && password == confirmPassword && password.count >= 6
        }
    }
    
    // MARK: - Actions
    
    private func handleAuthentication() {
        guard isValidInput else { return }
        
        isLoading = true
        errorMessage = ""
        
        if isLoginMode {
            signIn()
        } else {
            signUp()
        }
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else if result != nil {
                    onAuthenticationSuccess()
                }
            }
        }
    }
    
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else if result != nil {
                    onAuthenticationSuccess()
                }
            }
        }
    }
}

#Preview {
    AuthenticationView {
        print("Authentication successful")
    }
}
